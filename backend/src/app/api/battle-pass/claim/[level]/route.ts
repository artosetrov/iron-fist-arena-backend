import { NextRequest, NextResponse } from 'next/server'
import { ConsumableType, CosmeticType, type Prisma } from '@prisma/client'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { bpXpForLevel } from '@/lib/game/balance'
import { applyLevelUp } from '@/lib/game/progression'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { rateLimit } from '@/lib/rate-limit'

type SupportedBattlePassRewardType =
  | 'gold'
  | 'gems'
  | 'xp'
  | 'stamina'
  | 'item'
  | 'chest'
  | 'consumable'
  | 'cosmetic'
  | 'skin'
  | 'title'
  | 'frame'
  | 'effect'

type RewardResponse = {
  rewardType: string
  rewardId: string | null
  rewardAmount: number
  isPremium: boolean
}

type ClaimTx = Prisma.TransactionClient

function calculateBpLevel(totalXp: number): number {
  let remaining = totalXp
  let level = 0

  while (true) {
    const needed = bpXpForLevel(level + 1)
    if (remaining < needed) return level
    remaining -= needed
    level++
  }
}

function normalizeRewardType(rewardType: string): SupportedBattlePassRewardType | null {
  const normalized = rewardType.trim().toLowerCase()

  switch (normalized) {
    case 'gold':
    case 'gems':
    case 'xp':
    case 'stamina':
    case 'item':
    case 'chest':
    case 'consumable':
    case 'cosmetic':
    case 'skin':
    case 'title':
    case 'frame':
    case 'effect':
      return normalized
    default:
      return null
  }
}

function isConsumableType(value: string): value is ConsumableType {
  return Object.values(ConsumableType).includes(value as ConsumableType)
}

function parseCosmeticReward(
  rewardType: SupportedBattlePassRewardType,
  rewardId: string | null,
): { type: CosmeticType; refId: string } | null {
  if (rewardType === 'skin') {
    return rewardId ? { type: 'skin', refId: rewardId } : null
  }

  if (rewardType === 'title') {
    return rewardId ? { type: 'title', refId: rewardId } : null
  }

  if (rewardType === 'frame') {
    return rewardId ? { type: 'frame', refId: rewardId } : null
  }

  if (rewardType === 'effect') {
    return rewardId ? { type: 'effect', refId: rewardId } : null
  }

  if (rewardType !== 'cosmetic' || !rewardId) {
    return null
  }

  const [type, ...rest] = rewardId.split(':')
  const refId = rest.join(':').trim()

  if (!refId) return null
  if (!['skin', 'title', 'frame', 'effect'].includes(type)) return null

  return {
    type: type as CosmeticType,
    refId,
  }
}

async function resolveSkinRefId(
  tx: ClaimTx,
  rewardId: string,
): Promise<string | null> {
  const skin = await tx.appearanceSkin.findFirst({
    where: {
      OR: [{ id: rewardId }, { skinKey: rewardId }],
    },
    select: { skinKey: true },
  })

  return skin?.skinKey ?? null
}

