/**
 * The ladder as a contract.
 *
 * Two findings from the 2026-09-10 audit are covered here:
 *
 *  1. The iOS client classified ratings with its own table (6 tiers, no
 *     divisions, Silver at 1200) while the server used tier.ts (8 tiers ×
 *     3 divisions, Silver at 750). `ladderContract()` is what replaced the
 *     client's table, so its shape is now load-bearing.
 *
 *  2. The admin balance panel exposed `pvp_ranks.*` as editable tier floors
 *     and nothing read them: `tierFromRating` always used the frozen table.
 *     `resolveTierRanges()` is what makes those edits real — including
 *     refusing an edit that would produce an unusable ladder.
 */
import { describe, it, expect, vi } from 'vitest'
import {
  tierFromRating,
  globalTierIndex,
  ladderContract,
  resolveTierRanges,
  allTierRanges,
  minRatingForTier,
  ratingToNextPromotion,
  STARTING_RATING,
  asTierFloor,
  describeTierFloorProblem,
  CHALLENGER_PROMOTES_FROM,
  CHALLENGER_RANK_CUTOFF,
} from '../../src/lib/game/tier'
import { PVP_RANKS } from '../../src/lib/game/balance'

describe('ladderContract', () => {
  const contract = ladderContract()

  it('carries every tier the server can return', () => {
    expect(contract.tiers.map(t => t.key)).toEqual([
      'bronze', 'silver', 'gold', 'platinum', 'diamond', 'master', 'grandmaster',
    ])
  })

  it('emits the open top bound as null, because Infinity does not survive JSON', () => {
    const top = contract.tiers[contract.tiers.length - 1]
    expect(top.ratingEnd).toBeNull()
    // The real serialization path, not just the object we built.
    expect(JSON.parse(JSON.stringify(contract)).tiers.at(-1).ratingEnd).toBeNull()
  })

  it('states where Challenger comes from instead of leaving the client to guess', () => {
    expect(contract.challengerPromotesFrom).toBe(CHALLENGER_PROMOTES_FROM)
    expect(contract.challengerRankCutoff).toBe(CHALLENGER_RANK_CUTOFF)
    expect(contract.challengerKey).toBe('challenger')
  })

  it('orders division labels entry-first, so index 0 is the tier floor', () => {
    expect(contract.divisionLabels).toEqual(['III', 'II', 'I'])
    expect(tierFromRating(contract.tiers[1].ratingStart).division).toBe('III')
  })

  it('ships the starting rating so a fresh client agrees about the default tier', () => {
    expect(contract.startingRating).toBe(STARTING_RATING)
    expect(tierFromRating(contract.startingRating).label).toBe('Silver II')
  })

  it('is a projection of the ranges it is given, not a second table', () => {
    const shifted = resolveTierRanges({ silver: 800 })
    expect(ladderContract(shifted).tiers[1].ratingStart).toBe(800)
    // …and the tier before it now ends there too.
    expect(ladderContract(shifted).tiers[0].ratingEnd).toBe(800)
  })
})

describe('globalTierIndex', () => {
  it('reproduces the hand-written offsets it replaced', () => {
    expect(globalTierIndex('bronze', 'III')).toBe(0)
    expect(globalTierIndex('bronze', 'I')).toBe(2)
    expect(globalTierIndex('silver', 'III')).toBe(3)
    expect(globalTierIndex('gold', 'III')).toBe(6)
    expect(globalTierIndex('platinum', 'III')).toBe(9)
    expect(globalTierIndex('diamond', 'III')).toBe(12)
    expect(globalTierIndex('master', null)).toBe(15)
    expect(globalTierIndex('grandmaster', null)).toBe(16)
    expect(globalTierIndex('challenger', null)).toBe(17)
  })

  it('increases monotonically with rating across the whole ladder', () => {
    let previous = -1
    for (let rating = 0; rating <= 5000; rating += 25) {
      const index = tierFromRating(rating).index
      expect(index).toBeGreaterThanOrEqual(previous)
      previous = index
    }
  })
})

describe('PVP_RANKS', () => {
  it('is derived from the ladder, so the admin panel edits real floors', () => {
    expect(PVP_RANKS.BRONZE).toBe(minRatingForTier('bronze'))
    expect(PVP_RANKS.SILVER).toBe(minRatingForTier('silver'))
    expect(PVP_RANKS.GOLD).toBe(minRatingForTier('gold'))
    expect(PVP_RANKS.PLATINUM).toBe(minRatingForTier('platinum'))
    expect(PVP_RANKS.DIAMOND).toBe(minRatingForTier('diamond'))
    expect(PVP_RANKS.MASTER).toBe(minRatingForTier('master'))
    expect(PVP_RANKS.GRANDMASTER).toBe(minRatingForTier('grandmaster'))
  })

  it('still holds the frozen W3.D5 values', () => {
    expect(PVP_RANKS).toEqual({
      BRONZE: 0, SILVER: 750, GOLD: 1500, PLATINUM: 2250,
      DIAMOND: 3000, MASTER: 3750, GRANDMASTER: 4250,
    })
  })
})

