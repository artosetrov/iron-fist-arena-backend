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
// PVP_RANKS in balance.ts is derived from this file (see minRatingForTier) and
// exists only so the admin balance panel has `pvp_ranks.*` keys to edit. Those
// edits flow back in through resolveTierRanges(); the classification itself —
// tierFromRating() / divisionFromRating() — lives here and nowhere else, on the
// server, in the admin panel, or on the client.

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
  /** 0-based global tier index (Bronze III = 0 … Challenger = 17). Used for sorting. */
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
 * Per-tier rating-floor overrides, keyed by tier. Sourced from live config
 * (`pvp_ranks.*`, editable in the admin balance panel).
 *
 * Before 2026-09-15 those keys were read into `/api/game/init` and nothing
 * else: `tierFromRating` always used the frozen table below, so editing
 * "Minimum ELO for Gold" in the admin panel changed nothing anywhere. The
 * overrides now flow through `resolveTierRanges()` into every consumer —
 * leaderboard, init payload and the iOS ladder contract.
 */
export type TierFloorOverrides = Partial<Record<Exclude<TierKey, 'challenger'>, number>>

/**
 * The tier Challenger promotes out of. Exported so the client contract can
 * state it explicitly instead of assuming "the last tier in the list".
 */
export const CHALLENGER_PROMOTES_FROM: TierKey = 'grandmaster'

/**
 * Apply floor overrides to the frozen ladder and re-stitch the tier bounds.
 *
 * A ladder is only usable if it starts at 0 and is strictly ascending —
 * otherwise `tierFromRating` would have unreachable or overlapping tiers and
 * a division width of zero (or negative). An invalid override set is
 * therefore ignored WHOLESALE, not per-tier: partially applying it would
 * produce a ladder nobody authored. Returns the frozen table in that case.
 */
/**
 * Coerce one stored floor.
 *
 * `GameConfig.value` is a JSON column, so a floor can come back as the string
 * "1400" rather than the number 1400 depending on how it was written. Every
 * reader has to agree about that — an admin endpoint that validates "1400" as
 * 1400 while this file skips it as non-numeric is how you get a panel showing
 * 1400 and a game still using 1500, which is the exact failure this whole
 * change set exists to remove. Returns `null` for anything unusable.
 */
export function asTierFloor(value: unknown): number | null {
  const parsed = typeof value === 'string' && value.trim() !== '' ? Number(value) : value
  if (typeof parsed !== 'number' || !Number.isFinite(parsed)) return null
  return Math.max(0, Math.floor(parsed))
}

function applyTierFloors(overrides: TierFloorOverrides): TierRange[] {
  const next: TierRange[] = TIER_RANGES.map((r) => {
    const override = asTierFloor(overrides[r.key as Exclude<TierKey, 'challenger'>])
    return { ...r, ratingStart: override ?? r.ratingStart }
  })

  // Tier ends are derived, never configured: one tier ends where the next begins.
  for (let i = 0; i < next.length - 1; i++) {
    next[i].ratingEnd = next[i + 1].ratingStart
  }
  next[next.length - 1].ratingEnd = Number.POSITIVE_INFINITY

  return next
}

/**
 * Explain why a set of tier floors cannot form a ladder, or `null` if it can.
 *
 * Exported so the admin config endpoint can REFUSE such a save with a reason,
 * instead of accepting it and having `resolveTierRanges` quietly fall back to
 * the frozen ladder — which looks, from the balance panel, exactly like a save
 * that worked and did nothing.
 */
export function describeTierFloorProblem(overrides: TierFloorOverrides): string | null {
  const ranges = applyTierFloors(overrides)

  if (ranges[0].ratingStart !== 0) {
    return `the lowest tier (${ranges[0].key}) must start at 0, not ${ranges[0].ratingStart}`
  }

  for (let i = 1; i < ranges.length; i++) {
    const previous = ranges[i - 1]
    const current = ranges[i]
    if (current.ratingStart <= previous.ratingStart) {
      return `${current.key} starts at ${current.ratingStart}, which is not above ${previous.key} at ${previous.ratingStart}`
        + ' — each tier must start strictly higher than the one below it'
    }
  }

  return null
}

