// =============================================================================
// build-stats.ts — Full stat calculation pipeline including passives
// =============================================================================

import { prisma } from '@/lib/prisma'
import type { PrismaClient } from '@prisma/client'
import { applyPrestigeBonus } from './progression'
import { aggregatePassiveBonuses, emptyPassiveBonuses, type PassiveBonuses } from './passives'

type TransactionClient = Parameters<Parameters<PrismaClient['$transaction']>[0]>[0]

const STAT_KEYS = ['str', 'agi', 'vit', 'end', 'int', 'wis', 'luk', 'cha'] as const

export interface StatBlock {
  str: number
  agi: number
  vit: number
  end: number
  int: number
  wis: number
  luk: number
  cha: number
}

export interface FullDerivedStats {
  maxHp: number
  armor: number
  magicResist: number
  totalStats: StatBlock
}

// --- Equipment Bonuses ---

function sumEquipmentBonuses(
  equippedItems: Array<{
    item: { baseStats: unknown }
    upgradeLevel: number
    durability: number
  }>
): StatBlock {
  const bonus: StatBlock = { str: 0, agi: 0, vit: 0, end: 0, int: 0, wis: 0, luk: 0, cha: 0 }

  for (const eq of equippedItems) {
    if (eq.durability <= 0) continue
    const bs = eq.item.baseStats as Record<string, number> | null
    if (!bs) continue
    for (const key of STAT_KEYS) {
      if (typeof bs[key] === 'number') {
        bonus[key] += bs[key] + eq.upgradeLevel
      }
    }
  }

  return bonus
}

// --- Full Stat Calculation ---

/**
 * Calculate complete character stats with passives.
 *
 * Order:
 * 1. Base character stats
 * 2. + Equipment flat bonuses
 * 3. + Passive flat stat bonuses
 * 4. × Passive percent stat bonuses
 * 5. × Prestige bonus (+5% per level)
 * 6. Derive HP/armor/MR from total stats
 * 7. + Passive flat HP/armor/MR
 * 8. × Passive percent HP/armor/MR
 */
export function calculateFullStats(
  baseStats: StatBlock,
  equipmentBonuses: StatBlock,
  passiveBonuses: PassiveBonuses,
  prestigeLevel: number,
): FullDerivedStats {
  // Steps 1-3: base + equipment + passive flat
  const withFlat: StatBlock = { str: 0, agi: 0, vit: 0, end: 0, int: 0, wis: 0, luk: 0, cha: 0 }
  for (const key of STAT_KEYS) {
    withFlat[key] = baseStats[key] + equipmentBonuses[key] + (passiveBonuses.flatStats[key] ?? 0)
  }

  // Step 4: apply passive percent stat bonuses
  const withPercent: StatBlock = { str: 0, agi: 0, vit: 0, end: 0, int: 0, wis: 0, luk: 0, cha: 0 }
  for (const key of STAT_KEYS) {
    const pct = passiveBonuses.percentStats[key] ?? 0
    withPercent[key] = Math.floor(withFlat[key] * (1 + pct / 100))
  }

  // Step 5: apply prestige bonus
  const totalStats: StatBlock = { str: 0, agi: 0, vit: 0, end: 0, int: 0, wis: 0, luk: 0, cha: 0 }
  for (const key of STAT_KEYS) {
    totalStats[key] = applyPrestigeBonus(withPercent[key], prestigeLevel)
  }

  // Step 6: derive base HP/armor/MR
  let maxHp = 80 + totalStats.vit * 5 + totalStats.end * 3
  let armor = Math.floor(totalStats.end * 2 + totalStats.str * 0.5)
  let magicResist = Math.floor(totalStats.wis * 2 + totalStats.int * 0.5)

  // Step 7: add passive flat HP/armor/MR
  maxHp += passiveBonuses.flatHp
  armor += passiveBonuses.flatArmor
  magicResist += passiveBonuses.flatMagicResist

  // Step 8: apply passive percent HP/armor/MR
  maxHp = Math.floor(maxHp * (1 + passiveBonuses.percentHp / 100))
  armor = Math.floor(armor * (1 + passiveBonuses.percentArmor / 100))
  magicResist = Math.floor(magicResist * (1 + passiveBonuses.percentMagicResist / 100))

  return { maxHp, armor, magicResist, totalStats }
}

// --- Database Integration ---

/**
 * Recalculate and persist derived stats for a character, including passive bonuses.
 * Replaces the original recalculateDerivedStats when passives are involved.
 */
export async function recalculateFullDerivedStats(
  characterId: string,
  tx?: TransactionClient,
): Promise<FullDerivedStats> {
  const db = tx ?? prisma

  const character = await db.character.findUnique({
    where: { id: characterId },
    select: {
      str: true, agi: true, vit: true, end: true,
      int: true, wis: true, luk: true, cha: true,
      prestigeLevel: true,
      equipment: {
        where: { isEquipped: true },
        select: {
          upgradeLevel: true,
          durability: true,
          item: { select: { baseStats: true } },
        },
      },
      characterPassives: {
        select: {
          node: {
            select: { bonusType: true, bonusStat: true, bonusValue: true },
          },
        },
      },
    },
  })

  if (!character) throw new Error('Character not found')

  const baseStats: StatBlock = {
    str: character.str, agi: character.agi, vit: character.vit, end: character.end,
    int: character.int, wis: character.wis, luk: character.luk, cha: character.cha,
  }

  const eqBonus = sumEquipmentBonuses(
    character.equipment.map((e) => ({
      item: { baseStats: e.item.baseStats },
      upgradeLevel: e.upgradeLevel,
      durability: e.durability,
    }))
  )

  const passiveBonuses = character.characterPassives.length > 0
    ? aggregatePassiveBonuses(
        character.characterPassives.map((cp) => ({
          bonusType: cp.node.bonusType,
          bonusStat: cp.node.bonusStat,
          bonusValue: cp.node.bonusValue,
        }))
      )
    : emptyPassiveBonuses()

  const derived = calculateFullStats(
    baseStats,
    eqBonus,
    passiveBonuses,
    character.prestigeLevel ?? 0,
  )

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
