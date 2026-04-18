import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetSupabaseAuthUser,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetSupabaseAuthUser: vi.fn(),
  prismaMock: {
    user: {
      findUnique: vi.fn(),
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

import { POST } from '@/app/api/auth/guest/route'

describe('POST /api/auth/guest', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetSupabaseAuthUser.mockResolvedValue({
      id: 'guest-user-1',
      email: null,
      app_metadata: { provider: 'anonymous' },
      user_metadata: {},
    })
    prismaMock.user.findUnique.mockResolvedValue(null)
    prismaMock.user.create.mockResolvedValue({
      id: 'guest-user-1',
      email: null,
      username: 'Guest1234',
      authProvider: 'anonymous',
      isBanned: false,
    })
  })

  it('returns 401 when auth token is invalid', async () => {
    mockGetSupabaseAuthUser.mockResolvedValueOnce(null)

    const response = await POST(
      makeNextRequest('http://localhost/api/auth/guest', { method: 'POST' }),
    )

    expect(response.status).toBe(401)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Unauthorized',
    })
  })

  it('returns the existing local guest row when it already exists', async () => {
    prismaMock.user.findUnique.mockResolvedValueOnce({
      id: 'guest-user-1',
      email: 'guest_1@guest.ironfist.local',
      username: 'Guest1111',
      authProvider: 'anonymous',
      isBanned: false,
    })

    const response = await POST(
      makeNextRequest('http://localhost/api/auth/guest', { method: 'POST' }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      user: {
        id: 'guest-user-1',
        email: 'guest_1@guest.ironfist.local',
      },
    })
    expect(prismaMock.user.create).not.toHaveBeenCalled()
  })

  it('creates the missing local row for a valid guest auth user', async () => {
    const response = await POST(
      makeNextRequest('http://localhost/api/auth/guest', { method: 'POST' }),
    )

    expect(response.status).toBe(200)
    expect(prismaMock.user.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          id: 'guest-user-1',
          authProvider: 'anonymous',
          lastLogin: expect.any(Date),
        }),
      }),
    )
  })

  it('reloads the row and returns 200 if a concurrent request wins the local create race', async () => {
    prismaMock.user.findUnique
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({
        id: 'guest-user-1',
        email: 'guest_race@guest.ironfist.local',
        username: 'Guest2222',
        authProvider: 'anonymous',
        isBanned: false,
      })
    prismaMock.user.create.mockRejectedValueOnce(new Error('Unique constraint failed on id'))

    const response = await POST(
      makeNextRequest('http://localhost/api/auth/guest', { method: 'POST' }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      user: {
        id: 'guest-user-1',
        email: 'guest_race@guest.ironfist.local',
      },
    })
  })
})
