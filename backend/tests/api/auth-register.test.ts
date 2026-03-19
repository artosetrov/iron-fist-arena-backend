import { beforeEach, describe, expect, it, vi } from 'vitest'

const {
  mockCreateAdminClient,
  mockRateLimit,
  prismaMock,
} = vi.hoisted(() => {
  const supabaseClientMock = {
    auth: {
      admin: {
        createUser: vi.fn(),
      },
      signInWithPassword: vi.fn(),
    },
  }

  return {
    mockCreateAdminClient: vi.fn(() => supabaseClientMock),
    mockRateLimit: vi.fn(() => true),
    prismaMock: {
      user: {
        create: vi.fn(),
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

import { POST } from '@/app/api/auth/register/route'

describe('POST /api/auth/register', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('returns 400 when email is missing', async () => {
    mockRateLimit.mockResolvedValue(true)

    const response = await POST(
      new Request('http://localhost/api/auth/register', {
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
      new Request('http://localhost/api/auth/register', {
        method: 'POST',
        body: JSON.stringify({ email: 'newuser@example.com' }),
      }) as any,
    )

    expect(response.status).toBe(400)
    await expect(response.json()).resolves.toMatchObject({
      error: 'email and password are required',
    })
  })

  it('returns 400 when password is shorter than 6 characters', async () => {
    mockRateLimit.mockResolvedValue(true)

    const response = await POST(
      new Request('http://localhost/api/auth/register', {
        method: 'POST',
        body: JSON.stringify({ email: 'newuser@example.com', password: '12345' }),
      }) as any,
    )

    expect(response.status).toBe(400)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Password must be at least 6 characters',
    })
  })

  it('returns 429 when rate limited', async () => {
    mockRateLimit.mockResolvedValue(false)

    const response = await POST(
      new Request('http://localhost/api/auth/register', {
        method: 'POST',
        body: JSON.stringify({ email: 'newuser@example.com', password: 'test123' }),
      }) as any,
    )

    expect(response.status).toBe(429)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Too many requests. Please try again later.',
    })
  })

  it('returns 409 when email already exists', async () => {
    mockRateLimit.mockResolvedValue(true)

    const supabaseClient = mockCreateAdminClient()
    supabaseClient.auth.admin.createUser.mockResolvedValue({
      data: { user: null },
      error: { message: 'User already been registered' },
    })

    const response = await POST(
      new Request('http://localhost/api/auth/register', {
        method: 'POST',
        body: JSON.stringify({ email: 'existing@example.com', password: 'test123' }),
      }) as any,
    )

    expect(response.status).toBe(409)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Email already registered. Please login instead.',
    })
  })

  it('returns 200 with tokens on successful registration', async () => {
    mockRateLimit.mockResolvedValue(true)

    const supabaseClient = mockCreateAdminClient()
    supabaseClient.auth.admin.createUser.mockResolvedValue({
      data: {
        user: {
          id: 'user-new-1',
          email: 'newuser@example.com',
          role: 'authenticated',
        },
      },
      error: null,
    })

    supabaseClient.auth.signInWithPassword.mockResolvedValue({
      data: {
        session: {
          access_token: 'access-token-new',
          refresh_token: 'refresh-token-new',
          expires_in: 3600,
        },
      },
      error: null,
    })

    prismaMock.user.create.mockResolvedValue({
      id: 'user-new-1',
      email: 'newuser@example.com',
      username: 'newuser',
      authProvider: 'email',
    })

    const response = await POST(
      new Request('http://localhost/api/auth/register', {
        method: 'POST',
        body: JSON.stringify({
          email: 'newuser@example.com',
          password: 'test123',
          username: 'newuser',
        }),
      }) as any,
    )

    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data).toMatchObject({
      needs_confirmation: false,
      access_token: 'access-token-new',
      refresh_token: 'refresh-token-new',
      expires_in: 3600,
      user: {
        id: 'user-new-1',
        email: 'newuser@example.com',
        role: 'authenticated',
      },
    })
    expect(prismaMock.user.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: {
          id: 'user-new-1',
          username: 'newuser',
          email: 'newuser@example.com',
          authProvider: 'email',
        },
      }),
    )
  })

  it('uses email prefix as username when username not provided', async () => {
    mockRateLimit.mockResolvedValue(true)

    const supabaseClient = mockCreateAdminClient()
    supabaseClient.auth.admin.createUser.mockResolvedValue({
      data: {
        user: {
          id: 'user-new-2',
          email: 'nouser@example.com',
          role: 'authenticated',
        },
      },
      error: null,
    })

    supabaseClient.auth.signInWithPassword.mockResolvedValue({
      data: {
        session: {
          access_token: 'access-token',
          refresh_token: 'refresh-token',
          expires_in: 3600,
        },
      },
      error: null,
    })

    prismaMock.user.create.mockResolvedValue({
      id: 'user-new-2',
      email: 'nouser@example.com',
      username: 'nouser',
      authProvider: 'email',
    })

    const response = await POST(
      new Request('http://localhost/api/auth/register', {
        method: 'POST',
        body: JSON.stringify({ email: 'nouser@example.com', password: 'test123' }),
      }) as any,
    )

    expect(response.status).toBe(200)
    expect(prismaMock.user.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          username: 'nouser',
        }),
      }),
    )
  })
})
