// =============================================================================
// tier.ts — PvP tier and division calculation (W3.D5)
// =============================================================================
//
// Variant A: 8 tiers × 3 divisions (250 ELO per division), + Master / Grandmaster
// (no divisions) + Challenger (top-100 by absolute rank, regardless of rating).
//
// Industry precedent:
//   - League of Legends: 10 tiers × 4 divisions (100 LP per division)
//   - Valorant: 9 tiers × 3 divisions (100 RR per division)
//   - Apex Legends: 8 tiers × 4 divisions
//   - Clash Royale Path of Legends: 10 leagues × 10 stars
//
// All market leaders share the same invariants:
//   1. 3-5 divisions per tier to generate dopamine hits on promotion
//   2. Top tier is capped by absolute rank (top-N), not by rating number
//   3. Starting rating lands in the lower-to-middle tier (Silver-ish for us)
//   4. Decay/demotion exists only from Diamond+ (deferred to W4)
//
// Hexbound baseline: starting pvpRating = 1000 → Silver II (default).
//
// Zero migration cost: PVP_RANKS is an orphan constant with no gameplay
// consumer; pure functions here replace it. The new PVP_RANKS shape stays
// in balance.ts for live-config compatibility, but the gameplay/UI truth
// lives in tierFromRating() / divisionFromRating() below.

/** Tier keys — 8 base tiers, ascending. Challenger is computed separately. */
export type TierKey =
  | 'bronze'
  | 'silver'
  | 'gold'
  | 'platinum'
  | 'diamond'
  | 'master'
  | 'grandmaster'
  | 'challenger'

/** Division within a tier. Master+/GM/Challenger have no division. */
export type Division = 'III' | 'II' | 'I' | null

/** Resolved tier result. */
export interface TierInfo {
  /** Canonical tier key (lowercase). */
  tier: TierKey
  /** Division inside the tier, or null for Master/GM/Challenger. */
  division: Division
  /** Display label: "Silver II", "Master", "Challenger". */
  label: string
  /** 0-based global tier index (Bronze III = 0 … Challenger = 23). Used for sorting. */
  index: number
}

/**
 * Tier range definition.
 * `ratingStart` is inclusive, `ratingEnd` is exclusive (next tier starts there).
 * `divisions` is the number of divisions in this tier (0 = no divisions).
 */
interface TierRange {
  key: TierKey
  displayName: string
  ratingStart: number
  ratingEnd: number
  divisions: number
}

/**
 * Variant A ladder (W3.D5 frozen).
 *
 * Each 250-pt window inside a 3-division tier maps to III → II → I as rating
 * climbs. Silver II holds the starting rating (1000), which gives a new player
 * "room to fall" without bottoming out at Bronze III. 750-pt tier widths keep
 * the ladder approximately linear in E(games-to-promote): ~7-10 wins per
 * division for a K=32 player, which matches LoL/Valorant cadence.
 */
const TIER_RANGES: readonly TierRange[] = [
  { key: 'bronze',      displayName: 'Bronze',      ratingStart: 0,    ratingEnd: 750,  divisions: 3 },
  { key: 'silver',      displayName: 'Silver',      ratingStart: 750,  ratingEnd: 1500, divisions: 3 },
  { key: 'gold',        displayName: 'Gold',        ratingStart: 1500, ratingEnd: 2250, divisions: 3 },
  { key: 'platinum',    displayName: 'Platinum',    ratingStart: 2250, ratingEnd: 3000, divisions: 3 },
  { key: 'diamond',     displayName: 'Diamond',     ratingStart: 3000, ratingEnd: 3750, divisions: 3 },
  { key: 'master',      displayName: 'Master',      ratingStart: 3750, ratingEnd: 4250, divisions: 0 },
  { key: 'grandmaster', displayName: 'Grandmaster', ratingStart: 4250, ratingEnd: Number.POSITIVE_INFINITY, divisions: 0 },
] as const

/**
 * Leaderboard rank cutoff for Challenger tier. Players in Grandmaster range
 * who are in the top N of the absolute leaderboard get promoted to Challenger.
 * Top-N is computed at query-time from the leaderboard, NOT persisted on the
 * character — so a player can enter/leave Challenger without any DB writes.
 */
export const CHALLENGER_RANK_CUTOFF = 100

/** Starting rating for new characters — used by placement / defaults. */
export const STARTING_RATING = 1000

/**
 * Division labels in ascending order: lowest to highest within a 3-div tier.
 * Convention matches LoL/Valorant: III (entry) → II → I (top).
 */
const DIVISION_LABELS: readonly ('III' | 'II' | 'I')[] = ['III', 'II', 'I']

/**
 * Compute the division label within a tier of width `tierWidth` given
 * in-tier rating `ratingOffset` and `divisions` count.
 *
 * Pure function, deterministic. Clamps offset into valid range so that
 * off-by-one rounding can never fall off the edge.
 */
function computeDivision(ratingOffset: number, tierWidth: number, divisions: number): Division {
  if (divisions <= 0) return null
  if (ratingOffset < 0) return DIVISION_LABELS[0]
  const divisionWidth = tierWidth / divisions
  const rawIdx = Math.floor(ratingOffset / divisionWidth)
  const idx = Math.max(0, Math.min(divisions - 1, rawIdx))
  return DIVISION_LABELS[idx]
}

