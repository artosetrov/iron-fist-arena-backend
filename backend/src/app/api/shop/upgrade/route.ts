import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { getUpgradeChancesConfig } from '@/lib/game/live-config'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'
import { recalculateDerivedStats } from '@/lib/game/equipment-stats'
import { invalidateSkillCache, invalidatePassiveCache } from '@/lib/game/combat-loader'
import { rateLimit } from '@/lib/rate-limit'
import { incrementGuildChallenge } from '@/lib/game/guild-challenge'
import {
  getUpgradeCost,
  getUpgradeSuccessChance,
  getUpgradeProtectionCost,
  getUpgradeDowngradeThreshold,
  getUpgradeStatBonus,
} from '@/lib/game/item-balance'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`upgrade:${user.id}`, 15, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const UPGRADE_CHANCES = await getUpgradeChancesConfig()
    const body = await req.json()
    const { character_id, inventory_id, use_protection } = body

    if (!character_id || !inventory_id) {
      return NextResponse.json(
        { error: 'character_id and inventory_id are required' },
        { status: 400 }
      )
    }

    // Get the inventory item (read-only, no race concern on item data)
    const inventoryItem = await prisma.equipmentInventory.findUnique({
      where: { id: inventory_id },
      include: { item: true },
    })

    if (!inventoryItem) {
      return NextResponse.json({ error: 'Inventory item not found' }, { status: 404 })
    }
    if (inventoryItem.characterId !== character_id) {
      return NextResponse.json({ error: 'Item does not belong to this character' }, { status: 403 })
    }

    const currentLevel = inventoryItem.upgradeLevel
    if (currentLevel >= UPGRADE_CHANCES.length) {
      return NextResponse.json({ error: 'Item is already at maximum upgrade level' }, { status: 400 })
    }

    // Read upgrade parameters from config (DB-driven)
    const upgradeCost = await getUpgradeCost(currentLevel)
    const successChance = await getUpgradeSuccessChance(currentLevel)
    const protectionCost = await getUpgradeProtectionCost()
    const downgradeThreshold = await getUpgradeDowngradeThreshold()

    const roll = Math.random() * 100
    const success = roll < successChance

    // Use interactive transaction with row-level lock to prevent TOCTOU
    const result = await prisma.$transaction(async (tx) => {
      // Lock user row for update (gold and gems balance)
      const [userRow] = await tx.$queryRawUnsafe<Array<{ id: string; gold: number; gems: number }>>(
        `SELECT id, gold, gems FROM users WHERE id = $1 FOR UPDATE`,
        user.id
      )

      if (!userRow) throw new Error('USER_NOT_FOUND')
      if (userRow.gold < upgradeCost) throw new Error('NOT_ENOUGH_GOLD')

      if (use_protection && userRow.gems < protectionCost) {
        throw new Error('NOT_ENOUGH_GEMS')
      }

      // Verify character ownership
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true },
      })

      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Deduct gold
      let updatedUser = await tx.user.update({
        where: { id: user.id },
        data: { gold: { decrement: upgradeCost } },
      })

      let updatedItem = inventoryItem
      let protectionUsed = false
      let levelLost = false

      if (success) {
        // Upgrade succeeded — increment level, no gem cost
        updatedItem = await tx.equipmentInventory.update({
          where: { id: inventory_id },
          data: { upgradeLevel: { increment: 1 } },
          include: { item: true },
        })
      } else {
        // Upgrade failed
        if (use_protection) {
          // Protection scroll consumed — deduct gems, level stays the same
          updatedUser = await tx.user.update({
            where: { id: user.id },
            data: { gems: { decrement: protectionCost } },
          })
          protectionUsed = true
        } else if (currentLevel >= downgradeThreshold) {
          // No protection and level is at/above threshold — lose one level
          updatedItem = await tx.equipmentInventory.update({
            where: { id: inventory_id },
            data: { upgradeLevel: { decrement: 1 } },
            include: { item: true },
          })
          levelLost = true
        }
        // If currentLevel < threshold and no protection, nothing extra happens (gold already spent)
      }

      return { updatedUser, updatedItem, protectionUsed, levelLost }
    })

    // Non-critical post-transaction work — daily + weekly quest progress
    await Promise.all([
      updateDailyQuestProgress(prisma, character_id, 'item_upgrade'),
      updateDailyQuestProgress(prisma, character_id, 'gold_spent', upgradeCost),
      // W3.D5 — Weekly BP challenges: Master Smith + Spendthrift slots
      updateWeeklyChallengeProgress(prisma, character_id, 'item_upgrade'),
      updateWeeklyChallengeProgress(prisma, character_id, 'gold_spent', upgradeCost),
    ])
    if (success) {
      incrementGuildChallenge(prisma, 'items_upgraded', 1).catch(() => {})
    }

    if (success && result.updatedItem.isEquipped) {
      await recalculateDerivedStats(character_id)
      await invalidateSkillCache(character_id)
      await invalidatePassiveCache(character_id)
    }
    if (!success && result.levelLost && result.updatedItem.isEquipped) {
      await recalculateDerivedStats(character_id)
      await invalidateSkillCache(character_id)
      await invalidatePassiveCache(character_id)
    }

    let newLevel = currentLevel
    if (success) {
      newLevel = currentLevel + 1
    } else if (result.levelLost) {
      newLevel = currentLevel - 1
    }

    // Calculate effective stats (baseStats + upgrade bonus) for before and after
    const upgradeStatBonus = await getUpgradeStatBonus()
    const baseStats = (result.updatedItem.item.baseStats as Record<string, number>) ?? {}

    const effectiveStats: Record<string, number> = {}
    const previousEffectiveStats: Record<string, number> = {}
    const statChanges: Record<string, { before: number; after: number; diff: number }> = {}

    for (const [stat, baseValue] of Object.entries(baseStats)) {
      const before = baseValue + currentLevel * upgradeStatBonus
      const after = baseValue + newLevel * upgradeStatBonus
      previousEffectiveStats[stat] = before
      effectiveStats[stat] = after
      statChanges[stat] = { before, after, diff: after - before }
    }

    return NextResponse.json({
      success,
      inventoryItem: result.updatedItem,
      character: {
        gold: result.updatedUser.gold,
        gems: result.updatedUser.gems,
      },
      upgradeCost,
      newLevel,
      protection_used: result.protectionUsed,
      level_lost: result.levelLost,
      effectiveStats,
      previousEffectiveStats,
      statChanges,
      upgradeStatBonus,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'NOT_ENOUGH_GOLD') return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
      if (error.message === 'NOT_ENOUGH_GEMS') return NextResponse.json({ error: 'Not enough gems for protection scroll' }, { status: 400 })
    }
    console.error('upgrade item error:', error)
    return NextResponse.json({ error: 'Failed to upgrade item' }, { status: 500 })
  }
}
