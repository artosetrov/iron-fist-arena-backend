/**
 * Milestone ladder shape (2026-10-14 balance batch). The ×3 XP curve made
 * the gaps between the eight majors (10…50) multi-day stretches with nothing
 * in them; minor milestones fill those so no gap exceeds 3 levels.
 */
import { describe, expect, it } from 'vitest'
import { MILESTONES } from '@/lib/game/milestones'

describe('MILESTONES ladder', () => {
  const levels = MILESTONES.map((m) => m.level)

  it('is strictly ascending with unique levels', () => {
    for (let i = 1; i < levels.length; i++) expect(levels[i]).toBeGreaterThan(levels[i - 1])
  })

  it('starts at 10, ends at 50 and never leaves a gap wider than 3 levels', () => {
    expect(levels[0]).toBe(10)
    expect(levels[levels.length - 1]).toBe(50)
    for (let i = 1; i < levels.length; i++) expect(levels[i] - levels[i - 1]).toBeLessThanOrEqual(3)
  })

  it('keeps the eight titled majors and gives minors no title', () => {
    const majors = MILESTONES.filter((m) => m.reward.title)
    expect(majors.map((m) => m.level)).toEqual([10, 15, 20, 25, 30, 35, 40, 50])
    const minors = MILESTONES.filter((m) => !m.reward.title)
    expect(minors.map((m) => m.level)).toEqual([12, 18, 22, 27, 32, 37, 42, 45, 47])
  })

  it('keeps the minor drip small relative to the majors (gold faucet guard)', () => {
    const sum = (ms: typeof MILESTONES, k: 'gold' | 'gems') => ms.reduce((s, m) => s + m.reward[k], 0)
    const majors = MILESTONES.filter((m) => m.reward.title)
    const minors = MILESTONES.filter((m) => !m.reward.title)
    expect(sum(majors, 'gold')).toBe(34_500)
    expect(sum(majors, 'gems')).toBe(520)
    expect(sum(minors, 'gold')).toBeLessThan(sum(majors, 'gold') * 0.5)
    expect(sum(minors, 'gems')).toBeLessThan(sum(majors, 'gems') * 0.5)
    // Every reward is a positive payout and a minor never out-pays the next major.
    for (let i = 0; i < MILESTONES.length; i++) {
      expect(MILESTONES[i].reward.gold).toBeGreaterThan(0)
      expect(MILESTONES[i].reward.gems).toBeGreaterThan(0)
      if (!MILESTONES[i].reward.title) {
        const nextMajor = MILESTONES.slice(i + 1).find((m) => m.reward.title)
        if (nextMajor) expect(MILESTONES[i].reward.gold).toBeLessThan(nextMajor.reward.gold)
      }
    }
  })
})
