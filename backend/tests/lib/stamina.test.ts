import { beforeEach, describe, expect, it, vi } from 'vitest'

const { mockGetStaminaConfig } = vi.hoisted(() => ({
  mockGetStaminaConfig: vi.fn(),
}))

vi.mock('@/lib/game/live-config', () => ({
  getStaminaConfig: mockGetStaminaConfig,
}))

import { calculateCurrentStamina } from '@/lib/game/stamina'

describe('calculateCurrentStamina', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetStaminaConfig.mockResolvedValue({
      REGEN_RATE: 1,
      REGEN_INTERVAL_MINUTES: 8,
      MAX: 120,
    })
  })

  it('returns same stamina if already at max', async () => {
    const result = await calculateCurrentStamina(120, 120, new Date())

    expect(result).toEqual({
      stamina: 120,
      updated: false,
    })
  })

  it('returns same stamina if not enough time elapsed', async () => {
    const now = new Date()
    const fifteenSecondsAgo = new Date(now.getTime() - 15 * 1000)

    const result = await calculateCurrentStamina(50, 120, fifteenSecondsAgo)

    expect(result).toEqual({
      stamina: 50,
      updated: false,
    })
  })

  it('regenerates correct amount after full regen interval', async () => {
    const now = new Date()
    // 8 minutes = 1 point (REGEN_INTERVAL_MINUTES = 8, REGEN_RATE = 1)
    const eightMinutesAgo = new Date(now.getTime() - 8 * 60 * 1000)

    const result = await calculateCurrentStamina(50, 120, eightMinutesAgo)

    expect(result).toEqual({
      stamina: 51,
      updated: true,
    })
  })

  it('regenerates multiple points after multiple intervals', async () => {
    const now = new Date()
    // 32 minutes = 4 intervals = 4 points
    const thirtyTwoMinutesAgo = new Date(now.getTime() - 32 * 60 * 1000)

    const result = await calculateCurrentStamina(50, 120, thirtyTwoMinutesAgo)

    expect(result).toEqual({
      stamina: 54,
      updated: true,
    })
  })

  it('caps stamina at maxStamina', async () => {
    const now = new Date()
    // 80 minutes = 10 intervals = 10 points, but capped at 120
    const eightyMinutesAgo = new Date(now.getTime() - 80 * 60 * 1000)

    const result = await calculateCurrentStamina(115, 120, eightyMinutesAgo)

    expect(result).toEqual({
      stamina: 120,
      updated: true,
    })
  })

  it('returns updated=false when partial interval not yet complete', async () => {
    const now = new Date()
    // 4 minutes = less than 1 full interval
    const fourMinutesAgo = new Date(now.getTime() - 4 * 60 * 1000)

    const result = await calculateCurrentStamina(50, 120, fourMinutesAgo)

    expect(result).toEqual({
      stamina: 50,
      updated: false,
    })
  })

  it('uses config values from live-config', async () => {
    mockGetStaminaConfig.mockResolvedValue({
      REGEN_RATE: 2,
      REGEN_INTERVAL_MINUTES: 4,
      MAX: 150,
    })

    const now = new Date()
    // 4 minutes with REGEN_INTERVAL_MINUTES = 4 = 1 interval * 2 rate = 2 points
    const fourMinutesAgo = new Date(now.getTime() - 4 * 60 * 1000)

    const result = await calculateCurrentStamina(50, 150, fourMinutesAgo)

    expect(result).toEqual({
      stamina: 52,
      updated: true,
    })
    expect(mockGetStaminaConfig).toHaveBeenCalled()
  })

  it('handles very old timestamps with many regenerations', async () => {
    const now = new Date()
    // 24 hours = 1440 minutes = 180 intervals (with 8 min per interval) = 180 points
    const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000)

    const result = await calculateCurrentStamina(0, 120, oneDayAgo)

    // Should cap at 120, not 180
    expect(result).toEqual({
      stamina: 120,
      updated: true,
    })
  })

  it('floors points (does not round) intermediate calculation', async () => {
    mockGetStaminaConfig.mockResolvedValue({
      REGEN_RATE: 1,
      REGEN_INTERVAL_MINUTES: 10,
      MAX: 120,
    })

    const now = new Date()
    // 15 minutes = 1.5 intervals → floor(1.5) = 1 interval = 1 point
    const fifteenMinutesAgo = new Date(now.getTime() - 15 * 60 * 1000)

    const result = await calculateCurrentStamina(50, 120, fifteenMinutesAgo)

    expect(result).toEqual({
      stamina: 51,
      updated: true,
    })
  })
})
