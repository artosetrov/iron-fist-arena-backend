import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockCreateAdminClient,
  mockRateLimit,
  prismaMock,
  supabaseClientMock,
  randomUUIDMock,
} = vi.hoisted(() => {
  const supabaseClientMock = {
    auth: {
      admin: {
        createUser: vi.fn(),
        updateUserById: vi.fn(),
        deleteUser: vi.fn(),
      },
      signInWithPassword: vi.fn(),
    },
  }

  return {
    mockCreateAdminClient: vi.fn(() => supabaseClientMock),
    mockRateLimit: vi.fn(() => true),
    prismaMock: {
      user: {
        findUnique: vi.fn(),
        create: vi.fn(),
        delete: vi.fn(),
        update: vi.fn(),
      },
    },
    supabaseClientMock,
    randomUUIDMock: vi.fn(),
  }
})

vi.mock('crypto', () => ({
  default: {
    randomUUID: randomUUIDMock,
  },
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

import { POST } from '@/app/api/auth/guest-login/route'

describe('POST /api/auth/guest-login', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockRateLimit.mockResolvedValue(true)
    supabaseClientMock.auth.admin.createUser.mockResolvedValue({
      data: { user: { id: 'new-guest-user', role: 'authenticated' } },
      error: null,
    })
    supabaseClientMock.auth.admin.updateUserById.mockResolvedValue({ error: null })
    supabaseClientMock.auth.admin.deleteUser.mockResolvedValue({ error: null })
    supabaseClientMock.auth.signInWithPassword.mockResolvedValue({
      data: {
        session: {
          access_token: 'access-token',
          refresh_token: 'refresh-token',
          expires_in: 3600,
        },
      },
      error: null,
    })
    prismaMock.user.findUnique.mockResolvedValue(null)
    prismaMock.user.create.mockResolvedValue({})
    prismaMock.user.delete.mockResolvedValue({})
    prismaMock.user.update.mockResolvedValue({})
    randomUUIDMock
      .mockReturnValueOnce('guest-id-seed-1234')
      .mockReturnValueOnce('guest-password-seed-5678')
      .mockReturnValueOnce('restore-password-seed-9999')
  })

  it('deletes the fresh Supabase guest and restores the existing device-linked guest on a local create race', async () => {
    prismaMock.user.findUnique
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({
        id: 'existing-guest-user',
        authProvider: 'anonymous',
        email: 'guest_existing@guest.ironfist.local',
      })
    prismaMock.user.create.mockRejectedValueOnce(new Error('Unique constraint failed on deviceId'))

    const response = await POST(
      makeNextRequest('http://localhost/api/auth/guest-login', {
        method: 'POST',
        body: JSON.stringify({ device_id: 'device-12345678' }),
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      restored: true,
      user: {
        id: 'existing-guest-user',
        email: 'guest_existing@guest.ironfist.local',
        is_anonymous: true,
      },
    })
    expect(supabaseClientMock.auth.admin.deleteUser).toHaveBeenCalledWith('new-guest-user')
    expect(supabaseClientMock.auth.admin.updateUserById).toHaveBeenCalledWith(
      'existing-guest-user',
      { password: 'restore-password-seed-9999' },
    )
    expect(prismaMock.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'existing-guest-user' },
        data: { lastLogin: expect.any(Date) },
      }),
    )
  })

  it('returns 500 and deletes the fresh Supabase guest when local user creation fails without a device restore path', async () => {
    prismaMock.user.create.mockRejectedValueOnce(new Error('db create failed'))

    const response = await POST(
      makeNextRequest('http://localhost/api/auth/guest-login', {
        method: 'POST',
        body: JSON.stringify({}),
      }),
    )

    expect(response.status).toBe(500)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Failed to create guest account',
    })
    expect(supabaseClientMock.auth.admin.deleteUser).toHaveBeenCalledWith('new-guest-user')
    expect(supabaseClientMock.auth.signInWithPassword).not.toHaveBeenCalled()
  })

  it('deletes the fresh local user row if guest sign-in fails after local creation', async () => {
    supabaseClientMock.auth.signInWithPassword.mockResolvedValueOnce({
      data: { session: null },
      error: { message: 'sign in failed' },
    })

    const response = await POST(
      makeNextRequest('http://localhost/api/auth/guest-login', {
        method: 'POST',
        body: JSON.stringify({}),
      }),
    )

    expect(response.status).toBe(500)
    await expect(response.json()).resolves.toMatchObject({
      error: 'sign in failed',
    })
    expect(supabaseClientMock.auth.admin.deleteUser).toHaveBeenCalledWith('new-guest-user')
    expect(prismaMock.user.delete).toHaveBeenCalledWith({
      where: { id: 'new-guest-user' },
    })
  })
})
