import { beforeEach, describe, expect, it, vi } from 'vitest'

const {
  mockCreateAdminClient,
  mockRateLimit,
  prismaMock,
} = vi.hoisted(() => {
  const supabaseClientMock = {
    auth: {
      signInWithPassword: vi.fn(),
      admin: {
        updateUserById: vi.fn(),
      },
    },
  }

  return {
    mockCreateAdminClient: vi.fn(() => supabaseClientMock),
    mockRateLimit: vi.fn(() => true),
    prismaMock: {
      user: {
        findFirst: vi.fn(),
        upsert: vi.fn(),
      },
    },
    supabaseClientMock,
  }
})

vi.mock('@/lib/supabase/server', () => ({
  createAdminClient: mockCreateAdminClient,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

vi.mock('@/lib/rate-limit', () => ({
  rateLimit: mockRateLimit,
}))

import { POST } from '@/app/api/auth/login/route'

describe('POST /api/auth/login', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('returns 400 when email is missing', async () => {
    mockRateLimit.mockResolvedValue(true)

    const response = await POST(
      new Request('http://localhost/api/auth/login', {
        method: 'POST',
        body: JSON.stringify({ password: 'test123' }),
      }) as any,
    )

    expect(response.status).toBe(400)
    await expect(response.json()).resolves.toMatchObject({
      error: 'email and password are required',
    })
  })

  it('returns 400 when password is missing', async () => {
    mockRateLimit.mockResolvedValue(true)

    const response = await POST(
      new Request('http://localhost/api/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email: 'user@example.com' }),
      }) as any,
    )

    expect(response.status).toBe(400)
    await expect(response.json()).resolves.toMatchObject({
      error: 'email and password are required',
    })
  })

  it('returns 429 when rate limited', async () => {
    mockRateLimit.mockResolvedValue(false)

    const response = await POST(
      new Request('http://localhost/api/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email: 'user@example.com', password: 'test123' }),
      }) as any,
    )

    expect(response.status).toBe(429)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Too many requests. Please try again later.',
    })
  })

  it('returns 401 when Supabase rejects credentials', async () => {
    mockRateLimit.mockResolvedValue(true)
    const { supabaseClientMock } = vi.hoisted(() => ({
      supabaseClientMock: mockCreateAdminClient(),
    }))
    supabaseClientMock.auth.signInWithPassword.mockResolvedValue({
      data: { session: null },
      error: { message: 'Invalid login credentials' },
    })

    const response = await POST(
      new Request('http://localhost/api/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email: 'user@example.com', password: 'wrong' }),
      }) as any,
    )

    expect(response.status).toBe(401)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Invalid login credentials',
    })
  })

  it('returns 200 with tokens on successful login', async () => {
    mockRateLimit.mockResolvedValue(true)

    const supabaseClient = mockCreateAdminClient()
    supabaseClient.auth.signInWithPassword.mockResolvedValue({
      data: {
        session: {
          access_token: 'access-token-123',
          refresh_token: 'refresh-token-456',
          expires_in: 3600,
        },
        user: {
          id: 'user-1',
          email: 'user@example.com',
          role: 'authenticated',
        },
      },
      error: null,
    })

    prismaMock.user.upsert.mockResolvedValue({
      id: 'user-1',
      email: 'user@example.com',
      username: 'user',
      authProvider: 'email',
      lastLogin: new Date(),
    })

    const response = await POST(
      new Request('http://localhost/api/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email: 'user@example.com', password: 'test123' }),
      }) as any,
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      access_token: 'access-token-123',
      refresh_token: 'refresh-token-456',
      expires_in: 3600,
      user: {
        id: 'user-1',
        email: 'user@example.com',
        role: 'authenticated',
      },
    })
    expect(prismaMock.user.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'user-1' },
        update: { lastLogin: expect.any(Date) },
      }),
    )
  })

  it('auto-confirms unverified email and retries login', async () => {
    mockRateLimit.mockResolvedValue(true)

    const supabaseClient = mockCreateAdminClient()
    supabaseClient.auth.signInWithPassword
      .mockResolvedValueOnce({
        data: { session: null },
        error: { message: 'Email not confirmed' },
      })
      .mockResolvedValueOnce({
        data: {
          session: {
            access_token: 'access-token-123',
            refresh_token: 'refresh-token-456',
            expires_in: 3600,
          },
          user: {
            id: 'user-1',
            email: 'user@example.com',
            role: 'authenticated',
          },
        },
        error: null,
      })

    prismaMock.user.findFirst.mockResolvedValue({
      id: 'user-1',
      email: 'user@example.com',
    })

    supabaseClient.auth.admin.updateUserById.mockResolvedValue({
      user: { id: 'user-1', email: 'user@example.com' },
    })

    prismaMock.user.upsert.mockResolvedValue({
      id: 'user-1',
      email: 'user@example.com',
      username: 'user',
      authProvider: 'email',
      lastLogin: new Date(),
    })

    const response = await POST(
      new Request('http://localhost/api/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email: 'user@example.com', password: 'test123' }),
      }) as any,
    )

    expect(response.status).toBe(200)
    expect(supabaseClient.auth.admin.updateUserById).toHaveBeenCalledWith('user-1', {
      email_confirm: true,
    })
    expect(supabaseClient.auth.signInWithPassword).toHaveBeenCalledTimes(2)
  })
})
