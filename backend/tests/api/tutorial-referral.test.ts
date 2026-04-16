import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockLogTutorialEvent,
  mockGenerateReferralCode,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(),
  mockLogTutorialEvent: vi.fn(),
  mockGenerateReferralCode: vi.fn(() => 'NEWCODE88'),
  prismaMock: {
    character: {
      findUnique: vi.fn(),
      update: vi.fn(),
      findFirst: vi.fn(),
      count: vi.fn(),
    },
    $transaction: vi.fn(),
  },
}))

vi.mock('@/lib/auth', () => ({
  getAuthUser: mockGetAuthUser,
}))

vi.mock('@/lib/rate-limit', () => ({
  rateLimit: mockRateLimit,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

vi.mock('@/lib/game/tutorial', () => ({
  REFERRAL_BONUS: {
    extraGold: 250,
    referrerGold: 500,
    referrerGems: 10,
    maxReferrals: 20,
    inviteeLevelThreshold: 5,
  },
  generateReferralCode: mockGenerateReferralCode,
  normalizeReferralCode: (code: string) => code.toUpperCase().trim(),
  getReferralLinkValues: (referrerId: string, referralCode: string) =>
    Array.from(new Set([referrerId, referralCode.toUpperCase().trim()])),
  isReferralCodeLike: (value: string | null | undefined) =>
    typeof value === 'string' && /^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8}$/.test(value.toUpperCase().trim()),
}))

vi.mock('@/lib/game/tutorial-analytics', () => ({
  logTutorialEvent: mockLogTutorialEvent,
}))

import {
  GET,
  POST,
} from '@/app/api/tutorial/referral/route'

describe('/api/tutorial/referral', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
  })

  it('GET counts referrals across legacy code storage and canonical character-id storage', async () => {
    prismaMock.character.findUnique.mockResolvedValue({
      id: 'char-1',
      userId: 'user-1',
      referralCode: 'SELF1234',
      referredBy: 'referrer-1',
    })
    prismaMock.character.findFirst.mockResolvedValue({
      id: 'referrer-1',
      referralCode: 'FRIEND88',
    })
    prismaMock.character.count
      .mockResolvedValueOnce(3)
      .mockResolvedValueOnce(2)

    const response = await GET(
      makeNextRequest('http://localhost/api/tutorial/referral?character_id=char-1'),
    )

    expect(response.status).toBe(200)
    expect(prismaMock.character.count).toHaveBeenNthCalledWith(1, {
      where: {
        referredBy: { in: ['char-1', 'SELF1234'] },
      },
    })
    expect(prismaMock.character.count).toHaveBeenNthCalledWith(2, {
      where: {
        referredBy: { in: ['char-1', 'SELF1234'] },
        level: { gte: 5 },
      },
    })
    await expect(response.json()).resolves.toMatchObject({
      referralCode: 'SELF1234',
      referredBy: 'FRIEND88',
      referredByCode: 'FRIEND88',
      referredByCharacterId: 'referrer-1',
      referralCount: 3,
      qualifiedCount: 2,
      maxReferrals: 20,
    })
  })

  it('POST uses the normal allowed=false rate-limit contract with a 60-second window', async () => {
    mockRateLimit.mockResolvedValue(false)

    const response = await POST(
      makeNextRequest('http://localhost/api/tutorial/referral', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
          referral_code: 'friend88',
        }),
      }),
    )

    expect(mockRateLimit).toHaveBeenCalledWith('tutorial_referral:user-1', 5, 60_000)
    expect(response.status).toBe(429)
    expect(prismaMock.$transaction).not.toHaveBeenCalled()
    await expect(response.json()).resolves.toEqual({ error: 'Rate limited' })
  })

  it('POST stores the canonical referrer character id while returning the friend code to clients', async () => {
    const tx = {
      $queryRawUnsafe: vi.fn()
        .mockResolvedValueOnce([{
          id: 'char-1',
          user_id: 'user-1',
          referred_by: null,
          referral_code: 'SELF1234',
        }])
        .mockResolvedValueOnce([{
          id: 'referrer-1',
          referral_code: 'FRIEND88',
        }]),
      character: {
        count: vi.fn(async () => 1),
        update: vi.fn(async () => ({})),
      },
      user: {
        update: vi.fn(async () => ({})),
      },
    }

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: typeof tx) => Promise<unknown>) => callback(tx),
    )

    const response = await POST(
      makeNextRequest('http://localhost/api/tutorial/referral', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
          referral_code: ' friend88 ',
        }),
      }),
    )

    expect(response.status).toBe(200)
    expect(tx.character.count).toHaveBeenCalledWith({
      where: {
        referredBy: {
          in: ['referrer-1', 'FRIEND88'],
        },
      },
    })
    expect(tx.character.update).toHaveBeenCalledWith({
      where: { id: 'char-1' },
      data: { referredBy: 'referrer-1' },
    })
    expect(tx.user.update).toHaveBeenCalledWith({
      where: { id: 'user-1' },
      data: { gold: { increment: 250 } },
    })
    expect(mockLogTutorialEvent).toHaveBeenCalledWith({
      event: 'referral_applied',
      characterId: 'char-1',
      referrerCode: 'FRIEND88',
      bonusGold: 250,
    })
    await expect(response.json()).resolves.toMatchObject({
      success: true,
      bonusGold: 250,
      referredBy: 'FRIEND88',
      referredByCode: 'FRIEND88',
      referredByCharacterId: 'referrer-1',
    })
  })
})
