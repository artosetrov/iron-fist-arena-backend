import { describe, it, expect } from 'vitest'
import { describeTierChange } from '@/lib/game/tier-change'
import { tierFromRating, STARTING_RATING } from '@/lib/game/tier'

describe('describeTierChange', () => {
  // Silver spans 750..1500 in three 250-wide divisions:
  //   750..1000 Silver III, 1000..1250 Silver II, 1250..1500 Silver I.
  it('returns null when the division does not move', () => {
    expect(describeTierChange(1050, 1100)).toBeNull()
    expect(describeTierChange(1000, 1000)).toBeNull()
    expect(describeTierChange(1100, 1050)).toBeNull()
  })

  it('marks a division promotion inside one tier', () => {
    const change = describeTierChange(999, 1001)
    expect(change).not.toBeNull()
    expect(change!.direction).toBe('promotion')
    expect(change!.isTierChange).toBe(false)
    expect(change!.from.label).toBe('Silver III')
    expect(change!.to.label).toBe('Silver II')
  })

  it('marks a tier promotion across the boundary', () => {
    const change = describeTierChange(1499, 1500)
    expect(change!.direction).toBe('promotion')
    expect(change!.isTierChange).toBe(true)
    expect(change!.from.tier).toBe('silver')
    expect(change!.to.tier).toBe('gold')
    expect(change!.to.label).toBe('Gold III')
  })

  it('marks a demotion, tier and division alike', () => {
    const tier = describeTierChange(1500, 1499)!
    expect(tier.direction).toBe('demotion')
    expect(tier.isTierChange).toBe(true)

    const division = describeTierChange(1001, 999)!
    expect(division.direction).toBe('demotion')
    expect(division.isTierChange).toBe(false)
  })

  it('handles the divisionless top tiers', () => {
    // Diamond I (3500..3750) -> Master (3750+), which has no divisions.
    const promo = describeTierChange(3749, 3750)!
    expect(promo.isTierChange).toBe(true)
    expect(promo.to.tier).toBe('master')
    expect(promo.to.division).toBeNull()
    expect(promo.to.label).toBe('Master')

    const gm = describeTierChange(4249, 4250)!
    expect(gm.to.tier).toBe('grandmaster')
    expect(gm.from.tier).toBe('master')
  })

  it('never reports Challenger — it is a rank cutoff, not a rating band', () => {
    // Deep inside Grandmaster, a big swing still stays Grandmaster.
    expect(describeTierChange(5000, 9000)).toBeNull()
    expect(tierFromRating(9000).tier).toBe('grandmaster')
  })

  it('clamps rather than throwing on a rating below the floor', () => {
    const change = describeTierChange(-50, 300)
    // Bronze III spans 0..250, so -50 clamps into Bronze III and 300 is Bronze II.
    expect(change!.direction).toBe('promotion')
    expect(change!.from.tier).toBe('bronze')
    expect(change!.to.tier).toBe('bronze')
  })

  it('compares against overridden floors, not the frozen table', () => {
    // Admin moves Gold's floor down to 1200. 1250 is then Gold, not Silver.
    const ranges = [
      { key: 'bronze' as const, displayName: 'Bronze', ratingStart: 0, ratingEnd: 750, divisions: 3 },
      { key: 'silver' as const, displayName: 'Silver', ratingStart: 750, ratingEnd: 1200, divisions: 3 },
      { key: 'gold' as const, displayName: 'Gold', ratingStart: 1200, ratingEnd: 2250, divisions: 3 },
      { key: 'platinum' as const, displayName: 'Platinum', ratingStart: 2250, ratingEnd: 3000, divisions: 3 },
      { key: 'diamond' as const, displayName: 'Diamond', ratingStart: 3000, ratingEnd: 3750, divisions: 3 },
      { key: 'master' as const, displayName: 'Master', ratingStart: 3750, ratingEnd: 4250, divisions: 0 },
      { key: 'grandmaster' as const, displayName: 'Grandmaster', ratingStart: 4250, ratingEnd: Number.POSITIVE_INFINITY, divisions: 0 },
    ]
    // With Gold at 1200, Silver is 750..1200 — 150-wide divisions, so 1190 is
    // Silver I and 1250 is Gold III.
    const change = describeTierChange(1190, 1250, ranges)!
    expect(change.isTierChange).toBe(true)
    expect(change.from.label).toBe('Silver I')
    expect(change.to.tier).toBe('gold')

    // On the frozen ladder the same pair never leaves Silver: 1190 is Silver II
    // and 1250 is Silver I, a division move and nothing more.
    const frozen = describeTierChange(1190, 1250)!
    expect(frozen.isTierChange).toBe(false)
    expect(frozen.to.tier).toBe('silver')
  })

  it('leaves the starting rating in a stable division', () => {
    expect(tierFromRating(STARTING_RATING).label).toBe('Silver II')
  })
})
