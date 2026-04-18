import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  prismaMock: {
    user: {
      findUnique: vi.fn(),
      update: vi.fn(),
    },
  },
}))

vi.mock('@/lib/auth', () => ({
  getAuthUser: mockGetAuthUser,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

import { POST } from '@/app/api/auth/link-account/route'

describe('POST /api/auth/link-account', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('returns 401 when the caller is unauthenticated', async () => {
    mockGetAuthUser.mockResolvedValue(null)

    const response = await POST(
      makeNextRequest('http://localhost/api/auth/link-account', {
        method: 'POST',
        body: JSON.stringify({ email: 'player@example.com', username: 'player' }),
      }),
    )

    expect(response.status).toBe(401)
  })

  it('returns 409 when the target email belongs to another user', async () => {
    mockGetAuthUser.mockResolvedValue({ id: 'user-1', app_metadata: { provider: 'google' } })
    prismaMock.user.findUnique
      .mockResolvedValueOnce({ id: 'user-1', email: null, authProvider: 'anonymous' })
      .mockResolvedValueOnce({ id: 'other-user' })

    const response = await POST(
      makeNextRequest('http://localhost/api/auth/link-account', {
        method: 'POST',
        body: JSON.stringify({ email: 'taken@example.com', username: 'player' }),
      }),
    )

    expect(response.status).toBe(409)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Email already registered with another account.',
    })
    expect(prismaMock.user.update).not.toHaveBeenCalled()
  })

  it('updates local profile fields when the email is free', async () => {
    mockGetAuthUser.mockResolvedValue({ id: 'user-1', app_metadata: { provider: 'google' } })
    prismaMock.user.findUnique
      .mockResolvedValueOnce({ id: 'user-1', email: null, authProvider: 'anonymous' })
      .mockResolvedValueOnce(null)
    prismaMock.user.update.mockResolvedValue({
      id: 'user-1',
      email: 'player@example.com',
      username: 'player',
      authProvider: 'google',
    })

    const response = await POST(
      makeNextRequest('http://localhost/api/auth/link-account', {
        method: 'POST',
        body: JSON.stringify({ email: 'player@example.com', username: 'player' }),
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      user: {
        id: 'user-1',
        email: 'player@example.com',
        username: 'player',
        authProvider: 'google',
      },
    })
    expect(prismaMock.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'user-1' },
        data: expect.objectContaining({
          email: 'player@example.com',
          username: 'player',
          authProvider: 'google',
          lastLogin: expect.any(Date),
        }),
      }),
    )
  })
})
