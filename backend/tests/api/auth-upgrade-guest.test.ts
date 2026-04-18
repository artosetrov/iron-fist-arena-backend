import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockCreateAdminClient,
  mockRateLimit,
  prismaMock,
  supabaseClientMock,
  randomUUIDMock,
} = vi.hoisted(() => {
  const supabaseClientMock = {
    auth: {
      admin: {
        updateUserById: vi.fn(),
      },
      signInWithPassword: vi.fn(),
    },
  }

  return {
    mockGetAuthUser: vi.fn(),
    mockCreateAdminClient: vi.fn(() => supabaseClientMock),
    mockRateLimit: vi.fn(() => true),
    prismaMock: {
      user: {
        findUnique: vi.fn(),
        update: vi.fn(),
      },
    },
    supabaseClientMock,
    randomUUIDMock: vi.fn(() => 'revert-password-seed'),
  }
})

vi.mock('crypto', () => ({
  default: {
    randomUUID: randomUUIDMock,
  },
}))

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

import { POST } from '@/app/api/auth/upgrade-guest/route'

describe('POST /api/auth/upgrade-guest', () => {
  const originalSetTimeout = globalThis.setTimeout

  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'guest-user', role: 'authenticated' })
    mockRateLimit.mockResolvedValue(true)
    prismaMock.user.findUnique
      .mockResolvedValueOnce({ authProvider: 'anonymous', email: 'guest_legacy@guest.ironfist.local' })
      .mockResolvedValueOnce(null)
    supabaseClientMock.auth.admin.updateUserById.mockResolvedValue({ error: null })
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
    globalThis.setTimeout = ((handler: TimerHandler) => {
      if (typeof handler === 'function') {
        handler()
      }
      return 0 as ReturnType<typeof setTimeout>
    }) as typeof setTimeout
  })

  afterEach(() => {
    globalThis.setTimeout = originalSetTimeout
  })

  it('fully reverts Supabase guest identity if local upgrade persistence fails twice', async () => {
    prismaMock.user.update.mockRejectedValue(new Error('db write failed'))

    const response = await POST(
      makeNextRequest('http://localhost/api/auth/upgrade-guest', {
        method: 'POST',
        body: JSON.stringify({
          email: 'player@example.com',
          password: 'test123',
          username: 'player',
        }),
      }),
    )

    expect(response.status).toBe(500)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Failed to upgrade account. Please try again.',
    })
    expect(supabaseClientMock.auth.admin.updateUserById).toHaveBeenNthCalledWith(
      1,
      'guest-user',
      {
        email: 'player@example.com',
        password: 'test123',
        email_confirm: true,
        user_metadata: { is_guest: false, username: 'player' },
      },
    )
    expect(supabaseClientMock.auth.admin.updateUserById).toHaveBeenNthCalledWith(
      2,
      'guest-user',
      {
        email: 'guest_legacy@guest.ironfist.local',
        password: 'revert-password-seed',
        email_confirm: true,
        user_metadata: { is_guest: true, username: undefined },
      },
    )
    expect(supabaseClientMock.auth.signInWithPassword).not.toHaveBeenCalled()
  })
})
