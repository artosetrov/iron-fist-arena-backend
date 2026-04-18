import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockCreateAdminClient,
  mockRateLimit,
  prismaMock,
  txMock,
  supabaseClientMock,
} = vi.hoisted(() => {
  const supabaseClientMock = {
    auth: {
      signInWithIdToken: vi.fn(),
      admin: {
        deleteUser: vi.fn(),
      },
    },
  }

  const txMock = {
    user: {
      findUnique: vi.fn(),
      upsert: vi.fn(),
      delete: vi.fn(),
    },
    character: { updateMany: vi.fn() },
    cosmetic: { updateMany: vi.fn() },
    pushToken: { updateMany: vi.fn() },
    iapTransaction: { updateMany: vi.fn() },
    dailyGemCard: {
      findUnique: vi.fn(),
      deleteMany: vi.fn(),
      update: vi.fn(),
      delete: vi.fn(),
    },
    premiumSubscription: {
      findUnique: vi.fn(),
      update: vi.fn(),
      delete: vi.fn(),
    },
  }

  return {
    mockGetAuthUser: vi.fn(),
    mockCreateAdminClient: vi.fn(() => supabaseClientMock),
    mockRateLimit: vi.fn(() => true),
    prismaMock: {
      user: {
        findUnique: vi.fn(),
      },
      character: {
        findFirst: vi.fn(),
      },
      $transaction: vi.fn(async (callback: (tx: typeof txMock) => Promise<void>) => callback(txMock)),
    },
    txMock,
    supabaseClientMock,
  }
})

vi.mock('@/lib/auth', () => ({
  getAuthUser: mockGetAuthUser,
}))

vi.mock('@/lib/supabase/server', () => ({
  createAdminClient: mockCreateAdminClient,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

vi.mock('@/lib/rate-limit', () => ({
  rateLimit: mockRateLimit,
}))

import { POST } from '@/app/api/auth/upgrade-guest-oauth/route'

describe('POST /api/auth/upgrade-guest-oauth', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    mockGetAuthUser.mockResolvedValue({ id: 'guest-user' })
    mockRateLimit.mockResolvedValue(true)

    prismaMock.user.findUnique.mockImplementation(async ({ where }: { where: { id: string } }) => {
      if (where.id === 'guest-user') {
        return {
          id: 'guest-user',
          authProvider: 'anonymous',
          gold: 120,
          gems: 40,
          premiumUntil: new Date('2026-05-10T00:00:00.000Z'),
          premiumGemClaimDate: new Date('2026-04-17T00:00:00.000Z'),
        }
      }
      return null
    })

    prismaMock.character.findFirst.mockResolvedValue(null)
    prismaMock.$transaction.mockImplementation(async (callback: (tx: typeof txMock) => Promise<void>) => callback(txMock))

    supabaseClientMock.auth.signInWithIdToken.mockResolvedValue({
      data: {
        session: {
          access_token: 'access-token',
          refresh_token: 'refresh-token',
          expires_in: 3600,
        },
        user: {
          id: 'oauth-user',
          email: 'player@example.com',
          user_metadata: { full_name: 'Player One' },
        },
      },
      error: null,
    })

    supabaseClientMock.auth.admin.deleteUser.mockResolvedValue({ error: null })

    txMock.user.upsert.mockResolvedValue({})
    txMock.user.delete.mockResolvedValue({})
    txMock.character.updateMany.mockResolvedValue({ count: 1 })
    txMock.cosmetic.updateMany.mockResolvedValue({ count: 0 })
    txMock.pushToken.updateMany.mockResolvedValue({ count: 0 })
    txMock.iapTransaction.updateMany.mockResolvedValue({ count: 0 })
    txMock.dailyGemCard.deleteMany.mockResolvedValue({ count: 0 })
    txMock.dailyGemCard.update.mockResolvedValue({})
    txMock.dailyGemCard.delete.mockResolvedValue({})
    txMock.premiumSubscription.update.mockResolvedValue({})
    txMock.premiumSubscription.delete.mockResolvedValue({})
    txMock.premiumSubscription.findUnique
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(null)
  })

  it('merges guest and oauth wallet state instead of overwriting or dropping it', async () => {
    txMock.user.findUnique.mockResolvedValue({
      gold: 80,
      gems: 15,
      premiumUntil: new Date('2026-05-20T00:00:00.000Z'),
      premiumGemClaimDate: new Date('2026-04-18T00:00:00.000Z'),
    })
    txMock.dailyGemCard.findUnique
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(null)

    const response = await POST(
      makeNextRequest('http://localhost/api/auth/upgrade-guest-oauth', {
        method: 'POST',
        body: JSON.stringify({
          id_token: 'oauth-token',
          provider: 'google',
        }),
      }),
    )

    expect(response.status).toBe(200)
    expect(txMock.user.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'oauth-user' },
        update: expect.objectContaining({
          gold: 200,
          gems: 55,
          premiumUntil: new Date('2026-05-20T00:00:00.000Z'),
          premiumGemClaimDate: new Date('2026-04-18T00:00:00.000Z'),
        }),
        create: expect.objectContaining({
          gold: 120,
          gems: 40,
          premiumUntil: new Date('2026-05-10T00:00:00.000Z'),
          premiumGemClaimDate: new Date('2026-04-17T00:00:00.000Z'),
        }),
      }),
    )
  })

  it('keeps the longer-lived daily gem card when both accounts already have one', async () => {
    txMock.user.findUnique.mockResolvedValue({
      gold: 0,
      gems: 0,
      premiumUntil: null,
      premiumGemClaimDate: null,
    })
    txMock.dailyGemCard.findUnique
      .mockResolvedValueOnce({
        userId: 'guest-user',
        expiresAt: new Date('2026-04-20T00:00:00.000Z'),
        daysRemaining: 3,
      })
      .mockResolvedValueOnce({
        userId: 'oauth-user',
        expiresAt: new Date('2026-04-25T00:00:00.000Z'),
        daysRemaining: 8,
      })

    const response = await POST(
      makeNextRequest('http://localhost/api/auth/upgrade-guest-oauth', {
        method: 'POST',
        body: JSON.stringify({
          id_token: 'oauth-token',
          provider: 'apple',
        }),
      }),
    )

    expect(response.status).toBe(200)
    expect(txMock.dailyGemCard.delete).toHaveBeenCalledWith({
      where: { userId: 'guest-user' },
    })
    expect(txMock.dailyGemCard.deleteMany).not.toHaveBeenCalled()
    expect(txMock.dailyGemCard.update).not.toHaveBeenCalled()
  })

  it('deletes the fresh OAuth auth user if the guest->oauth transfer transaction fails before local attach', async () => {
    prismaMock.$transaction.mockRejectedValueOnce(new Error('tx failed'))

    const response = await POST(
      makeNextRequest('http://localhost/api/auth/upgrade-guest-oauth', {
        method: 'POST',
        body: JSON.stringify({
          id_token: 'oauth-token',
          provider: 'google',
        }),
      }),
    )

    expect(response.status).toBe(500)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Failed to link account. Please try again.',
    })
    expect(supabaseClientMock.auth.admin.deleteUser).toHaveBeenCalledWith('oauth-user')
  })
})
