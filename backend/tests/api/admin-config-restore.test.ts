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
    },
    configSnapshot: {
      create: vi.fn(),
    },
    adminLog: {
      create: vi.fn(),
    },
    $transaction: vi.fn(),
  },
  transactionMock: {
    gameConfig: {
      findMany: vi.fn(),
      deleteMany: vi.fn(),
      create: vi.fn(),
    },
    configSnapshot: {
      create: vi.fn(),
    },
    adminLog: {
      create: vi.fn(),
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

import { POST } from '@/app/api/admin/config/restore/route'

describe('admin config restore route', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    mockGetAuthAdmin.mockResolvedValue({ id: 'admin-1' })
    mockInvalidateGameConfigCache.mockResolvedValue(undefined)
    prismaMock.gameConfig.findMany.mockResolvedValue([
      { key: 'stamina.max' },
      { key: 'repair.base_cost' },
    ])
    transactionMock.gameConfig.findMany.mockResolvedValue([
      {
        key: 'stamina.max',
        value: 120,
        category: 'stamina',
        description: 'Maximum stamina capacity',
      },
      {
        key: 'repair.base_cost',
        value: 120,
        category: 'repair',
        description: 'Base repair cost',
      },
    ])
    transactionMock.configSnapshot.create.mockResolvedValue({ id: 'backup-1' })
    transactionMock.gameConfig.deleteMany.mockResolvedValue({ count: 2 })
    transactionMock.gameConfig.create.mockImplementation(async ({ data }) => data)
    transactionMock.adminLog.create.mockResolvedValue({ id: 'log-1' })
    prismaMock.$transaction.mockImplementation(
      async (callback: (tx: typeof transactionMock) => Promise<unknown>) => callback(transactionMock),
    )
  })

  it('restores a snapshot atomically and invalidates the union of old and restored keys', async () => {
    const response = await POST(
      makeNextRequest('http://localhost/api/admin/config/restore', {
        method: 'POST',
        body: JSON.stringify({
          snapshotId: 'snapshot-1',
          snapshotName: 'Pre-release tuning',
          configs: [
            {
              key: 'stamina.max',
              value: 100,
              category: 'stamina',
              description: 'Maximum stamina capacity',
            },
            {
              key: 'battle_pass.bp_xp_per_pvp',
              value: 25,
              category: 'battle_pass',
              description: 'Battle Pass XP earned per PvP match',
            },
          ],
        }),
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      success: true,
      restoredCount: 2,
      backupCreated: true,
      backupId: 'backup-1',
    })
    expect(transactionMock.gameConfig.deleteMany).toHaveBeenCalledTimes(1)
    expect(transactionMock.gameConfig.create).toHaveBeenNthCalledWith(1, {
      data: {
        key: 'stamina.max',
        value: 100,
        category: 'stamina',
        description: 'Maximum stamina capacity',
        updatedBy: 'admin-1',
      },
    })
    expect(transactionMock.gameConfig.create).toHaveBeenNthCalledWith(2, {
      data: {
        key: 'battle_pass.bp_xp_per_pvp',
        value: 25,
        category: 'battle_pass',
        description: 'Battle Pass XP earned per PvP match',
        updatedBy: 'admin-1',
      },
    })
    expect(mockInvalidateGameConfigCache).toHaveBeenCalledWith([
      'stamina.max',
      'repair.base_cost',
      'battle_pass.bp_xp_per_pvp',
    ])
  })

  it('rejects duplicate keys in the restore payload', async () => {
    const response = await POST(
      makeNextRequest('http://localhost/api/admin/config/restore', {
        method: 'POST',
        body: JSON.stringify({
          snapshotName: 'Broken snapshot',
          configs: [
            {
              key: 'stamina.max',
              value: 100,
              category: 'stamina',
              description: 'Maximum stamina capacity',
            },
            {
              key: 'stamina.max',
              value: 110,
              category: 'stamina',
              description: 'Duplicate key',
            },
          ],
        }),
      }),
    )

    expect(response.status).toBe(400)
    await expect(response.json()).resolves.toMatchObject({
      error: 'configs[] contains duplicate keys',
    })
  })
})
