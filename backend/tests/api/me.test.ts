import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetSupabaseAuthUser,
  mockGetPremiumExpiresAt,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetSupabaseAuthUser: vi.fn(),
  mockGetPremiumExpiresAt: vi.fn(),
  prismaMock: {
    user: {
      findUnique: vi.fn(),
      findFirst: vi.fn(),
      create: vi.fn(),
    },
  },
}))

vi.mock('@/lib/auth', () => ({
  getSupabaseAuthUser: mockGetSupabaseAuthUser,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

vi.mock('@/lib/game/premium', () => ({
  PREMIUM_ENTITLEMENT_USER_SELECT: {
    premiumUntil: true,
    premiumSubscription: {
      select: {
        expiresAt: true,
        status: true,
      },
    },
  },
  getPremiumExpiresAt: mockGetPremiumExpiresAt,
}))

import { GET } from '@/app/api/me/route'

describe('GET /api/me', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetSupabaseAuthUser.mockResolvedValue({
      id: 'user-1',
      email: 'user@example.com',
      app_metadata: { provider: 'email' },
      user_metadata: {},
    })
    mockGetPremiumExpiresAt.mockReturnValue(null)
    prismaMock.user.findUnique.mockResolvedValue({
      id: 'user-1',
      email: 'user@example.com',
      username: 'user',
      gems: 42,
      role: 'player',
      createdAt: new Date('2026-04-18T00:00:00.000Z'),
      lastLogin: new Date('2026-04-18T01:00:00.000Z'),
      premiumUntil: null,
      premiumSubscription: null,
      isBanned: false,
    })
    prismaMock.user.findFirst.mockResolvedValue(null)
    prismaMock.user.create.mockResolvedValue({
      id: 'user-1',
    })
  })

  it('returns 401 when auth token is invalid', async () => {
    mockGetSupabaseAuthUser.mockResolvedValueOnce(null)

    const response = await GET(makeNextRequest('http://localhost/api/me'))

    expect(response.status).toBe(401)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Unauthorized',
    })
  })

  it('returns the existing local user payload', async () => {
    const response = await GET(makeNextRequest('http://localhost/api/me'))

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      user: {
        id: 'user-1',
        email: 'user@example.com',
        username: 'user',
        gems: 42,
        premiumUntil: null,
      },
    })
  })

  it('bootstraps the missing local row when Supabase auth is valid', async () => {
    prismaMock.user.findUnique
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({
        id: 'user-1',
        email: 'user@example.com',
        username: 'user',
        gems: 0,
        role: 'player',
        createdAt: new Date('2026-04-18T00:00:00.000Z'),
        lastLogin: new Date('2026-04-18T01:00:00.000Z'),
        premiumUntil: null,
        premiumSubscription: null,
        isBanned: false,
      })

    const response = await GET(makeNextRequest('http://localhost/api/me'))

    expect(response.status).toBe(200)
    expect(prismaMock.user.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          id: 'user-1',
          email: 'user@example.com',
          username: 'user',
          authProvider: 'email',
          lastLogin: expect.any(Date),
        }),
      }),
    )
  })

  it('returns 409 when local bootstrap would collide with another email owner', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce(null)
    prismaMock.user.findFirst.mockResolvedValueOnce({ id: 'other-user' })

    const response = await GET(makeNextRequest('http://localhost/api/me'))

    expect(response.status).toBe(409)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Email already registered with another account.',
    })
    expect(prismaMock.user.create).not.toHaveBeenCalled()
  })

  it('reloads the local row if another request wins the bootstrap race', async () => {
    prismaMock.user.findUnique
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({
        id: 'user-1',
        email: 'user@example.com',
        username: 'user',
        gems: 7,
        role: 'player',
        createdAt: new Date('2026-04-18T00:00:00.000Z'),
        lastLogin: new Date('2026-04-18T01:00:00.000Z'),
        premiumUntil: null,
        premiumSubscription: null,
        isBanned: false,
      })
    prismaMock.user.create.mockRejectedValueOnce(new Error('Unique constraint failed on id'))

    const response = await GET(makeNextRequest('http://localhost/api/me'))

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      user: {
        id: 'user-1',
        gems: 7,
      },
    })
  })
})
