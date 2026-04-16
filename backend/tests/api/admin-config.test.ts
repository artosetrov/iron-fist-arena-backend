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

import { POST, PUT } from '@/app/api/admin/config/route'

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
})
