import { Prisma } from '@prisma/client'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockVerifyAppleTransaction,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockVerifyAppleTransaction: vi.fn(),
  prismaMock: {
    iapTransaction: {
      findUnique: vi.fn(),
      create: vi.fn(),
    },
    user: {
      update: vi.fn(),
    },
    character: {
      findFirst: vi.fn(),
      updateMany: vi.fn(),
    },
    consumableInventory: {
      upsert: vi.fn(),
    },
    premiumSubscription: {
      upsert: vi.fn(),
    },
    dailyGemCard: {
      upsert: vi.fn(),
    },
    $transaction: vi.fn(),
  },
}))

vi.mock('@/lib/auth', () => ({
  getAuthUser: mockGetAuthUser,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

vi.mock('@/lib/apple-iap', () => ({
  verifyAppleTransaction: mockVerifyAppleTransaction,
}))

import { POST } from '@/app/api/iap/verify-receipt/route'
import { POST as verifyAliasPOST } from '@/app/api/iap/verify/route'

describe('POST /api/iap/verify-receipt', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockVerifyAppleTransaction.mockResolvedValue({ valid: true })
    prismaMock.iapTransaction.findUnique.mockResolvedValue(null)
    prismaMock.iapTransaction.create.mockReturnValue({ op: 'iapTransaction.create' })
    prismaMock.user.update.mockReturnValue({ op: 'user.update' })
    prismaMock.character.findFirst.mockResolvedValue(null)
    prismaMock.character.updateMany.mockReturnValue({ op: 'character.updateMany' })
    prismaMock.consumableInventory.upsert.mockReturnValue({ op: 'consumableInventory.upsert' })
    prismaMock.premiumSubscription.upsert.mockReturnValue({ op: 'premiumSubscription.upsert' })
    prismaMock.dailyGemCard.upsert.mockReturnValue({ op: 'dailyGemCard.upsert' })
    prismaMock.$transaction.mockResolvedValue([{ id: 'iap-row-1' }])
  })

  it('returns 409 when the transaction was already processed before verification', async () => {
    prismaMock.iapTransaction.findUnique.mockResolvedValue({
      id: 'iap-row-1',
      transactionId: 'tx-1',
    })

    const response = await POST(
      makeNextRequest('http://localhost/api/iap/verify-receipt', {
        method: 'POST',
        body: JSON.stringify({
          product_id: 'gems_small',
          transaction_id: 'tx-1',
          receipt_data: 'receipt-blob',
        }),
      }),
    )

    expect(response.status).toBe(409)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Transaction already processed',
    })
    expect(mockVerifyAppleTransaction).not.toHaveBeenCalled()
    expect(prismaMock.$transaction).not.toHaveBeenCalled()
  })

  it('returns 409 instead of 500 when a concurrent receipt write hits the unique transaction constraint', async () => {
    mockVerifyAppleTransaction.mockResolvedValue({
      valid: true,
      transactionInfo: {
        transactionId: 'tx-race',
        originalTransactionId: 'orig-race',
        bundleId: 'com.hexbound.app',
        productId: 'gems_small',
        purchaseDate: Date.parse('2026-04-15T10:00:00.000Z'),
        type: 'Consumable',
        inAppOwnershipType: 'PURCHASED',
        environment: 'Sandbox',
        signedDate: Date.parse('2026-04-15T10:00:01.000Z'),
      },
    })

    prismaMock.$transaction.mockRejectedValue(
      new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
        code: 'P2002',
        clientVersion: 'test',
        meta: { target: ['transaction_id'] },
      }),
    )

    const response = await POST(
      makeNextRequest('http://localhost/api/iap/verify-receipt', {
        method: 'POST',
        body: JSON.stringify({
          product_id: 'gems_small',
          transaction_id: 'tx-race',
          receipt_data: 'receipt-race',
        }),
      }),
    )

    expect(response.status).toBe(409)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Transaction already processed',
    })
  })

  it('upserts premium subscription state and returns the authoritative expiry for subscription purchases', async () => {
    mockVerifyAppleTransaction.mockResolvedValue({
      valid: true,
      transactionInfo: {
        transactionId: 'tx-sub',
        originalTransactionId: 'orig-sub',
        bundleId: 'com.hexbound.app',
        productId: 'com.hexbound.premium_pass_monthly',
        purchaseDate: Date.parse('2026-04-15T10:00:00.000Z'),
        expiresDate: Date.parse('2026-05-15T10:00:00.000Z'),
        type: 'Auto-Renewable Subscription',
        inAppOwnershipType: 'PURCHASED',
        environment: 'Sandbox',
        signedDate: Date.parse('2026-04-15T10:00:01.000Z'),
      },
    })

    const response = await POST(
      makeNextRequest('http://localhost/api/iap/verify-receipt', {
        method: 'POST',
        body: JSON.stringify({
          product_id: 'premium_pass_monthly',
          transaction_id: 'tx-sub',
          receipt_data: 'receipt-sub',
        }),
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      success: true,
      transactionId: 'iap-row-1',
      subscriptionExpiresAt: '2026-05-15T10:00:00.000Z',
      monthlyGemsAwarded: 300,
    })
    expect(prismaMock.user.update).toHaveBeenCalledWith({
      where: { id: 'user-1' },
      data: { gems: { increment: 300 } },
    })
    expect(prismaMock.premiumSubscription.upsert).toHaveBeenCalledWith({
      where: { userId: 'user-1' },
      create: expect.objectContaining({
        userId: 'user-1',
        productId: 'premium_pass_monthly',
        originalTransactionId: 'orig-sub',
        latestTransactionId: 'tx-sub',
        autoRenew: true,
        status: 'active',
        latestReceipt: 'receipt-sub',
      }),
      update: expect.objectContaining({
        productId: 'premium_pass_monthly',
        originalTransactionId: 'orig-sub',
        latestTransactionId: 'tx-sub',
        autoRenew: true,
        status: 'active',
        latestReceipt: 'receipt-sub',
      }),
    })
  })

  it('keeps the live /api/iap/verify alias wired to the canonical verify handler', async () => {
    const response = await verifyAliasPOST(
      makeNextRequest('http://localhost/api/iap/verify', {
        method: 'POST',
        body: JSON.stringify({
          product_id: 'gems_small',
          transaction_id: 'tx-alias',
          receipt_data: 'receipt-alias',
        }),
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      success: true,
      transactionId: 'iap-row-1',
      gemsAwarded: 100,
    })
  })
})
