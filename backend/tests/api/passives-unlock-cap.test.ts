/**
 * POST /api/passives/unlock — total-investment cap (2026-10-14).
 *
 * Prestige keeps the tree and the replay re-earns POINTS_PER_LEVEL per level,
 * so without a cap on points SUNK (not just points in hand) a P1 would hold
 * two trees. The cap is live-config `passives.max_passive_points`.
 */
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const { mockGetAuthUser, mockRateLimit, prismaMock, mockRecalc, mockGetPassivesConfig } = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  prismaMock: { $transaction: vi.fn() },
  mockRecalc: vi.fn(),
  mockGetPassivesConfig: vi.fn(),
}))

vi.mock('@/lib/auth', () => ({ getAuthUser: mockGetAuthUser }))
vi.mock('@/lib/prisma', () => ({ prisma: prismaMock }))
vi.mock('@/lib/rate-limit', () => ({ rateLimit: mockRateLimit }))
vi.mock('@/lib/game/build-stats', () => ({ recalculateFullDerivedStats: mockRecalc }))
vi.mock('@/lib/cache', () => ({ cacheDelete: vi.fn() }))
vi.mock('@/lib/game/live-config', () => ({ getPassivesConfig: mockGetPassivesConfig }))

import { POST } from '@/app/api/passives/unlock/route'
import { spentPassivePoints } from '@/lib/game/passives'

function makeTx(opts: { available: number; invested: { currentRank: number; node: { cost: number } }[] }) {
  const tx = {
    character: {
      findUnique: vi.fn(async () => ({ userId: 'user-1', class: 'warrior', passivePointsAvailable: opts.available })),
      update: vi.fn(async () => ({})),
    },
    passiveNode: { findUnique: vi.fn(async () => ({ id: 'node-x', isActive: true, classRestriction: null, cost: 1, isStartNode: true })) },
    characterPassive: {
      findUnique: vi.fn(async () => null),
      findMany: vi.fn(async ({ select }: { select: Record<string, unknown> }) =>
        select.currentRank ? opts.invested : opts.invested.map(() => ({ nodeId: 'other' })),
      ),
      create: vi.fn(async () => ({})),
      update: vi.fn(async () => ({})),
    },
    passiveConnection: { findMany: vi.fn(async () => []) },
  }
  prismaMock.$transaction.mockImplementation(async (fn: (t: typeof tx) => Promise<unknown>) => fn(tx))
  return tx
}

function unlock() {
  return POST(
    makeNextRequest('http://localhost/api/passives/unlock', {
      method: 'POST',
      body: JSON.stringify({ character_id: 'char-1', node_id: 'node-x', rank: 1 }),
    }),
  )
}

describe('spentPassivePoints', () => {
  it('sums the paid rank schedule, like /passives/respec refunds', () => {
    expect(spentPassivePoints([])).toBe(0)
    expect(spentPassivePoints([{ currentRank: 1, node: { cost: 6 } }])).toBe(1)
    expect(spentPassivePoints([{ currentRank: 3, node: { cost: 6 } }])).toBe(6)
    expect(spentPassivePoints([{ currentRank: 1, node: { cost: 3 } }, { currentRank: 2, node: { cost: 6 } }])).toBe(6)
    // ranks beyond the schedule are clamped, not extrapolated
    expect(spentPassivePoints([{ currentRank: 5, node: { cost: 3 } }])).toBe(3)
  })
})

describe('POST /api/passives/unlock total cap', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
    mockRecalc.mockResolvedValue({})
    mockGetPassivesConfig.mockResolvedValue({ MAX_PASSIVE_POINTS: 50 })
  })

  it('refuses the unlock that would exceed MAX_PASSIVE_POINTS even with points in hand', async () => {
    const invested = Array.from({ length: 50 }, () => ({ currentRank: 1, node: { cost: 1 } }))
    const tx = makeTx({ available: 49, invested }) // prestiged replay: tree full, pocket full
    const response = await unlock()
    expect(response.status).toBe(400)
    await expect(response.json()).resolves.toMatchObject({ error: expect.stringContaining('fully invested') })
    expect(tx.characterPassive.create).not.toHaveBeenCalled()
    expect(tx.character.update).not.toHaveBeenCalled()
  })

  it('allows the unlock that lands exactly on the cap', async () => {
    const invested = Array.from({ length: 49 }, () => ({ currentRank: 1, node: { cost: 1 } }))
    const tx = makeTx({ available: 10, invested })
    const response = await unlock()
    expect(response.status).toBe(200)
    expect(tx.characterPassive.create).toHaveBeenCalledTimes(1)
  })

  it('still refuses on empty pockets first', async () => {
    const tx = makeTx({ available: 0, invested: [] })
    const response = await unlock()
    expect(response.status).toBe(400)
    await expect(response.json()).resolves.toMatchObject({ error: 'Not enough passive points' })
    expect(tx.characterPassive.findMany).not.toHaveBeenCalled()
  })
})
