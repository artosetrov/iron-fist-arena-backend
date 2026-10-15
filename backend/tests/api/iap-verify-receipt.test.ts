import { Prisma } from '@prisma/client'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const APPLE_TO_INTERNAL: Record<string, string> = {
  'com.hexbound.gems_small': 'gems_small',
  'com.hexbound.gems_mega': 'gems_mega',
  'com.hexbound.premium_pass_monthly': 'premium_pass_monthly',
  'com.hexbound.monthly_gem_card': 'monthly_gem_card',
  'com.hexbound.adventurer_bundle_III': 'adventurer_bundle_III',
  'com.hexbound.starter_bundle': 'starter_bundle',
  // Bare internal keys, as StoreKit Configuration environments may report them.
  gems_small: 'gems_small',
  gems_mega: 'gems_mega',
  premium_pass_monthly: 'premium_pass_monthly',
  monthly_gem_card: 'monthly_gem_card',
}

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
      findFirst: vi.fn(),
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
    $executeRaw: vi.fn(),
  },
}))

vi.mock('@/lib/auth', () => ({
  getAuthUser: mockGetAuthUser,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

// Kill switch (AUDIT-2026-10-13): default on; the route reads it before
// touching prisma, so tests that don't seed featureFlag keep working.
vi.mock('@/lib/game/feature-flags', () => ({
  isKillSwitchOn: vi.fn(async () => true),
}))

vi.mock('@/lib/apple-iap', () => ({
  verifyAppleTransaction: mockVerifyAppleTransaction,
  // Rewards are resolved from Apple's product id, never the client's — the
  // route imports this mapper, so the mock must provide it.
  internalProductIdFromApple: (appleProductId: string) =>
    APPLE_TO_INTERNAL[appleProductId],
}))

import { POST } from '@/app/api/iap/verify-receipt/route'
import { POST as verifyAliasPOST } from '@/app/api/iap/verify/route'
import { IAP_PRODUCTS, MONTHLY_GEM_CARD } from '@/lib/game/balance'

function appleConfirms(appleProductId: string, transactionId: string) {
  mockVerifyAppleTransaction.mockResolvedValue({
    valid: true,
    transactionInfo: {
      transactionId,
      originalTransactionId: transactionId,
      bundleId: 'com.hexbound.app',
      productId: appleProductId,
      purchaseDate: Date.now(),
      type: 'Consumable',
      inAppOwnershipType: 'PURCHASED',
      environment: 'Production',
      signedDate: Date.now(),
    },
  })
}

function redeem(productId: string, transactionId: string) {
  return POST(
    makeNextRequest('http://localhost/api/iap/verify-receipt', {
      method: 'POST',
      body: JSON.stringify({
        product_id: productId,
        transaction_id: transactionId,
        receipt_data: 'receipt-blob',
      }),
    }),
  )
}

describe('POST /api/iap/verify-receipt', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockVerifyAppleTransaction.mockResolvedValue({ valid: true })
    prismaMock.iapTransaction.findUnique.mockResolvedValue(null)
    prismaMock.iapTransaction.findFirst.mockResolvedValue(null)
    prismaMock.$executeRaw.mockReturnValue({ op: 'dailyGemCard.startOrExtend' })
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

  it('blocks product substitution: a cheap receipt claimed against an expensive SKU', async () => {
    // Real, Apple-valid $0.99 transaction replayed with product_id: gems_mega.
    mockVerifyAppleTransaction.mockResolvedValue({
      valid: true,
      transactionInfo: {
        transactionId: 'tx-sub',
        originalTransactionId: 'tx-sub',
        bundleId: 'com.hexbound.app',
        productId: 'com.hexbound.gems_small',
        purchaseDate: Date.now(),
        type: 'Consumable',
        inAppOwnershipType: 'PURCHASED',
        environment: 'Production',
        signedDate: Date.now(),
      },
    })

    const response = await POST(
      makeNextRequest('http://localhost/api/iap/verify-receipt', {
        method: 'POST',
        body: JSON.stringify({
          product_id: 'gems_mega',
          transaction_id: 'tx-sub',
          receipt_data: 'receipt-blob',
        }),
      }),
    )

    expect(response.status).toBe(403)
    expect(prismaMock.$transaction).not.toHaveBeenCalled()
  })

  it('rejects a transaction for a product id we do not sell', async () => {
    mockVerifyAppleTransaction.mockResolvedValue({
      valid: true,
      transactionInfo: {
        transactionId: 'tx-unknown',
        originalTransactionId: 'tx-unknown',
        bundleId: 'com.hexbound.app',
        productId: 'com.hexbound.not_a_real_sku',
        purchaseDate: Date.now(),
        type: 'Consumable',
        inAppOwnershipType: 'PURCHASED',
        environment: 'Production',
        signedDate: Date.now(),
      },
    })

    const response = await POST(
      makeNextRequest('http://localhost/api/iap/verify-receipt', {
        method: 'POST',
        body: JSON.stringify({
          product_id: 'gems_small',
          transaction_id: 'tx-unknown',
          receipt_data: 'receipt-blob',
        }),
      }),
    )

    expect(response.status).toBe(403)
    expect(prismaMock.$transaction).not.toHaveBeenCalled()
  })

  it('grants the product Apple confirms when client and Apple agree', async () => {
    mockVerifyAppleTransaction.mockResolvedValue({
      valid: true,
      transactionInfo: {
        transactionId: 'tx-ok',
        originalTransactionId: 'tx-ok',
        bundleId: 'com.hexbound.app',
        productId: 'com.hexbound.gems_small',
        purchaseDate: Date.now(),
        type: 'Consumable',
        inAppOwnershipType: 'PURCHASED',
        environment: 'Production',
        signedDate: Date.now(),
      },
    })

    const response = await POST(
      makeNextRequest('http://localhost/api/iap/verify-receipt', {
        method: 'POST',
        body: JSON.stringify({
          product_id: 'gems_small',
          transaction_id: 'tx-ok',
          receipt_data: 'receipt-blob',
        }),
      }),
    )

    expect(response.status).toBe(200)
    expect(prismaMock.$transaction).toHaveBeenCalled()
  })

  it('starts or extends the Monthly Gem Card in one atomic statement instead of resetting it', async () => {
    appleConfirms('com.hexbound.monthly_gem_card', 'tx-card')

    const response = await redeem('monthly_gem_card', 'tx-card')

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      gemsAwarded: IAP_PRODUCTS.monthly_gem_card.gems,
      gemCardActivated: true,
    })
    // The old Prisma upsert overwrote days_remaining with 30.
    expect(prismaMock.dailyGemCard.upsert).not.toHaveBeenCalled()
    expect(prismaMock.$executeRaw).toHaveBeenCalledTimes(1)
    const [strings, ...values] = prismaMock.$executeRaw.mock.calls[0] as [TemplateStringsArray, ...unknown[]]
    const sql = strings.join('?')
    expect(sql).toContain('ON CONFLICT ("user_id") DO UPDATE')
    expect(sql).toContain('"daily_gem_cards"."days_remaining" + ?')
    expect(sql).toContain('"daily_gem_cards"."expires_at" + make_interval')
    expect(values).toContain('user-1')
    expect(values).toContain(MONTHLY_GEM_CARD.DAYS)
    const [operations] = prismaMock.$transaction.mock.calls[0] as [unknown[]]
    expect(operations).toContainEqual({ op: 'dailyGemCard.startOrExtend' })
  })

  it('still grants a repeat Starter Bundle receipt — Apple already charged — and logs it', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    appleConfirms('com.hexbound.starter_bundle', 'tx-starter-2')
    prismaMock.iapTransaction.findFirst.mockResolvedValue({ id: 'iap-row-old' })

    const response = await redeem('starter_bundle', 'tx-starter-2')

    expect(response.status).toBe(200)
    expect(prismaMock.$transaction).toHaveBeenCalled()
    expect(prismaMock.iapTransaction.findFirst).toHaveBeenCalledWith({
      where: { userId: 'user-1', productId: 'starter_bundle' },
      select: { id: true },
    })
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('one-time product starter_bundle bought again'))
    warn.mockRestore()
  })

  it('does not flag a first Starter Bundle purchase', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    appleConfirms('com.hexbound.starter_bundle', 'tx-starter-1')

    const response = await redeem('starter_bundle', 'tx-starter-1')

    expect(response.status).toBe(200)
    expect(warn).not.toHaveBeenCalled()
    warn.mockRestore()
  })
})