/**
 * Return the tier & division for a given rating.
 *
 * @param rating          The character's pvpRating.
 * @param leaderboardRank Optional absolute rank in the global leaderboard
 *                        (1 = #1 player). If provided and <= CHALLENGER_RANK_CUTOFF
 *                        AND the character is already at Grandmaster rating floor,
 *                        the result is promoted to Challenger.
 */
export function tierFromRating(rating: number, leaderboardRank?: number): TierInfo {
  // Clamp negative ratings to 0 (ELO MIN_RATING is 0 per balance.ts).
  const safe = Math.max(0, Math.floor(rating))

  // Find the matching base tier range.
  let range: TierRange = TIER_RANGES[0]
  for (const r of TIER_RANGES) {
    if (safe >= r.ratingStart && safe < r.ratingEnd) {
      range = r
      break
    }
  }
  // Edge case: rating beyond GM's open upper bound stays in GM (handled by infinity above).

  // Challenger promotion: must be in the Grandmaster rating band AND top-N rank.
  if (
    range.key === 'grandmaster'
    && leaderboardRank !== undefined
    && leaderboardRank > 0
    && leaderboardRank <= CHALLENGER_RANK_CUTOFF
  ) {
    return {
      tier: 'challenger',
      division: null,
      label: 'Challenger',
      index: globalTierIndex('challenger', null),
    }
  }

  // Compute division if the tier has divisions.
  const tierWidth = range.ratingEnd - range.ratingStart
  const division = range.divisions > 0
    ? computeDivision(safe - range.ratingStart, tierWidth, range.divisions)
    : null

  const label = division
    ? `${range.displayName} ${division}`
    : range.displayName

  return {
    tier: range.key,
    division,
    label,
    index: globalTierIndex(range.key, division),
  }
}

/**
 * Thin wrapper: just return the division, or null for Master+ / Challenger.
 */
export function divisionFromRating(rating: number): Division {
  return tierFromRating(rating).division
}

/**
 * Return the global 0-based index for sorting / comparison purposes.
 * Bronze III = 0, Bronze II = 1, ..., Silver III = 3, ..., Challenger = max.
 *
 * - 5 tiers with divisions (Bronze, Silver, Gold, Platinum, Diamond) × 3 = 15 slots [0..14]
 * - Master = 15, Grandmaster = 16, Challenger = 17
 */
export function globalTierIndex(tier: TierKey, division: Division): number {
  const baseOffsets: Record<TierKey, number> = {
    bronze:      0,
    silver:      3,
    gold:        6,
    platinum:    9,
    diamond:     12,
    master:      15,
    grandmaster: 16,
    challenger:  17,
  }

  const base = baseOffsets[tier]

  if (tier === 'master' || tier === 'grandmaster' || tier === 'challenger') {
    return base
  }

  // Division III = +0, II = +1, I = +2
  const divOffset = division === 'I' ? 2 : division === 'II' ? 1 : 0
  return base + divOffset
}

/**
 * Inverse: minimum rating required to reach a given tier.
 * Useful for UI ("next promo in X ELO") and tests.
 */
export function minRatingForTier(tier: TierKey): number {
  if (tier === 'challenger') {
    // Challenger has no rating floor — it's a top-N cutoff inside Grandmaster.
    const gm = TIER_RANGES.find(r => r.key === 'grandmaster')!
    return gm.ratingStart
  }
  const range = TIER_RANGES.find(r => r.key === tier)
  if (!range) throw new Error(`Unknown tier key: ${tier}`)
  return range.ratingStart
}

/**
 * Rating required to reach the NEXT division or tier promotion from current rating.
 * Returns null if the player is already at the top (Grandmaster ceiling).
 */
export function ratingToNextPromotion(rating: number): number | null {
  const info = tierFromRating(rating)

  // Grandmaster / Challenger — no further promotion inside the ladder.
  if (info.tier === 'grandmaster' || info.tier === 'challenger') return null

  const safe = Math.max(0, Math.floor(rating))
  const range = TIER_RANGES.find(r => r.key === info.tier)!
  const tierWidth = range.ratingEnd - range.ratingStart

  if (range.divisions <= 0) {
    // Master — promoting means crossing into GM.
    return range.ratingEnd - safe
  }

  // Which division are we in? Next division threshold is divisionWidth higher.
  const divisionWidth = tierWidth / range.divisions
  const offset = safe - range.ratingStart
  const currentDivIdx = Math.floor(offset / divisionWidth)
  const nextDivIdx = Math.min(currentDivIdx + 1, range.divisions)
  // If nextDivIdx == range.divisions, next promotion is into the next tier.
  const nextThreshold = range.ratingStart + nextDivIdx * divisionWidth
  return nextThreshold - safe
}

/**
 * Return the ordered list of all tier ranges. Useful for admin panels and
 * leaderboard slicing.
 */
export function allTierRanges(): ReadonlyArray<TierRange> {
  return TIER_RANGES
}
