import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthAdmin,
  mockForbiddenResponse,
  mockInvalidateGameConfigCache,
  prismaMock,
  transactionMock,
} = vi.hoisted(() => ({
  mockGetAuthAdmin: vi.fn(),
  mockForbiddenResponse: vi.fn(() => new Response('forbidden', { status: 403 })),
  mockInvalidateGameConfigCache: vi.fn(),
  prismaMock: {
    gameConfig: {
      findMany: vi.fn(),
      upsert: vi.fn(),
      delete: vi.fn(),
    },
    adminLog: {
      create: vi.fn(),
    },
    $transaction: vi.fn(),
  },
  transactionMock: {
    gameConfig: {
      findMany: vi.fn(),
      create: vi.fn(),
      upsert: vi.fn(),
    },
  },
}))

vi.mock('@/lib/auth-admin', () => ({
  getAuthAdmin: mockGetAuthAdmin,
  forbiddenResponse: mockForbiddenResponse,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

vi.mock('@/lib/game/config', () => ({
  invalidateGameConfigCache: mockInvalidateGameConfigCache,
}))

import { DELETE, POST, PUT } from '@/app/api/admin/config/route'

describe('admin config route', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    mockGetAuthAdmin.mockResolvedValue({ id: 'admin-1' })
    mockInvalidateGameConfigCache.mockResolvedValue(undefined)
    prismaMock.adminLog.create.mockResolvedValue({ id: 'log-1' })
    prismaMock.gameConfig.upsert.mockResolvedValue({
      key: 'consumable.price.health_potion_small',
      value: 190,
      category: 'general',
      description: null,
    })
    prismaMock.gameConfig.delete.mockResolvedValue({ key: 'consumable.price.health_potion_small' })
    transactionMock.gameConfig.findMany.mockResolvedValue([{ key: 'stamina.max' }])
    transactionMock.gameConfig.create.mockImplementation(async ({ data }) => data)
    transactionMock.gameConfig.upsert.mockImplementation(async ({ create }) => create)
    prismaMock.$transaction.mockImplementation(async (callback: (tx: typeof transactionMock) => Promise<unknown>) =>
      callback(transactionMock)
    )
  })

  it('updates a single config key and invalidates game config caches', async () => {
    const response = await PUT(
      makeNextRequest('http://localhost/api/admin/config', {
        method: 'PUT',
        body: JSON.stringify({
          key: 'consumable.price.health_potion_small',
          value: 190,
          category: 'consumable_prices',
          description: 'Small health potion live price',
        }),
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      config: {
        key: 'consumable.price.health_potion_small',
        value: 190,
      },
    })
    expect(prismaMock.gameConfig.upsert).toHaveBeenCalledWith({
      where: { key: 'consumable.price.health_potion_small' },
      update: {
        value: 190,
        category: 'consumable_prices',
        description: 'Small health potion live price',
      },
      create: {
        key: 'consumable.price.health_potion_small',
        value: 190,
        category: 'consumable_prices',
        description: 'Small health potion live price',
      },
    })
    expect(mockInvalidateGameConfigCache).toHaveBeenCalledWith([
      'consumable.price.health_potion_small',
    ])
  })

  it('batch seeds only missing keys when skipExisting is enabled', async () => {
    const response = await POST(
      makeNextRequest('http://localhost/api/admin/config', {
        method: 'POST',
        body: JSON.stringify({
          skipExisting: true,
          updates: [
            { key: 'stamina.max', value: 120, category: 'stamina' },
            { key: 'consumable.price.health_potion_small', value: 190, category: 'consumable_prices' },
          ],
        }),
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      created: 1,
      skipped: 1,
      total: 2,
      configs: [
        expect.objectContaining({
          key: 'consumable.price.health_potion_small',
          value: 190,
          category: 'consumable_prices',
        }),
      ],
    })
    expect(transactionMock.gameConfig.findMany).toHaveBeenCalledWith({
      where: { key: { in: ['stamina.max', 'consumable.price.health_potion_small'] } },
      select: { key: true },
    })
    expect(transactionMock.gameConfig.create).toHaveBeenCalledTimes(1)
    expect(mockInvalidateGameConfigCache).toHaveBeenCalledWith([
      'stamina.max',
      'consumable.price.health_potion_small',
    ])
  })
  // ---------------------------------------------------------------------------
  // PvP ladder floors (2026-09-15)
  //
  // `pvp_ranks.*` used to be inert: the balance panel wrote the rows and no
  // gameplay code read them. They drive the live ladder now, and an invalid set
  // is rejected wholesale by `resolveTierRanges` — which from the panel looks
  // exactly like a save that worked and changed nothing. So the route has to
  // refuse it, with a reason.
  // ---------------------------------------------------------------------------
  describe('pvp_ranks ladder validation', () => {
    beforeEach(() => {
      // No stored overrides — the frozen ladder is the baseline.
      prismaMock.gameConfig.findMany.mockResolvedValue([])
    })

    it('accepts a floor that keeps the ladder ascending', async () => {
      const response = await POST(
        makeNextRequest('http://localhost/api/admin/config', {
          method: 'POST',
          body: JSON.stringify({ updates: [{ key: 'pvp_ranks.gold', value: 1400 }] }),
        }),
      )

      expect(response.status).toBe(200)
      expect(prismaMock.$transaction).toHaveBeenCalled()
    })

    it('refuses a floor that overtakes the tier above it, and writes nothing', async () => {
      const response = await POST(
        makeNextRequest('http://localhost/api/admin/config', {
          method: 'POST',
          body: JSON.stringify({ updates: [{ key: 'pvp_ranks.silver', value: 4000 }] }),
        }),
      )

      expect(response.status).toBe(400)
      await expect(response.json()).resolves.toMatchObject({
        error: expect.stringContaining('Invalid PvP ladder'),
      })
      expect(prismaMock.$transaction).not.toHaveBeenCalled()
      expect(mockInvalidateGameConfigCache).not.toHaveBeenCalled()
    })

    it('refuses two tiers sharing a floor', async () => {
      const response = await POST(
        makeNextRequest('http://localhost/api/admin/config', {
          method: 'POST',
          body: JSON.stringify({ updates: [{ key: 'pvp_ranks.master', value: 4250 }] }),
        }),
      )

      expect(response.status).toBe(400)
      expect(prismaMock.$transaction).not.toHaveBeenCalled()
    })

    it('refuses lifting the bottom tier off zero', async () => {
      const response = await PUT(
        makeNextRequest('http://localhost/api/admin/config', {
          method: 'PUT',
          body: JSON.stringify({ key: 'pvp_ranks.bronze', value: 50 }),
        }),
      )

      expect(response.status).toBe(400)
      expect(prismaMock.gameConfig.upsert).not.toHaveBeenCalled()
    })

    it('validates against stored floors, not just the frozen ones', async () => {
      // Gold was already moved down to 1400 in an earlier save.
      prismaMock.gameConfig.findMany.mockResolvedValue([
        { key: 'pvp_ranks.gold', value: 1400 },
      ])

      // 1450 is fine against the frozen ladder (Gold 1500) but not against the
      // ladder as it actually stands.
      const response = await POST(
        makeNextRequest('http://localhost/api/admin/config', {
          method: 'POST',
          body: JSON.stringify({ updates: [{ key: 'pvp_ranks.silver', value: 1450 }] }),
        }),
      )

      expect(response.status).toBe(400)
      expect(prismaMock.$transaction).not.toHaveBeenCalled()
    })

    it('judges the whole batch, not each edit in isolation', async () => {
      // Silver 1600 alone would overtake Gold; moving Gold up in the same save
      // keeps the ladder valid.
      const response = await POST(
        makeNextRequest('http://localhost/api/admin/config', {
          method: 'POST',
          body: JSON.stringify({
            updates: [
              { key: 'pvp_ranks.silver', value: 1600 },
              { key: 'pvp_ranks.gold', value: 1900 },
            ],
          }),
        }),
      )

      expect(response.status).toBe(200)
    })

    it('refuses a non-numeric floor', async () => {
      const response = await POST(
        makeNextRequest('http://localhost/api/admin/config', {
          method: 'POST',
          body: JSON.stringify({ updates: [{ key: 'pvp_ranks.gold', value: 'high' }] }),
        }),
      )

      expect(response.status).toBe(400)
      expect(prismaMock.$transaction).not.toHaveBeenCalled()
    })

    it('leaves saves that touch no tier floor alone', async () => {
      const response = await POST(
        makeNextRequest('http://localhost/api/admin/config', {
          method: 'POST',
          body: JSON.stringify({ updates: [{ key: 'stamina.max', value: 200 }] }),
        }),
      )

      expect(response.status).toBe(200)
      expect(prismaMock.gameConfig.findMany).not.toHaveBeenCalled()
    })
    it('stores a numeric string as a number, so the ladder does not skip it', async () => {
      const response = await POST(
        makeNextRequest('http://localhost/api/admin/config', {
          method: 'POST',
          body: JSON.stringify({ updates: [{ key: 'pvp_ranks.gold', value: '1400' }] }),
        }),
      )

      expect(response.status).toBe(200)
      // The config column is JSON: stored as the string "1400" this validates
      // as 1400 here and is then ignored by `applyTierFloors`, leaving the
      // panel showing 1400 while the game still uses 1500.
      expect(transactionMock.gameConfig.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          create: expect.objectContaining({ key: 'pvp_ranks.gold', value: 1400 }),
        }),
      )
    })

    it('refuses a delete that would leave the remaining floors out of order', async () => {
      // Silver was pushed above Gold's frozen floor. Deleting the Gold override
      // snaps Gold back to 1500 — below Silver.
      prismaMock.gameConfig.findMany.mockResolvedValue([
        { key: 'pvp_ranks.silver', value: 1600 },
        { key: 'pvp_ranks.gold', value: 1900 },
      ])

      const response = await DELETE(
        makeNextRequest('http://localhost/api/admin/config?key=pvp_ranks.gold', {
          method: 'DELETE',
        }),
      )

      expect(response.status).toBe(400)
      expect(prismaMock.gameConfig.delete).not.toHaveBeenCalled()
    })

    it('allows a delete that leaves a valid ladder', async () => {
      prismaMock.gameConfig.findMany.mockResolvedValue([
        { key: 'pvp_ranks.gold', value: 1400 },
      ])

      const response = await DELETE(
        makeNextRequest('http://localhost/api/admin/config?key=pvp_ranks.gold', {
          method: 'DELETE',
        }),
      )

      expect(response.status).toBe(200)
      expect(prismaMock.gameConfig.delete).toHaveBeenCalledWith({ where: { key: 'pvp_ranks.gold' } })
    })

    it('leaves deletes of other keys alone', async () => {
      const response = await DELETE(
        makeNextRequest('http://localhost/api/admin/config?key=stamina.max', {
          method: 'DELETE',
        }),
      )

      expect(response.status).toBe(200)
      expect(prismaMock.gameConfig.findMany).not.toHaveBeenCalled()
    })
  })
})
