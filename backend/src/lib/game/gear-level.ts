// =============================================================================
// gear-level.ts — the level a character may equip / be offered gear at.
//
// Prestige resets `level` to 1 but the character has earned the whole ladder
// once: it keeps its L40 sword equipped, and the design intent (balance.ts
// PRESTIGE, docs/06_game_systems/PROGRESSION.md) is a replay of the curve with
// a stat bonus — not a character who can no longer re-equip its own gear
// after a swap, sees a L3 shop, and drops L1 whites. Every level gate on gear
// (equip, shop listing, loot level cap) goes through this helper so the rule
// lives in one place.
// =============================================================================

import { PRESTIGE } from './balance'

export function effectiveGearLevel(
  level: number,
  prestigeLevel: number | null | undefined,
  maxLevel: number = PRESTIGE.MAX_LEVEL,
): number {
  const safeLevel = Number.isFinite(level) ? Math.max(1, Math.floor(level)) : 1
  if ((prestigeLevel ?? 0) > 0) return Math.max(safeLevel, maxLevel)
  return safeLevel
}