const warnedFloorSets = new Set<string>()

export function resolveTierRanges(overrides?: TierFloorOverrides): readonly TierRange[] {
  if (!overrides) return TIER_RANGES

  const problem = describeTierFloorProblem(overrides)
  if (problem) {
    // Rejected wholesale, not per-tier: half-applying an invalid set produces a
    // ladder nobody authored. The admin write paths refuse these at the door,
    // so reaching here means the rows were written some other way.
    //
    // Warned once per distinct bad set, not once per request: this runs on
    // every /api/game/init and every leaderboard cache miss, and a permanently
    // invalid set would otherwise emit one line per app launch forever.
    const signature = JSON.stringify(overrides)
    if (!warnedFloorSets.has(signature)) {
      warnedFloorSets.add(signature)
      console.warn(`[tier] pvp_ranks overrides rejected (${problem}); using the frozen ladder.`)
    }
    return TIER_RANGES
  }

  return applyTierFloors(overrides)
}

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
export function tierFromRating(
  rating: number,
  leaderboardRank?: number,
  ranges: readonly TierRange[] = TIER_RANGES,
): TierInfo {
  // Clamp negative ratings to 0 (ELO MIN_RATING is 0 per balance.ts).
  const safe = Math.max(0, Math.floor(rating))

  // Find the matching base tier range.
  let range: TierRange = ranges[0]
  for (const r of ranges) {
    if (safe >= r.ratingStart && safe < r.ratingEnd) {
      range = r
      break
    }
  }
  // Edge case: rating beyond GM's open upper bound stays in GM (handled by infinity above).

  // Challenger promotion: must be in the Grandmaster rating band AND top-N rank.
  if (
    range.key === CHALLENGER_PROMOTES_FROM
    && leaderboardRank !== undefined
    && leaderboardRank > 0
    && leaderboardRank <= CHALLENGER_RANK_CUTOFF
  ) {
    return {
      tier: 'challenger',
      division: null,
      label: 'Challenger',
      index: globalTierIndex('challenger', null, ranges),
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
    index: globalTierIndex(range.key, division, ranges),
  }
}

/**
 * Thin wrapper: just return the division, or null for Master+ / Challenger.
 */
export function divisionFromRating(
  rating: number,
  ranges: readonly TierRange[] = TIER_RANGES,
): Division {
  return tierFromRating(rating, undefined, ranges).division
}

/**
 * Return the global 0-based index for sorting / comparison purposes.
 * Bronze III = 0, Bronze II = 1, ..., Silver III = 3, ..., Challenger = max.
 *
 * - 5 tiers with divisions (Bronze, Silver, Gold, Platinum, Diamond) × 3 = 15 slots [0..14]
 * - Master = 15, Grandmaster = 16, Challenger = 17
 */
export function globalTierIndex(
  tier: TierKey,
  division: Division,
  ranges: readonly TierRange[] = TIER_RANGES,
): number {
  let index = 0
  for (const r of ranges) {
    if (r.key === tier) {
      if (r.divisions <= 0) return index
      const divOffset = division === 'I' ? 2 : division === 'II' ? 1 : 0
      return index + Math.min(divOffset, r.divisions - 1)
    }
    index += Math.max(1, r.divisions)
  }
  // Challenger is not in TIER_RANGES — it sits one slot above the top tier.
  return index
}

/**
 * Inverse: minimum rating required to reach a given tier.
 * Useful for UI ("next promo in X ELO") and tests.
 */
export function minRatingForTier(
  tier: TierKey,
  ranges: readonly TierRange[] = TIER_RANGES,
): number {
  if (tier === 'challenger') {
    // Challenger has no rating floor — it's a top-N cutoff inside Grandmaster.
    const gm = ranges.find(r => r.key === CHALLENGER_PROMOTES_FROM)!
    return gm.ratingStart
  }
  const range = ranges.find(r => r.key === tier)
  if (!range) throw new Error(`Unknown tier key: ${tier}`)
  return range.ratingStart
}

/**
 * Rating required to reach the NEXT division or tier promotion from current rating.
 * Returns null if the player is already at the top (Grandmaster ceiling).
 */
export function ratingToNextPromotion(
  rating: number,
  ranges: readonly TierRange[] = TIER_RANGES,
): number | null {
  const info = tierFromRating(rating, undefined, ranges)

  // Grandmaster / Challenger — no further promotion inside the ladder.
  if (info.tier === 'grandmaster' || info.tier === 'challenger') return null

  const safe = Math.max(0, Math.floor(rating))
  const range = ranges.find(r => r.key === info.tier)!
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
  //
  // Round the threshold UP: ratings are integers, and with a tier width that
  // does not divide evenly by 3 (possible as soon as the floors are
  // live-configurable) the exact boundary lands mid-integer. Returning the
  // fractional distance told the player "12 more rating" when 12 more rating
  // left them in the same division — `tierFromRating` floors, so the threshold
  // has to be floor-reachable.
  const nextThreshold = Math.ceil(range.ratingStart + nextDivIdx * divisionWidth)
  return nextThreshold - safe
}

/**
 * Return the ordered list of all tier ranges. Useful for admin panels and
 * leaderboard slicing.
 */
export function allTierRanges(
  ranges: readonly TierRange[] = TIER_RANGES,
): ReadonlyArray<TierRange> {
  return ranges
}

// =============================================================================
// Client contract
// =============================================================================
//
// The iOS client needs the tier for every rating it renders — its own hero,
// every opponent card, every friend row, every duel challenge — and the server
// attaches a resolved tier only to leaderboard entries. Until 2026-09-15 the
// client filled that gap with its own table in `PvPRank.swift`: 6 tiers, no
// divisions, thresholds from a different era (Silver at 1200 instead of 750).
// Same account, two answers: the leaderboard said "Silver II", the arena badge
// next to it said "Bronze".
//
// Rather than attaching a tier to a dozen more payloads, the ladder itself is
// the contract: shipped once in `/api/game/init`, rendered by the client with
// no thresholds of its own. This is the shape iOS decodes into `PvPLadder`.

export interface PvPLadderTier {
  key: TierKey
  displayName: string
  ratingStart: number
  /** Exclusive upper bound; `null` for the open-ended top tier. */
  ratingEnd: number | null
  divisions: number
}

export interface PvPLadderContract {
  tiers: PvPLadderTier[]
  /** Division labels, lowest first — index 0 is the tier's entry division. */
  divisionLabels: string[]
  challengerKey: TierKey
  challengerDisplayName: string
  challengerPromotesFrom: TierKey
  challengerRankCutoff: number
  startingRating: number
}

/**
 * Serialize the ladder for the client.
 *
 * `Number.POSITIVE_INFINITY` does not survive JSON (it serializes to `null`),
 * so the open top bound is emitted as an explicit `null` rather than left to
 * chance.
 */
export function ladderContract(ranges: readonly TierRange[] = TIER_RANGES): PvPLadderContract {
  return {
    tiers: ranges.map((r) => ({
      key: r.key,
      displayName: r.displayName,
      ratingStart: r.ratingStart,
      ratingEnd: Number.isFinite(r.ratingEnd) ? r.ratingEnd : null,
      divisions: r.divisions,
    })),
    divisionLabels: [...DIVISION_LABELS],
    challengerKey: 'challenger',
    challengerDisplayName: 'Challenger',
    challengerPromotesFrom: CHALLENGER_PROMOTES_FROM,
    challengerRankCutoff: CHALLENGER_RANK_CUTOFF,
    startingRating: STARTING_RATING,
  }
}
