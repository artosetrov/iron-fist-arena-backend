import { ConsumableType, type Prisma } from '@prisma/client'
import { applyLevelUp, type LevelUpResult } from './progression'

export interface RewardGrantEntry {
  readonly type: 'gold' | 'gems' | 'xp' | 'item' | 'consumable'
  readonly id?: string | null
  readonly quantity: number
}

export interface RewardGrantResult {
  readonly gold: number
  readonly gems: number
  readonly xp: number
  readonly level: number
  readonly levelUpResult: LevelUpResult | null
}

function isConsumableType(value: string): value is ConsumableType {
  return Object.values(ConsumableType).includes(value as ConsumableType)
}

async function resolveItemId(
  tx: Prisma.TransactionClient,
  itemRef: string,
): Promise<string | null> {
  const direct = await tx.item.findUnique({
    where: { id: itemRef },
    select: { id: true },
  })
  if (direct) return direct.id

  const byCatalogId = await tx.item.findUnique({
    where: { catalogId: itemRef },
    select: { id: true },
  })
  return byCatalogId?.id ?? null
}

export async function grantRewardEntries(
  tx: Prisma.TransactionClient,
  args: {
    userId: string
    characterId: string
    rewards: readonly RewardGrantEntry[]
  },
): Promise<RewardGrantResult> {
  const { userId, characterId, rewards } = args

  await tx.$queryRaw`SELECT id FROM characters WHERE id = ${characterId} FOR UPDATE`

  let goldGrant = 0
  let gemsGrant = 0
  let xpGrant = 0

  const pendingConsumables = new Map<ConsumableType, number>()
  const pendingItemIds: string[] = []

  for (const reward of rewards) {
    if (
      !Number.isFinite(reward.quantity)
      || !Number.isInteger(reward.quantity)
      || reward.quantity < 0
    ) {
      throw new Error('INVALID_REWARD_QUANTITY')
    }
    if (reward.quantity === 0) continue

    switch (reward.type) {
      case 'gold':
        goldGrant += reward.quantity
        break
      case 'gems':
        gemsGrant += reward.quantity
        break
      case 'xp':
        xpGrant += reward.quantity
        break
      case 'consumable': {
        if (!reward.id || !isConsumableType(reward.id)) {
          throw new Error('INVALID_CONSUMABLE_REWARD')
        }
        pendingConsumables.set(
          reward.id,
          (pendingConsumables.get(reward.id) ?? 0) + reward.quantity,
        )
        break
      }
      case 'item': {
        if (!reward.id) throw new Error('INVALID_ITEM_REWARD')
        const itemId = await resolveItemId(tx, reward.id)
        if (!itemId) throw new Error('INVALID_ITEM_REWARD')
        for (let i = 0; i < reward.quantity; i += 1) {
          pendingItemIds.push(itemId)
        }
        break
      }
      default:
        throw new Error('INVALID_REWARD_TYPE')
    }
  }

  const lockedCharacter = await tx.character.findUnique({
    where: { id: characterId },
    select: { inventorySlots: true },
  })
  if (!lockedCharacter) throw new Error('CHARACTER_NOT_FOUND')

  if (pendingItemIds.length > 0) {
    const inventoryCount = await tx.equipmentInventory.count({
      where: { characterId },
    })
    if (inventoryCount + pendingItemIds.length > lockedCharacter.inventorySlots) {
      throw new Error('INVENTORY_FULL')
    }
  }

  if (goldGrant > 0) {
    await tx.user.update({
      where: { id: userId },
      data: { gold: { increment: goldGrant } },
    })
  }

  if (gemsGrant > 0) {
    await tx.user.update({
      where: { id: userId },
      data: { gems: { increment: gemsGrant } },
    })
  }

  if (xpGrant > 0) {
    await tx.character.update({
      where: { id: characterId },
      data: { currentXp: { increment: xpGrant } },
    })
  }

  for (const [consumableType, quantity] of pendingConsumables.entries()) {
    await tx.consumableInventory.upsert({
      where: {
        characterId_consumableType: {
          characterId,
          consumableType,
        },
      },
      update: { quantity: { increment: quantity } },
      create: {
        characterId,
        consumableType,
        quantity,
      },
    })
  }

  for (const itemId of pendingItemIds) {
    await tx.equipmentInventory.create({
      data: {
        characterId,
        itemId,
        upgradeLevel: 0,
        durability: 100,
        maxDurability: 100,
        isEquipped: false,
      },
    })
  }

  const levelUpResult = xpGrant > 0
    ? await applyLevelUp(tx, characterId)
    : null

  const [updatedUser, updatedChar] = await Promise.all([
    tx.user.findUnique({
      where: { id: userId },
      select: { gold: true, gems: true },
    }),
    tx.character.findUnique({
      where: { id: characterId },
      select: { currentXp: true, level: true },
    }),
  ])

  if (!updatedUser) throw new Error('USER_NOT_FOUND')
  if (!updatedChar) throw new Error('CHARACTER_NOT_FOUND')

  return {
    gold: updatedUser.gold,
    gems: updatedUser.gems,
    xp: updatedChar.currentXp,
    level: updatedChar.level,
    levelUpResult,
  }
}