export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ level: string }> }
) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`battle-pass-claim:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  let requestedLevel = 0

  try {
    const { level: levelParam } = await params
    const targetLevel = parseInt(levelParam, 10)
    requestedLevel = targetLevel

    if (isNaN(targetLevel) || targetLevel < 1) {
      return NextResponse.json({ error: 'Invalid level' }, { status: 400 })
    }

    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: character_id },
      select: { id: true, userId: true },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const now = new Date()
    const activeSeason = await prisma.season.findFirst({
      where: {
        startAt: { lte: now },
        endAt: { gte: now },
      },
      select: { id: true },
    })

    if (!activeSeason) {
      return NextResponse.json({ error: 'No active season' }, { status: 404 })
    }

    const result = await prisma.$transaction(async (tx) => {
      const [lockedCharacter] = await tx.$queryRawUnsafe<Array<{
        id: string
        user_id: string
        current_stamina: number
        max_stamina: number
        last_stamina_update: Date | null
        inventory_slots: number
      }>>(
        `SELECT id, user_id, current_stamina, max_stamina, last_stamina_update, inventory_slots
           FROM characters
          WHERE id = $1
          FOR UPDATE`,
        character_id,
      )

      if (!lockedCharacter) throw new Error('CHARACTER_NOT_FOUND')
      if (lockedCharacter.user_id !== user.id) throw new Error('FORBIDDEN')

      const [lockedUser] = await tx.$queryRawUnsafe<Array<{ id: string }>>(
        `SELECT id FROM users WHERE id = $1 FOR UPDATE`,
        user.id,
      )

      if (!lockedUser) throw new Error('USER_NOT_FOUND')

      const existingBattlePassRows = await tx.$queryRawUnsafe<Array<{
        id: string
        premium: boolean
        bp_xp: number
      }>>(
        `SELECT id, premium, bp_xp
           FROM battle_pass
          WHERE character_id = $1 AND season_id = $2
          FOR UPDATE`,
        character_id,
        activeSeason.id,
      )

      let battlePassId: string
      let hasPremium: boolean
      let bpXp: number

      if (existingBattlePassRows[0]) {
        battlePassId = existingBattlePassRows[0].id
        hasPremium = existingBattlePassRows[0].premium
        bpXp = existingBattlePassRows[0].bp_xp
      } else {
        const createdBattlePass = await tx.battlePass.create({
          data: {
            characterId: character_id,
            seasonId: activeSeason.id,
            premium: false,
            bpXp: 0,
          },
        })

        battlePassId = createdBattlePass.id
        hasPremium = createdBattlePass.premium
        bpXp = createdBattlePass.bpXp
      }

      const currentLevel = calculateBpLevel(bpXp)
      if (currentLevel < targetLevel) {
        throw new Error(`LEVEL_NOT_REACHED:${currentLevel}`)
      }

      const rewards = await tx.battlePassReward.findMany({
        where: { seasonId: activeSeason.id, bpLevel: targetLevel },
        orderBy: { isPremium: 'asc' },
      })

      if (rewards.length === 0) {
        throw new Error('NO_REWARDS')
      }

      const eligibleRewards = rewards.filter((reward) => !reward.isPremium || hasPremium)
      if (eligibleRewards.length === 0) {
        throw new Error('NO_CLAIMABLE_REWARDS')
      }

      const existingClaims = await tx.battlePassClaim.findMany({
        where: {
          characterId: character_id,
          rewardId: { in: eligibleRewards.map((reward) => reward.id) },
        },
        select: { rewardId: true },
      })

      const claimedRewardIds = new Set(existingClaims.map((claim) => claim.rewardId))
      const claimableRewards = eligibleRewards.filter((reward) => !claimedRewardIds.has(reward.id))

      if (claimableRewards.length === 0) {
        throw new Error('NO_CLAIMABLE_REWARDS')
      }

      let goldIncrement = 0
      let gemsIncrement = 0
      let xpIncrement = 0

      const staminaBefore = calculateCurrentStamina(
        lockedCharacter.current_stamina,
        lockedCharacter.max_stamina,
        lockedCharacter.last_stamina_update ?? now,
      ).stamina
      let staminaAfter = staminaBefore

      const pendingItemIds: string[] = []
      const pendingConsumables = new Map<ConsumableType, number>()
      const pendingCosmetics = new Map<string, { type: CosmeticType; refId: string }>()
      const claimedRewards: RewardResponse[] = []

      for (const reward of claimableRewards) {
        const rewardType = normalizeRewardType(reward.rewardType)

        if (!rewardType) {
          throw new Error(`INVALID_REWARD_TYPE:${reward.rewardType}`)
        }

        if (!Number.isInteger(reward.rewardAmount) || reward.rewardAmount < 1) {
          throw new Error(`INVALID_REWARD_CONFIG:${reward.id}`)
        }

        switch (rewardType) {
          case 'gold':
            goldIncrement += reward.rewardAmount
            break
          case 'gems':
            gemsIncrement += reward.rewardAmount
            break
          case 'xp':
            xpIncrement += reward.rewardAmount
            break
          case 'stamina':
            staminaAfter = Math.min(
              staminaAfter + reward.rewardAmount,
              lockedCharacter.max_stamina,
            )
            break
          case 'consumable': {
            if (!reward.rewardId || !isConsumableType(reward.rewardId)) {
              throw new Error(`INVALID_REWARD_CONFIG:${reward.id}`)
            }

            pendingConsumables.set(
              reward.rewardId,
              (pendingConsumables.get(reward.rewardId) ?? 0) + reward.rewardAmount,
            )
            break
          }
          case 'item':
          case 'chest': {
            if (!reward.rewardId) {
              throw new Error(`INVALID_REWARD_CONFIG:${reward.id}`)
            }

            const item = await tx.item.findUnique({
              where: { id: reward.rewardId },
              select: { id: true },
            })

            if (!item) {
              throw new Error(`INVALID_REWARD_CONFIG:${reward.id}`)
            }

            for (let i = 0; i < reward.rewardAmount; i += 1) {
              pendingItemIds.push(item.id)
            }
            break
          }
          case 'skin':
          case 'title':
          case 'frame':
          case 'effect':
          case 'cosmetic': {
            const cosmetic = parseCosmeticReward(rewardType, reward.rewardId)
            if (!cosmetic) {
              throw new Error(`INVALID_REWARD_CONFIG:${reward.id}`)
            }

            let refId = cosmetic.refId
            if (cosmetic.type === 'skin') {
              const resolvedSkinKey = await resolveSkinRefId(tx, cosmetic.refId)
              if (!resolvedSkinKey) {
                throw new Error(`INVALID_REWARD_CONFIG:${reward.id}`)
              }
              refId = resolvedSkinKey
            }

            pendingCosmetics.set(`${cosmetic.type}:${refId}`, {
              type: cosmetic.type,
              refId,
            })
            break
          }
        }

        claimedRewards.push({
          rewardType: reward.rewardType,
          rewardId: reward.rewardId,
          rewardAmount: reward.rewardAmount,
          isPremium: reward.isPremium,
        })
      }

      if (pendingItemIds.length > 0) {
        const inventoryCount = await tx.equipmentInventory.count({
          where: { characterId: character_id },
        })

        if (inventoryCount + pendingItemIds.length > lockedCharacter.inventory_slots) {
          throw new Error('INVENTORY_FULL')
        }
      }

      for (const reward of claimableRewards) {
        await tx.battlePassClaim.create({
          data: {
            characterId: character_id,
            battlePassId,
            rewardId: reward.id,
          },
        })
      }

      if (
        goldIncrement > 0 ||
        xpIncrement > 0 ||
        staminaAfter !== staminaBefore
      ) {
        await tx.character.update({
          where: { id: character_id },
          data: {
            ...(goldIncrement > 0 ? { gold: { increment: goldIncrement } } : {}),
            ...(xpIncrement > 0 ? { currentXp: { increment: xpIncrement } } : {}),
            ...(staminaAfter !== staminaBefore
              ? {
                  currentStamina: staminaAfter,
                  lastStaminaUpdate: now,
                }
              : {}),
          },
        })
      }

      if (gemsIncrement > 0) {
        await tx.user.update({
          where: { id: user.id },
          data: { gems: { increment: gemsIncrement } },
        })
      }

      for (const [consumableType, quantity] of pendingConsumables.entries()) {
        await tx.consumableInventory.upsert({
          where: {
            characterId_consumableType: {
              characterId: character_id,
              consumableType,
            },
          },
          update: { quantity: { increment: quantity } },
          create: {
            characterId: character_id,
            consumableType,
            quantity,
          },
        })
      }

      for (const itemId of pendingItemIds) {
        await tx.equipmentInventory.create({
          data: {
            characterId: character_id,
            itemId,
          },
        })
      }

      for (const cosmetic of pendingCosmetics.values()) {
        const existingCosmetic = await tx.cosmetic.findFirst({
          where: {
            userId: user.id,
            type: cosmetic.type,
            refId: cosmetic.refId,
          },
          select: { id: true },
        })

        if (!existingCosmetic) {
          await tx.cosmetic.create({
            data: {
              userId: user.id,
              type: cosmetic.type,
              refId: cosmetic.refId,
            },
          })
        }
      }

      const levelUpResult = xpIncrement > 0
        ? await applyLevelUp(tx, character_id)
        : null

      return {
        claimedRewards,
        levelUpResult,
      }
    })

    return NextResponse.json({
      level: targetLevel,
      rewards: result.claimedRewards,
      leveled_up: result.levelUpResult?.leveledUp ?? false,
      new_level: result.levelUpResult?.newLevel,
      stat_points_awarded: result.levelUpResult?.statPointsAwarded,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'CHARACTER_NOT_FOUND') {
        return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      }
      if (error.message === 'USER_NOT_FOUND') {
        return NextResponse.json({ error: 'User not found' }, { status: 404 })
      }
      if (error.message === 'FORBIDDEN') {
        return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      }
      if (error.message === 'NO_REWARDS') {
        return NextResponse.json({ error: 'No rewards found for this level' }, { status: 404 })
      }
      if (error.message === 'NO_CLAIMABLE_REWARDS') {
        return NextResponse.json(
          { error: 'No claimable rewards at this level (already claimed or premium required)' },
          { status: 400 },
        )
      }
      if (error.message === 'INVENTORY_FULL') {
        return NextResponse.json(
          { error: 'Inventory is full. Free up space before claiming this reward.' },
          { status: 409 },
        )
      }
      if (error.message.startsWith('LEVEL_NOT_REACHED:')) {
        const currentLevel = error.message.split(':')[1] ?? '0'
        return NextResponse.json(
          { error: `Battle pass level ${requestedLevel} not yet reached (current: ${currentLevel})` },
          { status: 400 },
        )
      }
      if (
        error.message.startsWith('INVALID_REWARD_TYPE:') ||
        error.message.startsWith('INVALID_REWARD_CONFIG:')
      ) {
        console.error('battle pass reward config error:', error.message)
        return NextResponse.json(
          { error: 'Battle pass reward configuration is invalid. Claim was not applied.' },
          { status: 500 },
        )
      }
    }

    console.error('claim battle pass reward error:', error)
    return NextResponse.json(
      { error: 'Failed to claim battle pass reward' },
      { status: 500 }
    )
  }
}
