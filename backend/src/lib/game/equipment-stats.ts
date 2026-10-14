// =============================================================================
// equipment-stats.ts — Recalculate derived stats (thin wrapper, see build-stats.ts)
// =============================================================================

import type { PrismaClient } from '@prisma/client'
import { recalculateFullDerivedStats } from './build-stats'

type TransactionClient = Parameters<Parameters<PrismaClient['$transaction']>[0]>[0]

interface DerivedStats {
  maxHp: number
  armor: number
  magicResist: number
}

/**
 * Recalculate and persist maxHp, armor, magicResist for a character.
 * Call after: stat allocation, equip, unequip, upgrade, level-up.
 *
 * Delegates to `recalculateFullDerivedStats`, which includes passive-tree
 * bonuses. This function used to compute from stats + equipment only, and it
 * is what equip/unequip/upgrade/allocate/respec/buy-stat-points/prestige and
 * durability all call — so unlocking "+9% max HP" and then equipping anything
 * silently deleted the bonus from the persisted `maxHp` that combat reads
 * (2026-10-14 balance audit). One pipeline now.
 */
export async function recalculateDerivedStats(characterId: string, tx?: TransactionClient): Promise<DerivedStats> {
  const full = await recalculateFullDerivedStats(characterId, tx)
  return { maxHp: full.maxHp, armor: full.armor, magicResist: full.magicResist }
}
