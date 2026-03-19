import { beforeEach, describe, expect, it, vi } from 'vitest'

const { mockGetEloConfig } = vi.hoisted(() => ({
  mockGetEloConfig: vi.fn(),
}))

vi.mock('@/lib/game/live-config', () => ({
  getEloConfig: mockGetEloConfig,
}))

import { calculateElo, getKFactor } from '@/lib/game/elo'

describe('calculateElo', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetEloConfig.mockResolvedValue({
      K_DEFAULT: 32,
      K_CALIBRATION: 48,
      CALIBRATION_GAMES: 30,
      MIN_RATING: 0,
    })
  })

  it('equal rating players: winner gains ~16, loser loses ~16', async () => {
    // Both at 1000
    const result = await calculateElo(1000, 1000)

    // Expected: 0.5, so winner gets 32 * (1 - 0.5) = 16
    // Loser gets 32 * (0 - 0.5) = -16
    expect(result.newWinner).toBe(1016)
    expect(result.newLoser).toBe(984)
  })

  it('higher rated player beats lower: smaller gain', async () => {
    // Winner at 1200, Loser at 800
    const result = await calculateElo(1200, 800)

    // Expected for winner: 1 / (1 + 10^((800-1200)/400)) ≈ 0.909
    // Expected for loser: 1 / (1 + 10^((1200-800)/400)) ≈ 0.091
    // Winner: 1200 + 32 * (1 - 0.909) ≈ 1200 + 3 = 1203
    // Loser: 800 + 32 * (0 - 0.091) ≈ 800 - 3 = 797
    expect(result.newWinner).toBe(1203)
    expect(result.newLoser).toBe(797)
    // Higher rated player gains ~3 points (less than 16 for equal players)
    expect(result.newWinner - 1200).toBeLessThan(16)
    // Lower rated player loses more
    expect(800 - result.newLoser).toBeLessThan(16)
  })

  it('lower rated player beats higher: bigger gain', async () => {
    // Winner at 800, Loser at 1200
    const result = await calculateElo(800, 1200)

    // Expected for winner: 1 / (1 + 10^((1200-800)/400)) ≈ 0.091
    // Expected for loser: 1 / (1 + 10^((800-1200)/400)) ≈ 0.909
    // Winner: 800 + 32 * (1 - 0.091) ≈ 800 + 29 = 829
    // Loser: 1200 + 32 * (0 - 0.909) ≈ 1200 - 29 = 1171
    expect(result.newWinner).toBeGreaterThan(824) // More than 16 point gain
    expect(result.newLoser).toBeLessThan(1200 - 16) // More than 16 point loss
  })

  it('rating never goes below MIN_RATING', async () => {
    // Loser at 0, should not go negative
    const result = await calculateElo(1000, 0)

    expect(result.newLoser).toBeGreaterThanOrEqual(0)
  })

  it('accepts custom K-factor', async () => {
    const result = await calculateElo(1000, 1000, 48)

    // With K=48 and equal ratings: 48 * (1 - 0.5) = 24
    expect(result.newWinner).toBe(1024)
    expect(result.newLoser).toBe(976)
  })

  it('uses K_DEFAULT from config by default', async () => {
    const result = await calculateElo(1000, 1000)

    // Should use K_DEFAULT = 32
    expect(result.newWinner).toBe(1016)
    expect(result.newLoser).toBe(984)
    expect(mockGetEloConfig).toHaveBeenCalled()
  })

  it('rounds result to nearest integer', async () => {
    // Case that produces non-integer intermediate result
    const result = await calculateElo(1050, 950)

    expect(Number.isInteger(result.newWinner)).toBe(true)
    expect(Number.isInteger(result.newLoser)).toBe(true)
  })

  it('ELO is zero-sum (total rating unchanged)', async () => {
    const result = await calculateElo(1000, 1000)

    const ratingChange = (result.newWinner - 1000) + (result.newLoser - 1000)
    expect(ratingChange).toBe(0) // Zero-sum
  })
})

describe('getKFactor', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetEloConfig.mockResolvedValue({
      K_DEFAULT: 32,
      K_CALIBRATION: 48,
      CALIBRATION_GAMES: 30,
      MIN_RATING: 0,
    })
  })

  it('returns K_CALIBRATION during calibration phase', async () => {
    const kFactor = await getKFactor(0)
    expect(kFactor).toBe(48)
  })

  it('returns K_CALIBRATION at calibration threshold - 1', async () => {
    const kFactor = await getKFactor(29)
    expect(kFactor).toBe(48)
  })

  it('returns K_DEFAULT after calibration phase', async () => {
    const kFactor = await getKFactor(30)
    expect(kFactor).toBe(32)
  })

  it('returns K_DEFAULT well after calibration phase', async () => {
    const kFactor = await getKFactor(100)
    expect(kFactor).toBe(32)
  })

  it('uses config CALIBRATION_GAMES threshold', async () => {
    mockGetEloConfig.mockResolvedValue({
      K_DEFAULT: 32,
      K_CALIBRATION: 48,
      CALIBRATION_GAMES: 50,
      MIN_RATING: 0,
    })

    const kFactorBefore = await getKFactor(49)
    const kFactorAfter = await getKFactor(50)

    expect(kFactorBefore).toBe(48)
    expect(kFactorAfter).toBe(32)
  })
})
