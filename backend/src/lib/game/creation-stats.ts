import type { CharacterClass, CharacterOrigin } from '@prisma/client'

/**
 * Starting stats — the single source for character creation, respec and
 * origin changes. Before 2026-10-16 the origin table was copy-pasted into
 * four routes and class bonuses existed ONLY in the iOS creation screen: the
 * client promised "+3 Strength / +2 Vitality" and the server never granted it.
 *
 * Base 10 in every stat, plus the origin bonus, plus the class bonus.
 * GET /api/characters/creation-options serves these tables to the client so
 * the creation screen shows what the server will actually do.
 */
export const STAT_KEYS = ['str', 'agi', 'vit', 'end', 'int', 'wis', 'luk', 'cha'] as const
export type StatKey = (typeof STAT_KEYS)[number]
export type StatBonuses = Partial<Record<StatKey, number>>

export const BASE_STAT_VALUE = 10

export const ORIGIN_BONUSES: Record<CharacterOrigin, StatBonuses> = {
  human:    { cha: 2, wis: 1 },
  orc:      { str: 3, int: -1 },
  skeleton: { end: 2, agi: 1 },
  demon:    { int: 2, wis: 2, cha: -1 },
  dogfolk:  { agi: 2, luk: 1 },
}

/** The values the creation screen has always advertised — now real. */
export const CLASS_BONUSES: Record<CharacterClass, StatBonuses> = {
  warrior: { str: 3, vit: 2 },
  rogue:   { agi: 3, luk: 2 },
  mage:    { int: 3, wis: 2 },
  tank:    { vit: 3, end: 2 },
}

/** The stat a class scales with (shown as "Scales with" on creation). */
export const CLASS_MAIN_STAT: Record<CharacterClass, StatKey> = {
  warrior: 'str',
  rogue: 'agi',
  mage: 'int',
  tank: 'vit',
}

/** Unspent-point baseline: what a fresh character of this class+origin has. */
export function baseStatsFor(characterClass: CharacterClass, origin: CharacterOrigin): Record<StatKey, number> {
  const o = ORIGIN_BONUSES[origin] ?? {}
  const c = CLASS_BONUSES[characterClass] ?? {}
  const out = {} as Record<StatKey, number>
  for (const key of STAT_KEYS) out[key] = BASE_STAT_VALUE + (o[key] ?? 0) + (c[key] ?? 0)
  return out
}

export function calculateMaxHp(vit: number, end: number): number {
  return 80 + vit * 5 + end * 3
}
