/**
 * POST /api/prestige — prestige keeps the build (2026-10-14).
 *
 * Before: every unlocked passive was deleted and passive points zeroed, so a
 * L50 lost ~27% damage for +5% stats. Now the level resets and nothing else
 * is touched; the talent-tree cap lives in /passives/unlock.
 */
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const { mockGetAuthUser, mockRateLimit, prismaMock, mockRecalc, mockCheckPrestige, mockAchievements } = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  prismaMock: { $transaction: vi.fn(), character: { findUnique: vi.fn() } },
  mockRecalc: vi.fn(),
  mockCheckPrestige: vi.fn(),
  mockAchievements: vi.fn(),
}))

vi.mock('@/lib/auth', () => ({ getAuthUser: mockGetAuthUser }))
vi.mock('@/lib/prisma', () => ({ prisma: prismaMock }))
vi.mock('@/lib/rate-limit', () => ({ rateLimit: mockRateLimit }))
vi.mock('@/lib/game/progression', () => ({ checkPrestige: mockCheckPrestige }))
vi.mock('@/lib/game/live-config', () => ({
  getPrestigeConfig: vi.fn(async () => ({ MAX_LEVEL: 50, STAT_POINTS_PER_LEVEL: 3, STAT_BONUS_PER_PRESTIGE: 0.05 })),
}))
vi.mock('@/lib/game/equipment-stats', () => ({ recalculateDerivedStats: mockRecalc }))
vi.mock('@/lib/game/combat-loader', () => ({ invalidateSkillCache: vi.fn(), invalidatePassiveCache: vi.fn() }))
vi.mock('@/lib/game/achievements', () => ({ updateMultipleAchievements: mockAchievements }))

import { POST } from '@/app/api/prestige/route'

function makeTx() {
  const tx = {
    $queryRawUnsafe: vi.fn(async () => [{ id: 'char-1', user_id: 'user-1', level: 50, prestige_level: 0 }]),
    character: { update: vi.fn(async ({ data }: { data: unknown }) => ({ id: 'char-1', ...(data as object) })) },
    characterPassive: { deleteMany: vi.fn(async () => ({ count: 0 })) },
  }
  prismaMock.$transaction.mockImplementation(async (fn: (t: typeof tx) => Promise<unknown>) => fn(tx))
  return tx
}

describe('POST /api/prestige', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
    mockCheckPrestige.mockResolvedValue({ canPrestige: true, newPrestigeLevel: 1, statBonusPercent: 5 })
    mockRecalc.mockResolvedValue({})
  })

  it('resets level and XP, bumps prestige, and leaves the talent tree and points alone', async () => {
    const tx = makeTx()
    const response = await POST(
      makeNextRequest('http://localhost/api/prestige', { method: 'POST', body: JSON.stringify({ character_id: 'char-1' }) }),
    )
    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({ success: true, prestigeLevel: 1, statBonusPercent: 5 })

    expect(tx.characterPassive.deleteMany).not.toHaveBeenCalled()
    expect(tx.character.update).toHaveBeenCalledTimes(1)
    const { data } = tx.character.update.mock.calls[0][0] as { data: Record<string, unknown> }
    expect(data).toEqual({
      level: 1,
      currentXp: 0,
      prestigeLevel: 1,
      statPointsAvailable: { increment: 3 },
    })
    expect(data).not.toHaveProperty('passivePointsAvailable')
    expect(mockRecalc).toHaveBeenCalledWith('char-1', tx)
  })

  it('refuses below max level without touching the character', async () => {
    const tx = makeTx()
    mockCheckPrestige.mockResolvedValue({ canPrestige: false, newPrestigeLevel: 1, statBonusPercent: 5 })
    const response = await POST(
      makeNextRequest('http://localhost/api/prestige', { method: 'POST', body: JSON.stringify({ character_id: 'char-1' }) }),
    )
    expect(response.status).toBe(400)
    expect(tx.character.update).not.toHaveBeenCalled()
  })
})
