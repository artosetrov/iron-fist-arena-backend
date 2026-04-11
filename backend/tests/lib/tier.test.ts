import { describe, it, expect } from 'vitest'
import {
  tierFromRating,
  divisionFromRating,
  globalTierIndex,
  minRatingForTier,
  ratingToNextPromotion,
  allTierRanges,
  STARTING_RATING,
  CHALLENGER_RANK_CUTOFF,
  type TierKey,
} from '../../src/lib/game/tier'

describe('tier.ts — W3.D5 Variant A (8 tiers × 3 divisions + Master/GM/Challenger)', () => {
  describe('tierFromRating — base tier detection', () => {
    it('rating 0 → Bronze III', () => {
      const t = tierFromRating(0)
      expect(t.tier).toBe('bronze')
      expect(t.division).toBe('III')
      expect(t.label).toBe('Bronze III')
    })

    it('rating 749 → Bronze I (just below Silver)', () => {
      const t = tierFromRating(749)
      expect(t.tier).toBe('bronze')
      expect(t.division).toBe('I')
    })

    it('rating 750 → Silver III (first in Silver)', () => {
      const t = tierFromRating(750)
      expect(t.tier).toBe('silver')
      expect(t.division).toBe('III')
      expect(t.label).toBe('Silver III')
    })

    it('STARTING_RATING (1000) → Silver II', () => {
      const t = tierFromRating(STARTING_RATING)
      expect(t.tier).toBe('silver')
      expect(t.division).toBe('II')
      expect(t.label).toBe('Silver II')
    })

    it('rating 1499 → Silver I (just below Gold)', () => {
      const t = tierFromRating(1499)
      expect(t.tier).toBe('silver')
      expect(t.division).toBe('I')
    })

    it('rating 1500 → Gold III', () => {
      const t = tierFromRating(1500)
      expect(t.tier).toBe('gold')
      expect(t.division).toBe('III')
    })

    it('rating 2249 → Gold I', () => {
      const t = tierFromRating(2249)
      expect(t.tier).toBe('gold')
      expect(t.division).toBe('I')
    })

    it('rating 2250 → Platinum III', () => {
      const t = tierFromRating(2250)
      expect(t.tier).toBe('platinum')
      expect(t.division).toBe('III')
    })

    it('rating 2999 → Platinum I', () => {
      const t = tierFromRating(2999)
      expect(t.tier).toBe('platinum')
      expect(t.division).toBe('I')
    })

    it('rating 3000 → Diamond III', () => {
      const t = tierFromRating(3000)
      expect(t.tier).toBe('diamond')
      expect(t.division).toBe('III')
    })

    it('rating 3749 → Diamond I', () => {
      const t = tierFromRating(3749)
      expect(t.tier).toBe('diamond')
      expect(t.division).toBe('I')
    })

    it('rating 3750 → Master (no division)', () => {
      const t = tierFromRating(3750)
      expect(t.tier).toBe('master')
      expect(t.division).toBeNull()
      expect(t.label).toBe('Master')
    })

    it('rating 4249 → Master (still)', () => {
      const t = tierFromRating(4249)
      expect(t.tier).toBe('master')
    })

    it('rating 4250 → Grandmaster', () => {
      const t = tierFromRating(4250)
      expect(t.tier).toBe('grandmaster')
      expect(t.division).toBeNull()
      expect(t.label).toBe('Grandmaster')
    })

    it('extremely high rating (99999) stays in Grandmaster (no Challenger without leaderboard rank)', () => {
      const t = tierFromRating(99999)
      expect(t.tier).toBe('grandmaster')
    })

    it('negative rating clamped to Bronze III', () => {
      const t = tierFromRating(-500)
      expect(t.tier).toBe('bronze')
      expect(t.division).toBe('III')
    })
  })

  describe('tierFromRating — Challenger promotion', () => {
    it('rating 4250 + leaderboardRank=1 → Challenger', () => {
      const t = tierFromRating(4250, 1)
      expect(t.tier).toBe('challenger')
      expect(t.division).toBeNull()
      expect(t.label).toBe('Challenger')
    })

    it('rating 4250 + leaderboardRank=100 → Challenger (inclusive cutoff)', () => {
      const t = tierFromRating(4250, CHALLENGER_RANK_CUTOFF)
      expect(t.tier).toBe('challenger')
    })

    it('rating 4250 + leaderboardRank=101 → Grandmaster (cutoff exceeded)', () => {
      const t = tierFromRating(4250, CHALLENGER_RANK_CUTOFF + 1)
      expect(t.tier).toBe('grandmaster')
    })

    it('rating 3000 + leaderboardRank=1 → Diamond III (not high enough for Challenger)', () => {
      const t = tierFromRating(3000, 1)
      expect(t.tier).toBe('diamond')
      expect(t.division).toBe('III')
    })

    it('rating 3749 + leaderboardRank=1 → Diamond I (Master rating floor not reached)', () => {
      const t = tierFromRating(3749, 1)
      expect(t.tier).toBe('diamond')
    })

    it('rating 3800 (Master) + leaderboardRank=1 → Master (not Grandmaster floor)', () => {
      // Challenger requires GM rating floor. Master top-N does NOT promote to Challenger.
      const t = tierFromRating(3800, 1)
      expect(t.tier).toBe('master')
    })

    it('leaderboardRank=0 does not promote (invalid rank)', () => {
      const t = tierFromRating(4250, 0)
      expect(t.tier).toBe('grandmaster')
    })
  })

  describe('divisionFromRating — thin wrapper', () => {
    it('Bronze III = "III"', () => expect(divisionFromRating(0)).toBe('III'))
    it('Silver II = "II"', () => expect(divisionFromRating(1000)).toBe('II'))
    it('Master = null', () => expect(divisionFromRating(3800)).toBeNull())
  })

  describe('globalTierIndex — strictly monotonic', () => {
    it('Bronze III = 0', () => expect(globalTierIndex('bronze', 'III')).toBe(0))
    it('Bronze I = 2', () => expect(globalTierIndex('bronze', 'I')).toBe(2))
    it('Silver III = 3', () => expect(globalTierIndex('silver', 'III')).toBe(3))
    it('Diamond I = 14', () => expect(globalTierIndex('diamond', 'I')).toBe(14))
    it('Master = 15', () => expect(globalTierIndex('master', null)).toBe(15))
    it('Grandmaster = 16', () => expect(globalTierIndex('grandmaster', null)).toBe(16))
    it('Challenger = 17', () => expect(globalTierIndex('challenger', null)).toBe(17))

    it('strictly monotonic across the full ladder', () => {
      const samples: number[] = []
      for (const rating of [0, 250, 500, 750, 1000, 1250, 1500, 1750, 2000, 2250, 2500, 2750, 3000, 3250, 3500, 3750, 4250]) {
        samples.push(tierFromRating(rating).index)
      }
      for (let i = 1; i < samples.length; i++) {
        expect(samples[i]).toBeGreaterThan(samples[i - 1])
      }
    })
  })

  describe('minRatingForTier', () => {
    const expectations: Array<[TierKey, number]> = [
      ['bronze',      0],
      ['silver',      750],
      ['gold',        1500],
      ['platinum',    2250],
      ['diamond',     3000],
      ['master',      3750],
      ['grandmaster', 4250],
      ['challenger',  4250], // same as GM — Challenger is rank-based not rating-based
    ]
    for (const [tier, min] of expectations) {
      it(`${tier} floor = ${min}`, () => expect(minRatingForTier(tier)).toBe(min))
    }
  })

  describe('ratingToNextPromotion', () => {
    it('Silver II at 1000 → 250 more for Silver I', () => {
      // Silver range 750-1499, divisions width = 250, Silver III 750-999, Silver II 1000-1249, Silver I 1250-1499
      expect(ratingToNextPromotion(1000)).toBe(250)
    })

    it('Silver I at 1250 → 250 more for Gold III', () => {
      expect(ratingToNextPromotion(1250)).toBe(250)
    })

    it('Bronze III at 0 → 250 more for Bronze II', () => {
      expect(ratingToNextPromotion(0)).toBe(250)
    })

    it('Master at 3750 → 500 more for Grandmaster', () => {
      // Master range 3750-4249 (500 wide), no divisions → promotion == full tier width
      expect(ratingToNextPromotion(3750)).toBe(500)
    })

    it('Grandmaster at 4500 → null (terminal)', () => {
      expect(ratingToNextPromotion(4500)).toBeNull()
    })
  })

  describe('allTierRanges', () => {
    it('returns 7 base tier ranges (Bronze → Grandmaster)', () => {
      // Challenger is not a range — it's computed from leaderboard rank.
      expect(allTierRanges()).toHaveLength(7)
    })

    it('ranges are contiguous (no gap, no overlap)', () => {
      const ranges = allTierRanges()
      for (let i = 1; i < ranges.length; i++) {
        expect(ranges[i].ratingStart).toBe(ranges[i - 1].ratingEnd)
      }
    })

    it('every ranged tier with divisions has width divisible by division count', () => {
      for (const r of allTierRanges()) {
        if (r.divisions > 0 && Number.isFinite(r.ratingEnd)) {
          const width = r.ratingEnd - r.ratingStart
          expect(width % r.divisions).toBe(0)
        }
      }
    })
  })

  describe('regression guards (W3.D5)', () => {
    it('starting rating 1000 never lands in Bronze', () => {
      const t = tierFromRating(1000)
      expect(t.tier).not.toBe('bronze')
    })

    it('starting rating 1000 never lands in Gold+ (would skip Silver psychologically)', () => {
      const t = tierFromRating(1000)
      expect(t.tier).toBe('silver')
    })

    it('Challenger promotion cannot happen below GM rating floor', () => {
      for (const rating of [0, 1000, 2000, 3000, 3500, 3749, 4000, 4249]) {
        expect(tierFromRating(rating, 1).tier).not.toBe('challenger')
      }
    })

    it('division widths inside Diamond tier = 250 each', () => {
      expect(tierFromRating(3000).label).toBe('Diamond III')
      expect(tierFromRating(3249).label).toBe('Diamond III')
      expect(tierFromRating(3250).label).toBe('Diamond II')
      expect(tierFromRating(3499).label).toBe('Diamond II')
      expect(tierFromRating(3500).label).toBe('Diamond I')
      expect(tierFromRating(3749).label).toBe('Diamond I')
    })
  })
})
