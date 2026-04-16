import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import {
  STARTER_WEAPON_BY_CLASS,
  WELCOME_GIFT,
  REFERRAL_BONUS,
  BUILDING_UNLOCK_LEVELS,
  TUTORIAL_QUESTS,
  generateReferralCode,
  getReferralLinkValues,
  normalizeReferralCode,
} from '@/lib/game/tutorial'
import { logTutorialEvent } from '@/lib/game/tutorial-analytics'

/**
 * GET /api/tutorial?character_id=xxx
 * Returns full tutorial state: step, quests, building unlocks, referral code.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const characterId = req.nextUrl.searchParams.get('character_id')
  if (!characterId) {
    return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
  }

  try {
    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: {
        id: true,
        userId: true,
        level: true,
        class: true,
        tutorialStep: true,
        tutorialSkipped: true,
        referralCode: true,
        prestigeLevel: true,
        tutorialQuests: true,
      },
    })

    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    // Compute unlocked buildings based on current level
    const unlockedBuildings: Record<string, boolean> = {}
    for (const [building, level] of Object.entries(BUILDING_UNLOCK_LEVELS)) {
      unlockedBuildings[building] = character.level >= level
    }

    // Find next available quest (not yet created)
    const completedQuestIds = new Set(character.tutorialQuests.map((q) => q.questId))
    const availableQuests = TUTORIAL_QUESTS.filter(
      (q) => character.level >= q.unlockLevel && !completedQuestIds.has(q.id)
    )

    return NextResponse.json({
      tutorialStep: character.tutorialStep,
      tutorialSkipped: character.tutorialSkipped,
      isPrestige: character.prestigeLevel > 0,
      referralCode: character.referralCode,
      unlockedBuildings,
      quests: character.tutorialQuests,
      availableQuests: availableQuests.map((q) => ({
        id: q.id,
        title: q.title,
        npcMessage: q.npcMessage,
        target: q.target,
      })),
      buildingUnlockLevels: BUILDING_UNLOCK_LEVELS,
    })
  } catch (error) {
    console.error('tutorial GET error:', error)
    return NextResponse.json({ error: 'Failed to get tutorial state' }, { status: 500 })
  }
}

/**
 * POST /api/tutorial
 * Initialize tutorial: claim welcome gift (weapon + stamina + potions).
 * Only works once (tutorialStep must be 0).
 * Body: { character_id, referral_code? }
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`tutorial-init:${user.id}`, 5, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, referral_code } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const result = await prisma.$transaction(async (tx) => {
      // Lock character row
      const [character] = await tx.$queryRawUnsafe<
        Array<{
          id: string
          user_id: string
          tutorial_step: number
          class: string
          current_stamina: number
          max_stamina: number
          prestige_level: number
        }>
      >(
        `SELECT id, user_id, tutorial_step, class, current_stamina, max_stamina, prestige_level
         FROM characters WHERE id = $1 FOR UPDATE`,
        character_id
      )

      if (!character) throw new Error('NOT_FOUND')
      if (character.user_id !== user.id) throw new Error('FORBIDDEN')
      if (character.tutorial_step !== 0) throw new Error('ALREADY_CLAIMED')
      if (character.prestige_level > 0) throw new Error('PRESTIGE_NO_TUTORIAL')

      // Determine starter weapon
      const weaponCatalogId = STARTER_WEAPON_BY_CLASS[character.class] || 'wpn_rusty_sword'
      const item = await tx.item.findUnique({ where: { catalogId: weaponCatalogId } })
      if (!item) throw new Error('STARTER_ITEM_NOT_FOUND')

      // Handle referral
      let isReferred = false
      if (referral_code) {
        const normalizedReferralCode = normalizeReferralCode(referral_code)
        const referralRecord = await tx.character.findUnique({
          where: { referralCode: normalizedReferralCode },
          select: { id: true, referralCode: true },
        })
        if (referralRecord && referralRecord.id !== character_id) {
          const referrerCode = referralRecord.referralCode ?? normalizedReferralCode
          const referralCount = await tx.character.count({
            where: {
              referredBy: {
                in: getReferralLinkValues(referralRecord.id, referrerCode),
              },
            },
          })

          if (referralCount < REFERRAL_BONUS.maxReferrals) {
            await tx.character.update({
              where: { id: character_id },
              data: { referredBy: referralRecord.id },
            })
            isReferred = true
          }
        }
      }

      // Base welcome gold + extra for referred players
      const baseGold = WELCOME_GIFT.baseGold
      const extraGold = isReferred ? REFERRAL_BONUS.extraGold : 0
      const totalGold = baseGold + extraGold

      // Update character: advance step, add stamina
      const updatedCharacter = await tx.character.update({
        where: { id: character_id },
        data: {
          tutorialStep: 1,
          currentStamina: Math.min(
            character.current_stamina + WELCOME_GIFT.staminaBonus,
            character.max_stamina + WELCOME_GIFT.staminaBonus
          ),
          referralCode: generateReferralCode(),
        },
      })

      // Add welcome gold + referral bonus to user account
      if (totalGold > 0) {
        await tx.user.update({
          where: { id: user.id },
          data: { gold: { increment: totalGold } },
        })
      }

      // Give starter weapon
      const inventoryItem = await tx.equipmentInventory.create({
        data: {
          characterId: character_id,
          itemId: item.id,
          upgradeLevel: 0,
          durability: 100,
          maxDurability: 100,
          isEquipped: false,
        },
        include: { item: true },
      })

      // Give health potions
      await tx.consumableInventory.upsert({
        where: {
          characterId_consumableType: {
            characterId: character_id,
            consumableType: WELCOME_GIFT.healthPotionType,
          },
        },
        update: { quantity: { increment: WELCOME_GIFT.healthPotionCount } },
        create: {
          characterId: character_id,
          consumableType: WELCOME_GIFT.healthPotionType,
          quantity: WELCOME_GIFT.healthPotionCount,
        },
      })

      // Initialize first available tutorial quests
      const questsToCreate = TUTORIAL_QUESTS.filter((q) => q.unlockLevel <= 1)
      for (const quest of questsToCreate) {
        await tx.tutorialQuest.create({
          data: {
            characterId: character_id,
            questId: quest.id,
            target: quest.target,
          },
        })
      }

      return {
        character: updatedCharacter,
        weapon: inventoryItem,
        isReferred,
      }
    })

    logTutorialEvent({
      event: 'tutorial_started',
      characterId: character_id,
      isReferred: result.isReferred,
      weaponId: result.weapon?.item?.catalogId,
    })

    return NextResponse.json({
      tutorialStep: result.character.tutorialStep,
      weapon: result.weapon,
      isReferred: result.isReferred,
      stamina: result.character.currentStamina,
    }, { status: 201 })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'ALREADY_CLAIMED') return NextResponse.json({ error: 'Welcome gift already claimed' }, { status: 409 })
      if (error.message === 'PRESTIGE_NO_TUTORIAL') return NextResponse.json({ error: 'No tutorial after prestige' }, { status: 409 })
      if (error.message === 'STARTER_ITEM_NOT_FOUND') return NextResponse.json({ error: 'Starter item not in catalog' }, { status: 500 })
    }
    console.error('tutorial init error:', error)
    return NextResponse.json({ error: 'Failed to initialize tutorial' }, { status: 500 })
  }
}
