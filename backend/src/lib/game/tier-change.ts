// =============================================================================
// tier-change.ts — did this fight move the player across a ladder boundary?
// =============================================================================
//
// `/api/pvp/resolve` has always returned the new rating and the delta, and
// nothing else. Crossing from Silver I into Gold III therefore looked exactly
// like any other +24: the client had no way to know a boundary had been
// crossed, so `RankUpCeremonyView` — a finished 206-line screen — was never
// instantiated anywhere, and a promotion passed with a one-line banner at
// best. This turns the crossing itself into part of the payload.
//
// Scope, deliberately: this compares two ratings against the live ladder and
// nothing more. Challenger is NOT detectable here, because it is a top-100
// cutoff on the absolute leaderboard rather than a rating band — a player can
// enter or leave it without their rating moving at all, and resolve does not
// know anyone's rank. A Grandmaster who breaks into the top 100 after a win
// gets no `tier_change` from this, and that is correct: the event did not
// happen at this rating boundary.

import { tierFromRating, type Division, type TierKey } from './tier'

/** One side of a crossing. Mirrors the parts of TierInfo a client renders. */
export interface TierSnapshot {
  tier: TierKey
  division: Division
  label: string
  index: number
}

export interface TierChange {
  direction: 'promotion' | 'demotion'
  /**
   * True when the tier KEY changed (Silver → Gold), false when only the
   * division moved inside one tier (Silver II → Silver I). Both are worth
   * marking, but only the first deserves the full ceremony — three division
   * promotions per tier would wear it out fast.
   */
  isTierChange: boolean
  from: TierSnapshot
  to: TierSnapshot
}

function snapshot(rating: number, ranges?: Parameters<typeof tierFromRating>[2]): TierSnapshot {
  // No leaderboard rank on purpose — see the Challenger note above.
  const info = tierFromRating(rating, undefined, ranges)
  return { tier: info.tier, division: info.division, label: info.label, index: info.index }
}

/**
 * Compare two ratings against the ladder.
 *
 * Returns `null` when the fight left the player in the same division, which is
 * the overwhelmingly common case — callers can hand the result straight to
 * `JSON.stringify` and have the field simply be absent.
 *
 * `ranges` comes from `getPvpLadderRanges()` so a ladder edited in the admin
 * balance panel is the one being compared against. Omit it and the frozen
 * table is used, which is only right in tests.
 */
export function describeTierChange(
  ratingBefore: number,
  ratingAfter: number,
  ranges?: Parameters<typeof tierFromRating>[2],
): TierChange | null {
  const from = snapshot(ratingBefore, ranges)
  const to = snapshot(ratingAfter, ranges)

  if (from.index === to.index) return null

  return {
    direction: to.index > from.index ? 'promotion' : 'demotion',
    isTierChange: from.tier !== to.tier,
    from,
    to,
  }
}
