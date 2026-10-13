import { beforeEach, describe, expect, it, vi } from 'vitest'

const {
  mockGetPrestigeConfig,
  mockGetPassivesConfig,
} = vi.hoisted(() => ({
  mockGetPrestigeConfig: vi.fn(),
  mockGetPassivesConfig: vi.fn(),
}))

vi.mock('../../src/lib/game/live-config', () => ({
  getPrestigeConfig: mockGetPrestigeConfig,
  getPassivesConfig: mockGetPassivesConfig,
}))

import { applyPrestigeBonus, checkLevelUp, xpForLevel, xpToNextLevel } from '../../src/lib/game/progression'

describe('progression.ts', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetPrestigeConfig.mockResolvedValue({
      MAX_LEVEL: 50,
      STAT_POINTS_PER_LEVEL: 3,
      STAT_BONUS_PER_PRESTIGE: 0.1,
    })
    mockGetPassivesConfig.mockResolvedValue({
      POINTS_PER_LEVEL: 1,
    })
  })

  it('handles multiple level-ups in a single XP dump', async () => {
    const result = await checkLevelUp({
      level: 1,
      currentXp: xpToNextLevel(1) + xpToNextLevel(2) + 5,
    })

    expect(result).toEqual({
      leveledUp: true,
      newLevel: 3,
      remainingXp: 5,
      statPointsAwarded: 6,
      passivePointsAwarded: 2,
      atMaxLevel: false,
    })
  })

  it('per-level requirement is the delta of the cumulative curve (L50 ≈ 55k total, not 986k)', () => {
    expect(xpToNextLevel(1)).toBe(160)
    expect(xpToNextLevel(10)).toBe(520)
    expect(xpToNextLevel(49)).toBe(2080)
    let total = 0
    for (let l = 1; l < 50; l++) total += xpToNextLevel(l)
    expect(total).toBe(xpForLevel(50) - xpForLevel(1))
    expect(total).toBeLessThan(60_000)
  })

  it('applies prestige stat bonus multiplicatively from config', async () => {
    await expect(applyPrestigeBonus(10, 2)).resolves.toBe(12)
  })
})
