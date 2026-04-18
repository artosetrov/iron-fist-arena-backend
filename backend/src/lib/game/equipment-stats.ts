// =============================================================================
// equipment-stats.ts — Recalculate derived stats from base stats + equipment
// Now reads formulas from GameConfig via item-balance engine.
// =============================================================================

import { prisma } from '@/lib/prisma'
import type { PrismaClient } from '@prisma/client'
import { getPrestigeConfig } from './live-config'
import { calculateDerivedStatsFromConfig, getUpgradeStatBonus } from './item-balance'
import { sumCoreEquipmentStats } from './item-stats'

type TransactionClient = Parameters<Parameters<PrismaClient['$transaction']>[0]>[0]

interface DerivedStats {
  maxHp: number
  armor: number
  magicResist: number
}

interface StatBlock {
  str: number
  agi: number
  vit: number
  end: number
  int: number
  wis: number
  luk: number
  cha: number
}

/**
 * Sum stat bonuses from all equipped items.
 * Each item may contribute base stats plus rolled stats.
 * Upgrade levels add +upgradeStatBonus per stat that exists on the merged item payload.
 */
async function sumEquipmentBonuses(
  equippedItems: Array<{
    item: { baseStats: unknown }
    rolledStats: unknown
    upgradeLevel: number
    durability: number
  }>
): Promise<StatBlock> {
  const bonus: StatBlock = { str: 0, agi: 0, vit: 0, end: 0, int: 0, wis: 0, luk: 0, cha: 0 }
  const upgradeStatBonus = await getUpgradeStatBonus()

  for (const eq of equippedItems) {
    // Broken items (durability <= 0) provide NO stat bonuses
    if (eq.durability <= 0) continue

    const effectiveCoreStats = sumCoreEquipmentStats(
      eq.item.baseStats,
      eq.rolledStats,
      eq.upgradeLevel,
      upgradeStatBonus,
    )
    for (const [key, value] of Object.entries(effectiveCoreStats) as Array<[keyof StatBlock, number]>) {
      bonus[key] += value
    }
  }

  return bonus
}

/**
 * Recalculate and persist maxHp, armor, magicResist for a character.
 * Call after: stat allocation, equip, unequip, upgrade, level-up.
 */
export async function recalculateDerivedStats(characterId: string, tx?: TransactionClient): Promise<DerivedStats> {
  const db = tx ?? prisma
  const character = await db.character.findUnique({
    where: { id: characterId },
    select: {
      str: true,
      agi: true,
      vit: true,
      end: true,
      int: true,
      wis: true,
      luk: true,
      cha: true,
      prestigeLevel: true,
      equipment: {
        where: { isEquipped: true },
        select: {
          upgradeLevel: true,
          rolledStats: true,
          durability: true,
          item: { select: { baseStats: true } },
        },
      },
    },
  })

  if (!character) throw new Error('Character not found')

  const eqBonus = await sumEquipmentBonuses(
    character.equipment.map((e) => ({
      item: { baseStats: e.item.baseStats },
      rolledStats: e.rolledStats,
      upgradeLevel: e.upgradeLevel,
      durability: e.durability,
    }))
  )

  const rawTotalStats: StatBlock = {
    str: character.str + eqBonus.str,
    agi: character.agi + eqBonus.agi,
    vit: character.vit + eqBonus.vit,
    end: character.end + eqBonus.end,
    int: character.int + eqBonus.int,
    wis: character.wis + eqBonus.wis,
    luk: character.luk + eqBonus.luk,
    cha: character.cha + eqBonus.cha,
  }

  // Apply prestige bonus: +5% per prestige level to each stat.
  // Fetch config ONCE, then apply to all 8 stats synchronously (was: 8 sequential DB calls).
  const prestige = character.prestigeLevel ?? 0
  const prestigeConfig = await getPrestigeConfig()
  const prestigeMultiplier = 1 + prestige * prestigeConfig.STAT_BONUS_PER_PRESTIGE
  const totalStats: StatBlock = {
    str: Math.floor(rawTotalStats.str * prestigeMultiplier),
    agi: Math.floor(rawTotalStats.agi * prestigeMultiplier),
    vit: Math.floor(rawTotalStats.vit * prestigeMultiplier),
    end: Math.floor(rawTotalStats.end * prestigeMultiplier),
    int: Math.floor(rawTotalStats.int * prestigeMultiplier),
    wis: Math.floor(rawTotalStats.wis * prestigeMultiplier),
    luk: Math.floor(rawTotalStats.luk * prestigeMultiplier),
    cha: Math.floor(rawTotalStats.cha * prestigeMultiplier),
  }

  // Use config-driven derived stat calculation
  const derived = await calculateDerivedStatsFromConfig(totalStats)

  await db.character.update({
    where: { id: characterId },
    data: {
      maxHp: derived.maxHp,
      armor: derived.armor,
      magicResist: derived.magicResist,
    },
  })

  return derived
}
