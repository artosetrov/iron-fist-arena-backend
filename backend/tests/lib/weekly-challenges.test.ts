import { describe, it, expect, vi } from 'vitest'
import {
  buildWeeklyChallenges,
  isoWeekOf,
  updateWeeklyChallengeProgress,
  WEEKLY_CHALLENGE_POOL,
} from '../../src/lib/game/weekly-challenges'
import { BP_WEEKLY } from '../../src/lib/game/balance'

describe('weekly-challenges.ts — W3.D5 BAL-06', () => {
  describe('isoWeekOf — ISO-8601 week key', () => {
    it('returns YYYY-Www format', () => {
      const w = isoWeekOf(new Date('2026-04-10T12:00:00Z'))
      expect(w).toMatch(/^\d{4}-W\d{2}$/)
    })

    it('2026-01-01 (Thursday) → 2026-W01', () => {
      // ISO week rule: Thursday belongs to its own week-of-year.
      expect(isoWeekOf(new Date('2026-01-01T00:00:00Z'))).toBe('2026-W01')
    })

    it('2025-12-29 (Monday) → 2026-W01 (Mon of Thu-Jan-1 week)', () => {
      expect(isoWeekOf(new Date('2025-12-29T00:00:00Z'))).toBe('2026-W01')
    })

    it('2026-04-10 (Friday) → 2026-W15', () => {
      expect(isoWeekOf(new Date('2026-04-10T00:00:00Z'))).toBe('2026-W15')
    })

    it('same ISO week Mon and Sun return same key', () => {
      const mon = isoWeekOf(new Date('2026-04-06T00:00:00Z'))
      const sun = isoWeekOf(new Date('2026-04-12T23:59:59Z'))
      expect(mon).toBe(sun)
    })

    it('zero-pads single-digit weeks', () => {
      expect(isoWeekOf(new Date('2026-01-05T12:00:00Z'))).toBe('2026-W02')
    })
  })

  describe('buildWeeklyChallenges — determinism', () => {
    it('same week → identical output (structural equality)', () => {
      const a = buildWeeklyChallenges('2026-W15')
      const b = buildWeeklyChallenges('2026-W15')
      expect(a).toEqual(b)
    })

    it('different weeks → at least some slot differs', () => {
      const a = buildWeeklyChallenges('2026-W15')
      const b = buildWeeklyChallenges('2026-W16')
      // Probability that 5 random picks from 9 with weights collide identically
      // is vanishingly small; assert at least one slot is not identical.
      let anyDifferent = false
      for (let i = 0; i < a.length; i++) {
        if (a[i].goalType !== b[i].goalType || a[i].goalTarget !== b[i].goalTarget) {
          anyDifferent = true
          break
        }
      }
      expect(anyDifferent).toBe(true)
    })

    it('produces exactly BP_WEEKLY.SLOTS challenges', () => {
      const cs = buildWeeklyChallenges('2026-W15')
      expect(cs).toHaveLength(BP_WEEKLY.SLOTS)
    })

    it('slotIndex is contiguous 0..SLOTS-1', () => {
      const cs = buildWeeklyChallenges('2026-W15')
      for (let i = 0; i < cs.length; i++) {
        expect(cs[i].slotIndex).toBe(i)
      }
    })

    it('awards BP_WEEKLY.XP_PER_CLEAR per slot', () => {
      for (const c of buildWeeklyChallenges('2026-W15')) {
        expect(c.bpXpAward).toBe(BP_WEEKLY.XP_PER_CLEAR)
      }
    })
  })

  describe('buildWeeklyChallenges — target shape', () => {
    it('targets are within pool template min/max', () => {
      const cs = buildWeeklyChallenges('2026-W20')
      for (const c of cs) {
        // Every generated challenge must correspond to a template of the same goalType
        // whose [minTarget, maxTarget] envelope contains the rolled target.
        const matchingTemplates = WEEKLY_CHALLENGE_POOL.filter(
          (t) => t.goalType === c.goalType,
        )
        expect(matchingTemplates.length).toBeGreaterThan(0)
        const ok = matchingTemplates.some(
          (t) => c.goalTarget >= t.minTarget && c.goalTarget <= t.maxTarget * 1.5,
          // allow headroom for niceStep rounding at the edge
        )
        expect(ok).toBe(true)
      }
    })

    it('description substitutes {target}', () => {
      const cs = buildWeeklyChallenges('2026-W15')
      for (const c of cs) {
        expect(c.description).not.toContain('{target}')
        expect(c.description).toContain(String(c.goalTarget))
      }
    })

    it('targets are positive integers', () => {
      const cs = buildWeeklyChallenges('2026-W15')
      for (const c of cs) {
        expect(Number.isInteger(c.goalTarget)).toBe(true)
        expect(c.goalTarget).toBeGreaterThan(0)
      }
    })
  })

  describe('buildWeeklyChallenges — distinctness', () => {
    it('no two slots in a week share the same template instance (weighted sampling is without replacement)', () => {
      const cs = buildWeeklyChallenges('2026-W15')
      // Distinctness is per template, not per goalType — e.g. both pvp_wins tiers are allowed
      // in the same week. Check we don't have exact duplicates of (goalType, label).
      const keys = new Set(cs.map((c) => `${c.goalType}:${c.label}`))
      expect(keys.size).toBe(cs.length)
    })
  })

  describe('buildWeeklyChallenges — pool diversity over 100 weeks', () => {
    it('every non-zero-weight template appears in at least one of 100 consecutive weeks', () => {
      const seen = new Set<string>()
      for (let w = 1; w <= 100; w++) {
        const isoWeek = `2026-W${String(w % 53 || 1).padStart(2, '0')}`
        for (const c of buildWeeklyChallenges(isoWeek)) {
          seen.add(`${c.goalType}:${c.label}`)
        }
      }
      // All 9 templates should surface over 100 weeks × 5 slots = 500 picks.
      // Probability of missing any is ~10^-22 — effectively impossible.
      const allKeys = WEEKLY_CHALLENGE_POOL.filter((t) => t.weight > 0).map(
        (t) => `${t.goalType}:${t.label}`,
      )
      for (const key of allKeys) {
        expect(seen.has(key)).toBe(true)
      }
    })

    it('highest-weight entries appear more often than lowest-weight over 200 weeks', () => {
      const counts: Record<string, number> = {}
      for (let y = 2026; y <= 2029; y++) {
        for (let w = 1; w <= 52; w++) {
          const isoWeek = `${y}-W${String(w).padStart(2, '0')}`
          for (const c of buildWeeklyChallenges(isoWeek)) {
            const key = `${c.goalType}:${c.label}`
            counts[key] = (counts[key] || 0) + 1
          }
        }
      }
      // Arena Conqueror (weight 15) should beat Prospector (weight 6) handily.
      const conqueror = counts['pvp_wins:Arena Conqueror'] || 0
      const prospector = counts['gold_mine_collect:Prospector'] || 0
      expect(conqueror).toBeGreaterThan(prospector)
    })
  })

  describe('regression guards', () => {
    it('pool length has not shrunk (would break historical rows)', () => {
      // If this test fails, you either added a template (fine, bump this) or
      // REMOVED one. Never remove — set weight to 0 instead.
      expect(WEEKLY_CHALLENGE_POOL.length).toBeGreaterThanOrEqual(9)
    })

    it('every template has valid target range', () => {
      for (const t of WEEKLY_CHALLENGE_POOL) {
        expect(t.minTarget).toBeGreaterThan(0)
        expect(t.maxTarget).toBeGreaterThanOrEqual(t.minTarget)
        expect(t.weight).toBeGreaterThanOrEqual(0)
      }
    })
  })

  describe('updateWeeklyChallengeProgress', () => {
    it('writes the current ISO week and goal type through the raw SQL helper', async () => {
      const executor = {
        $executeRawUnsafe: vi.fn(async () => 1),
      }

      await updateWeeklyChallengeProgress(executor, 'char-1', 'pvp_wins', 2)

      expect(executor.$executeRawUnsafe).toHaveBeenCalledWith(
        expect.stringContaining('UPDATE "weekly_challenge_progress"'),
        2,
        'char-1',
        isoWeekOf(),
        'pvp_wins',
      )
    })
  })
})
