import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockCreateAdminClient,
  mockRateLimit,
  prismaMock,
  supabaseClientMock,
} = vi.hoisted(() => {
  const supabaseClientMock = {
    auth: {
      admin: {
        deleteUser: vi.fn(),
      },
      signInWithIdToken: vi.fn(),
    },
  }

  return {
    mockCreateAdminClient: vi.fn(() => supabaseClientMock),
    mockRateLimit: vi.fn(() => true),
    prismaMock: {
      user: {
        findUnique: vi.fn(),
        create: vi.fn(),
        update: vi.fn(),
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

import { POST as postGoogle } from '@/app/api/auth/google/route'
import { POST as postApple } from '@/app/api/auth/apple/route'

describe('OAuth auth local user sync', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockRateLimit.mockResolvedValue(true)
    prismaMock.user.findUnique.mockResolvedValue(null)
    prismaMock.user.create.mockResolvedValue({})
    prismaMock.user.update.mockResolvedValue({})
    supabaseClientMock.auth.admin.deleteUser.mockResolvedValue({ error: null })
  })

  it('returns 500 for Google sign-in when first-time local user creation fails', async () => {
    supabaseClientMock.auth.signInWithIdToken.mockResolvedValue({
      data: {
        session: {
          access_token: 'access-token',
          refresh_token: 'refresh-token',
          expires_in: 3600,
        },
        user: {
          id: 'google-user',
          email: 'player@example.com',
          role: 'authenticated',
          user_metadata: { full_name: 'Player One' },
        },
      },
      error: null,
    })
    prismaMock.user.create.mockRejectedValueOnce(new Error('db create failed'))

    const response = await postGoogle(
      makeNextRequest('http://localhost/api/auth/google', {
        method: 'POST',
        body: JSON.stringify({ id_token: 'google-token' }),
      }),
    )

    expect(response.status).toBe(500)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Failed to initialize account',
    })
    expect(supabaseClientMock.auth.admin.deleteUser).toHaveBeenCalledWith('google-user')
  })

  it('returns 500 for Apple sign-in when first-time local user creation fails', async () => {
    supabaseClientMock.auth.signInWithIdToken.mockResolvedValue({
      data: {
        session: {
          access_token: 'access-token',
          refresh_token: 'refresh-token',
          expires_in: 3600,
        },
        user: {
          id: 'apple-user',
          email: 'player@example.com',
          role: 'authenticated',
          user_metadata: {},
        },
      },
      error: null,
    })
    prismaMock.user.create.mockRejectedValueOnce(new Error('db create failed'))

    const response = await postApple(
      makeNextRequest('http://localhost/api/auth/apple', {
        method: 'POST',
        body: JSON.stringify({ id_token: 'apple-token' }),
      }),
    )

    expect(response.status).toBe(500)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Failed to initialize account',
    })
    expect(supabaseClientMock.auth.admin.deleteUser).toHaveBeenCalledWith('apple-user')
  })

  it('returns 409 for Google sign-in when the OAuth email already belongs to another local account', async () => {
    supabaseClientMock.auth.signInWithIdToken.mockResolvedValue({
      data: {
        session: {
          access_token: 'access-token',
          refresh_token: 'refresh-token',
          expires_in: 3600,
        },
        user: {
          id: 'google-user',
          email: 'player@example.com',
          role: 'authenticated',
          user_metadata: { full_name: 'Player One' },
        },
      },
      error: null,
    })
    prismaMock.user.findUnique
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({ id: 'email-user' })

    const response = await postGoogle(
      makeNextRequest('http://localhost/api/auth/google', {
        method: 'POST',
        body: JSON.stringify({ id_token: 'google-token' }),
      }),
    )

    expect(response.status).toBe(409)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Email already registered with another account. Please log in and link Google from settings.',
    })
    expect(prismaMock.user.create).not.toHaveBeenCalled()
    expect(supabaseClientMock.auth.admin.deleteUser).toHaveBeenCalledWith('google-user')
  })

  it('returns 409 for Apple sign-in when the OAuth email already belongs to another local account', async () => {
    supabaseClientMock.auth.signInWithIdToken.mockResolvedValue({
      data: {
        session: {
          access_token: 'access-token',
          refresh_token: 'refresh-token',
          expires_in: 3600,
        },
        user: {
          id: 'apple-user',
          email: 'player@example.com',
          role: 'authenticated',
          user_metadata: {},
        },
      },
      error: null,
    })
    prismaMock.user.findUnique
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({ id: 'email-user' })

    const response = await postApple(
      makeNextRequest('http://localhost/api/auth/apple', {
        method: 'POST',
        body: JSON.stringify({ id_token: 'apple-token' }),
      }),
    )

    expect(response.status).toBe(409)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Email already registered with another account. Please log in and link Apple from settings.',
    })
    expect(prismaMock.user.create).not.toHaveBeenCalled()
    expect(supabaseClientMock.auth.admin.deleteUser).toHaveBeenCalledWith('apple-user')
  })

  it('still returns tokens when the local row already exists and only lastLogin update fails', async () => {
    supabaseClientMock.auth.signInWithIdToken.mockResolvedValue({
      data: {
        session: {
          access_token: 'access-token',
          refresh_token: 'refresh-token',
          expires_in: 3600,
        },
        user: {
          id: 'google-user',
          email: 'player@example.com',
          role: 'authenticated',
          user_metadata: { full_name: 'Player One' },
        },
      },
      error: null,
    })
    prismaMock.user.findUnique.mockResolvedValue({ id: 'google-user' })
    prismaMock.user.update.mockRejectedValueOnce(new Error('db update failed'))

    const response = await postGoogle(
      makeNextRequest('http://localhost/api/auth/google', {
        method: 'POST',
        body: JSON.stringify({ id_token: 'google-token' }),
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      access_token: 'access-token',
      refresh_token: 'refresh-token',
      user: {
        id: 'google-user',
        email: 'player@example.com',
      },
    })
    expect(prismaMock.user.create).not.toHaveBeenCalled()
  })
})