describe('resolveTierRanges', () => {
  it('returns the frozen table when there is nothing to override', () => {
    expect(resolveTierRanges()).toBe(allTierRanges())
  })

  it('applies a floor and re-stitches the neighbouring bound', () => {
    const ranges = resolveTierRanges({ gold: 1400 })
    const silver = ranges.find(r => r.key === 'silver')!
    const gold = ranges.find(r => r.key === 'gold')!
    expect(gold.ratingStart).toBe(1400)
    expect(silver.ratingEnd).toBe(1400)
    // A rating that used to be Silver I is now Gold III.
    expect(tierFromRating(1450, undefined, ranges).label).toBe('Gold III')
    expect(tierFromRating(1450).label).toBe('Silver I')
  })

  it('keeps divisions proportional to the edited tier width', () => {
    const ranges = resolveTierRanges({ silver: 500, gold: 1100 })
    // Silver is now 600 wide → 200 per division.
    expect(tierFromRating(500, undefined, ranges).label).toBe('Silver III')
    expect(tierFromRating(700, undefined, ranges).label).toBe('Silver II')
    expect(tierFromRating(900, undefined, ranges).label).toBe('Silver I')
    expect(tierFromRating(1100, undefined, ranges).label).toBe('Gold III')
  })

  it('leaves the top tier open-ended after an override', () => {
    const ranges = resolveTierRanges({ grandmaster: 4000 })
    expect(tierFromRating(999999, undefined, ranges).tier).toBe('grandmaster')
  })

  it.each([
    ['a non-ascending pair', { gold: 700 }],
    ['a tier that overtakes the one above it', { silver: 4000 }],
    ['a bronze floor above zero', { bronze: 100 }],
    ['two tiers sharing a floor', { gold: 750 }],
  ])('rejects %s wholesale rather than half-applying it', (_label, overrides) => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    expect(resolveTierRanges(overrides)).toBe(allTierRanges())
    expect(warn).toHaveBeenCalled()
    warn.mockRestore()
  })

  it('ignores non-numeric junk for a single tier without losing the rest', () => {
    const ranges = resolveTierRanges({ gold: 1400, diamond: Number.NaN })
    expect(ranges.find(r => r.key === 'gold')!.ratingStart).toBe(1400)
    expect(ranges.find(r => r.key === 'diamond')!.ratingStart).toBe(3000)
  })

  it('carries the override into promotion distance', () => {
    const ranges = resolveTierRanges({ gold: 1400 })
    // 1450 is Gold III; the next promotion is Gold II at 1400 + 850/3.
    const remaining = ratingToNextPromotion(1450, ranges)!
    expect(remaining).toBeGreaterThan(0)
    expect(tierFromRating(1450 + remaining, undefined, ranges).label).toBe('Gold II')
  })
})

describe('Challenger', () => {
  it('is awarded only inside the tier the contract names', () => {
    expect(tierFromRating(4300, 1).tier).toBe('challenger')
    expect(tierFromRating(4249, 1).tier).toBe('master')
  })

  it('tracks an overridden Grandmaster floor', () => {
    const ranges = resolveTierRanges({ grandmaster: 4000 })
    expect(tierFromRating(4100, 1, ranges).tier).toBe('challenger')
    expect(tierFromRating(4100, 1).tier).toBe('master')
  })
})

describe('describeTierFloorProblem', () => {
  it('says nothing about a valid ladder', () => {
    expect(describeTierFloorProblem({})).toBeNull()
    expect(describeTierFloorProblem({ gold: 1400 })).toBeNull()
  })

  it('names the tier and the number, so the panel can show the operator why', () => {
    expect(describeTierFloorProblem({ bronze: 50 })).toContain('must start at 0')
    expect(describeTierFloorProblem({ silver: 4000 })).toContain('silver')
    expect(describeTierFloorProblem({ master: 4250 })).toContain('grandmaster')
  })

  it('agrees with what resolveTierRanges actually does', () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    for (const overrides of [{}, { gold: 1400 }, { bronze: 50 }, { silver: 4000 }, { master: 4250 }]) {
      const rejected = resolveTierRanges(overrides) === allTierRanges()
        && Object.keys(overrides).length > 0
      expect(describeTierFloorProblem(overrides) !== null).toBe(rejected)
    }
    warn.mockRestore()
  })
})

describe('asTierFloor', () => {
  it('accepts the numeric string a JSON config column can hand back', () => {
    // The whole reason this is exported: the admin endpoint used to coerce
    // "1400" to 1400 while the ladder skipped it as non-numeric, so the panel
    // showed 1400 and the game kept using 1500 with nothing logged.
    expect(asTierFloor('1400')).toBe(1400)
    expect(asTierFloor(1400)).toBe(1400)
    expect(asTierFloor(1400.9)).toBe(1400)
  })

  it('has one answer for junk, shared by every reader', () => {
    for (const junk of [null, undefined, '', '  ', 'high', {}, [], Number.NaN, Infinity]) {
      expect(asTierFloor(junk)).toBeNull()
    }
  })

  it('clamps below zero rather than inventing a negative tier floor', () => {
    expect(asTierFloor(-50)).toBe(0)
  })

  it('is what resolveTierRanges actually uses', () => {
    expect(resolveTierRanges({ gold: '1400' as unknown as number })).toEqual(
      resolveTierRanges({ gold: 1400 }),
    )
  })
})
