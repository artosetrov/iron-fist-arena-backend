/**
 * POST /api/shop/buy-gems — the gold→gem conversion is capped per account per
 * day (2026-10-14 balance audit). Uncapped, every gem price in the game was a
 * gold price at ~30:1 with a multi-thousand daily gold surplus behind it.
 */
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const { mockGetAuthUser, mockRateLimit, prismaMock, quests } = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  prismaMock: { $transaction: vi.fn() },
  quests: { daily: vi.fn(), weekly: vi.fn() },
}))

vi.mock('@/lib/auth', () => ({ getAuthUser: mockGetAuthUser }))
vi.mock('@/lib/prisma', () => ({ prisma: prismaMock }))
vi.mock('@/lib/rate-limit', () => ({ rateLimit: mockRateLimit, shopRateLimit: mockRateLimit }))
vi.mock('@/lib/game/daily-quests', () => ({ updateDailyQuestProgress: quests.daily }))
vi.mock('@/lib/game/weekly-challenges', () => ({ updateWeeklyChallengeProgress: quests.weekly }))

import { POST } from '@/app/api/shop/buy-gems/route'
import { GEM_PACK_DAILY_PURCHASE_CAP } from '@/lib/game/gem-packs'

function txWith(userRow: { gold: number; gem_pack_purchases_today: number; gem_pack_purchase_date: Date | null }) {
  const tx = {
    character: { findUnique: vi.fn(async () => ({ userId: 'user-1', level: 20 })) },
    $queryRawUnsafe: vi.fn(async () => [{ id: 'user-1', ...userRow }]),
    user: {
      update: vi.fn(async ({ data }: { data: Record<string, unknown> }) => ({
        gold: userRow.gold - 3000,
        gems: 100,
        gemPackPurchasesToday: data.gemPackPurchasesToday,
      })),
    },
  }
  prismaMock.$transaction.mockImplementation(async (fn: (t: typeof tx) => Promise<unknown>) => fn(tx))
  return tx
}

function buy() {
  return POST(
    makeNextRequest('http://localhost/api/shop/buy-gems', {
      method: 'POST',
      body: JSON.stringify({ character_id: 'char-1', catalog_id: 'gem_pack_large' }),
    }),
  )
}

describe('POST /api/shop/buy-gems daily cap', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
  })

  it('allows the first pack of the day and records it on the account', async () => {
    const tx = txWith({ gold: 10_000, gem_pack_purchases_today: 0, gem_pack_purchase_date: null })
    const response = await buy()
    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      gemsReceived: 100,
      packsBoughtToday: 1,
      packsDailyCap: GEM_PACK_DAILY_PURCHASE_CAP,
    })
    expect(tx.user.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ gemPackPurchasesToday: 1 }) }),
    )
  })

  it('refuses a second pack the same day, before touching gold', async () => {
    const tx = txWith({ gold: 10_000, gem_pack_purchases_today: GEM_PACK_DAILY_PURCHASE_CAP, gem_pack_purchase_date: new Date() })
    const response = await buy()
    expect(response.status).toBe(429)
    expect(tx.user.update).not.toHaveBeenCalled()
  })

  it('resets the counter on a new UTC day', async () => {
    const yesterday = new Date(Date.now() - 36 * 60 * 60 * 1000)
    const tx = txWith({ gold: 10_000, gem_pack_purchases_today: GEM_PACK_DAILY_PURCHASE_CAP, gem_pack_purchase_date: yesterday })
    const response = await buy()
    expect(response.status).toBe(200)
    expect(tx.user.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ gemPackPurchasesToday: 1 }) }),
    )
  })

  it('checks the cap inside the same row lock as the gold balance', async () => {
    const tx = txWith({ gold: 10_000, gem_pack_purchases_today: 0, gem_pack_purchase_date: null })
    await buy()
    const sql = tx.$queryRawUnsafe.mock.calls[0][0] as string
    expect(sql).toMatch(/FOR UPDATE/)
    expect(sql).toMatch(/gem_pack_purchases_today/)
  })
})
