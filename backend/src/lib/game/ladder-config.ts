// =============================================================================
// ladder-config.ts — guarding the `pvp_ranks.*` config rows
// =============================================================================
//
// These rows were inert until 2026-09-15: the admin balance panel wrote them
// and no gameplay code ever read them. They drive the live ladder now
// (`getPvpLadderRanges`), which means a set of floors that cannot form a ladder
// has to be refused at the write, with a reason.
//
// The alternative is what `resolveTierRanges` does on its own — reject the set
// wholesale and fall back to the frozen table — and from the balance panel that
// is indistinguishable from a save that worked and changed nothing. The panel
// would show Gold at 1400 while every badge in the game said 1500.
//
// Three endpoints can write these rows and all three must go through here:
// the config PUT/POST, the config DELETE (removing one floor while the others
// keep their overrides can leave the remaining ones out of order), and the
// snapshot restore (which replaces every row at once).

import { allTierRanges, asTierFloor, describeTierFloorProblem, type TierFloorOverrides } from './tier'

export const PVP_RANK_KEY_PREFIX = 'pvp_ranks.'

export interface ConfigRowLike {
  key: string
  value: unknown
}

export function isPvpRankKey(key: string): boolean {
  return key.startsWith(PVP_RANK_KEY_PREFIX)
}

function tierKeys(): string[] {
  return allTierRanges().map((range) => range.key)
}

/** The tier a `pvp_ranks.*` key names, or null if it names nothing on the ladder. */
export function tierKeyFromConfigKey(key: string): string | null {
  if (!isPvpRankKey(key)) return null
  const tier = key.slice(PVP_RANK_KEY_PREFIX.length)
  return tierKeys().includes(tier) ? tier : null
}

/**
 * Build the floor set a given collection of rows describes.
 *
 * Tiers with no row keep their frozen floor, which is exactly how the runtime
 * reads them — so a partial set (one edited field, or a snapshot that predates
 * a tier) validates as the ladder it will actually produce.
 *
 * Rows for unknown tiers and unusable values are ignored rather than rejected:
 * they are already ignored at runtime, and failing every future save over a
 * stale row would be worse than the row itself.
 */
export function tierFloorsFrom(rows: ConfigRowLike[]): TierFloorOverrides {
  const floors: TierFloorOverrides = {}
  for (const range of allTierRanges()) {
    floors[range.key as keyof TierFloorOverrides] = range.ratingStart
  }

  for (const row of rows) {
    const tier = tierKeyFromConfigKey(row.key)
    if (!tier) continue
    const floor = asTierFloor(row.value)
    if (floor === null) continue
    floors[tier as keyof TierFloorOverrides] = floor
  }

  return floors
}

/**
 * Why the ladder these rows describe is unusable, or `null` when it is fine.
 */
export function describeLadderRowsProblem(rows: ConfigRowLike[]): string | null {
  return describeTierFloorProblem(tierFloorsFrom(rows))
}
