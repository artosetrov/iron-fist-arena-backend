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
import { XP_CURVE_SCALE } from '../../src/lib/game/balance'

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

  it('per-level requirement is the delta of the cumulative curve, scaled once', () => {
    expect(xpToNextLevel(1)).toBe(160 * XP_CURVE_SCALE)
    expect(xpToNextLevel(10)).toBe(520 * XP_CURVE_SCALE)
    expect(xpToNextLevel(49)).toBe(2080 * XP_CURVE_SCALE)
    let total = 0
    for (let l = 1; l < 50; l++) total += xpToNextLevel(l)
    expect(total).toBe(xpForLevel(50) - xpForLevel(1))
    // The ×18 bug fed the cumulative value into the per-level loop (~986k).
    // The scaled design curve is 54 880 × scale; anything near 986k is that
    // bug coming back, whatever the scale.
    expect(total).toBe(54_880 * XP_CURVE_SCALE)
    expect(total).toBeLessThan(900_000)
  })

  it('applies prestige stat bonus multiplicatively from config', async () => {
    await expect(applyPrestigeBonus(10, 2)).resolves.toBe(12)
  })
})
