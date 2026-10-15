import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const { mockGetAuthUser, prismaMock } = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  prismaMock: {
    iapTransaction: {
      findFirst: vi.fn(),
    },
    dailyGemCard: {
      findUnique: vi.fn(),
    },
  },
}))

vi.mock('@/lib/auth', () => ({
  getAuthUser: mockGetAuthUser,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

import { GET } from '@/app/api/iap/offers/route'
import { IAP_PRODUCTS, MONTHLY_GEM_CARD } from '@/lib/game/balance'

const NOW = new Date('2026-10-15T12:00:00.000Z')
const DAY_MS = 24 * 60 * 60 * 1000

function getOffers() {
  return GET(makeNextRequest('http://localhost/api/iap/offers'))
}

describe('GET /api/iap/offers', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.useFakeTimers()
    vi.setSystemTime(NOW)
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    prismaMock.iapTransaction.findFirst.mockResolvedValue(null)
    prismaMock.dailyGemCard.findUnique.mockResolvedValue(null)
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('requires a signed-in player', async () => {
    mockGetAuthUser.mockResolvedValue(null)

    const response = await getOffers()

    expect(response.status).toBe(401)
    expect(prismaMock.iapTransaction.findFirst).not.toHaveBeenCalled()
  })

  it('offers the Starter Bundle and quotes the gem card terms from balance.ts to a new account', async () => {
    const response = await getOffers()

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toEqual({
      starterBundleAvailable: true,
      gemCard: {
        instantGems: IAP_PRODUCTS.monthly_gem_card.gems,
        dailyGems: MONTHLY_GEM_CARD.DAILY_GEMS,
        days: MONTHLY_GEM_CARD.DAYS,
        active: false,
        daysRemaining: 0,
        expiresAt: null,
      },
    })
    expect(IAP_PRODUCTS.monthly_gem_card.gems).toBe(MONTHLY_GEM_CARD.INSTANT_GEMS)
  })

  it('withdraws the Starter Bundle once the account has bought it', async () => {
    prismaMock.iapTransaction.findFirst.mockResolvedValue({ id: 'iap-row-1' })

    const response = await getOffers()

    await expect(response.json()).resolves.toMatchObject({ starterBundleAvailable: false })
    expect(prismaMock.iapTransaction.findFirst).toHaveBeenCalledWith({
      where: { userId: 'user-1', productId: 'starter_bundle' },
      select: { id: true },
    })
  })

  it('reports an active card, capping the days left by its expiry', async () => {
    const expiresAt = new Date(NOW.getTime() + 12.5 * DAY_MS)
    prismaMock.dailyGemCard.findUnique.mockResolvedValue({ expiresAt, daysRemaining: 20 })

    const response = await getOffers()

    await expect(response.json()).resolves.toMatchObject({
      gemCard: { active: true, daysRemaining: 13, expiresAt: expiresAt.toISOString() },
    })
  })

  it('treats an expired or used-up card as inactive', async () => {
    prismaMock.dailyGemCard.findUnique.mockResolvedValueOnce({
      expiresAt: new Date(NOW.getTime() - DAY_MS),
      daysRemaining: 5,
    })
    const expired = await getOffers()
    await expect(expired.json()).resolves.toMatchObject({
      gemCard: { active: false, daysRemaining: 0, expiresAt: null },
    })

    prismaMock.dailyGemCard.findUnique.mockResolvedValueOnce({
      expiresAt: new Date(NOW.getTime() + 3 * DAY_MS),
      daysRemaining: 0,
    })
    const usedUp = await getOffers()
    await expect(usedUp.json()).resolves.toMatchObject({
      gemCard: { active: false, daysRemaining: 0 },
    })
  })

  it('answers 500 without leaking the error when the database fails', async () => {
    const error = vi.spyOn(console, 'error').mockImplementation(() => {})
    prismaMock.dailyGemCard.findUnique.mockRejectedValue(new Error('connection reset'))

    const response = await getOffers()

    expect(response.status).toBe(500)
    await expect(response.json()).resolves.toEqual({ error: 'Failed to load offers' })
    error.mockRestore()
  })
})
