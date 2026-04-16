import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  prismaMock: {
    iapTransaction: {
      findMany: vi.fn(),
    },
  },
}))

vi.mock('@/lib/auth', () => ({
  getAuthUser: mockGetAuthUser,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

import { POST as restorePurchasesPOST } from '@/app/api/iap/restore-purchases/route'
import { POST as restoreAliasPOST } from '@/app/api/iap/restore/route'

describe('POST /api/iap/restore-purchases', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    prismaMock.iapTransaction.findMany.mockResolvedValue([
      {
        id: 'iap-1',
        productId: 'gems_small',
        transactionId: 'tx-1',
        gemsAwarded: 100,
        createdAt: new Date('2026-04-15T10:00:00.000Z'),
        verifiedAt: new Date('2026-04-15T10:00:01.000Z'),
      },
    ])
  })

  it('returns 401 when unauthorized', async () => {
    mockGetAuthUser.mockResolvedValue(null)

    const response = await restorePurchasesPOST(
      makeNextRequest('http://localhost/api/iap/restore-purchases', {
        method: 'POST',
      }),
    )

    expect(response.status).toBe(401)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Unauthorized',
    })
  })

  it('returns verified purchase history from the canonical restore route', async () => {
    const response = await restorePurchasesPOST(
      makeNextRequest('http://localhost/api/iap/restore-purchases', {
        method: 'POST',
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      transactions: [
        {
          id: 'iap-1',
          productId: 'gems_small',
          transactionId: 'tx-1',
          gemsAwarded: 100,
        },
      ],
    })
    expect(prismaMock.iapTransaction.findMany).toHaveBeenCalledWith({
      where: {
        userId: 'user-1',
        status: 'verified',
      },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        productId: true,
        transactionId: true,
        gemsAwarded: true,
        createdAt: true,
        verifiedAt: true,
      },
    })
  })

  it('keeps the legacy /api/iap/restore alias wired to the canonical restore handler', async () => {
    const response = await restoreAliasPOST(
      makeNextRequest('http://localhost/api/iap/restore', {
        method: 'POST',
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      transactions: [
        {
          id: 'iap-1',
          productId: 'gems_small',
          transactionId: 'tx-1',
          gemsAwarded: 100,
        },
      ],
    })
  })
})
