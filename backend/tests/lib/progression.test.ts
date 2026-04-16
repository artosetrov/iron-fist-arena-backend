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

import { applyPrestigeBonus, checkLevelUp, xpForLevel } from '../../src/lib/game/progression'

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
      currentXp: xpForLevel(2) + xpForLevel(3) + 5,
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

  it('applies prestige stat bonus multiplicatively from config', async () => {
    await expect(applyPrestigeBonus(10, 2)).resolves.toBe(12)
  })
})
