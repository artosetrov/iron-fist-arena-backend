import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockCreateClient,
  mockRateLimit,
  supabaseClientMock,
} = vi.hoisted(() => {
  const supabaseClientMock = {
    auth: {
      resetPasswordForEmail: vi.fn(),
    },
  }

  return {
    mockCreateClient: vi.fn(() => supabaseClientMock),
    mockRateLimit: vi.fn(() => true),
    supabaseClientMock,
  }
})

vi.mock('@supabase/supabase-js', () => ({
  createClient: mockCreateClient,
}))

vi.mock('@/lib/rate-limit', () => ({
  rateLimit: mockRateLimit,
}))

import { POST } from '@/app/api/auth/forgot-password/route'

describe('POST /api/auth/forgot-password', () => {
  const originalAppUrl = process.env.NEXT_PUBLIC_APP_URL

  beforeEach(() => {
    vi.clearAllMocks()
    mockRateLimit.mockResolvedValue(true)
    supabaseClientMock.auth.resetPasswordForEmail.mockResolvedValue({ error: null })
    delete process.env.NEXT_PUBLIC_APP_URL
  })

  afterAll(() => {
    if (originalAppUrl === undefined) {
      delete process.env.NEXT_PUBLIC_APP_URL
      return
    }
    process.env.NEXT_PUBLIC_APP_URL = originalAppUrl
  })

  it('uses the canonical production backend host when NEXT_PUBLIC_APP_URL is unset', async () => {
    const response = await POST(
      makeNextRequest('http://localhost/api/auth/forgot-password', {
        method: 'POST',
        body: JSON.stringify({ email: 'player@example.com' }),
      }),
    )

    expect(response.status).toBe(200)
    expect(supabaseClientMock.auth.resetPasswordForEmail).toHaveBeenCalledWith(
      'player@example.com',
      {
        redirectTo: 'https://api.hexboundapp.com/reset-password',
      },
    )
  })

  it('respects NEXT_PUBLIC_APP_URL and trims a trailing slash', async () => {
    process.env.NEXT_PUBLIC_APP_URL = 'https://staging.hexboundapp.com/'

    const response = await POST(
      makeNextRequest('http://localhost/api/auth/forgot-password', {
        method: 'POST',
        body: JSON.stringify({ email: 'player@example.com' }),
      }),
    )

    expect(response.status).toBe(200)
    expect(supabaseClientMock.auth.resetPasswordForEmail).toHaveBeenCalledWith(
      'player@example.com',
      {
        redirectTo: 'https://staging.hexboundapp.com/reset-password',
      },
    )
  })
})
