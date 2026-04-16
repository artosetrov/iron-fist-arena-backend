import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockRateLimit,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  prismaMock: {
    character: {
      findUnique: vi.fn(),
    },
    mailRecipient: {
      count: vi.fn(),
      findMany: vi.fn(),
    },
  },
}))

vi.mock('@/lib/auth', () => ({
  getAuthUser: mockGetAuthUser,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

vi.mock('@/lib/rate-limit', () => ({
  rateLimit: mockRateLimit,
}))

import { GET } from '@/app/api/mail/route'

describe('GET /api/mail', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
    prismaMock.character.findUnique.mockResolvedValue({ id: 'char-1', userId: 'user-1' })
    prismaMock.mailRecipient.count.mockResolvedValue(1)
    prismaMock.mailRecipient.findMany.mockResolvedValue([
      {
        id: 'recipient-1',
        messageId: 'message-1',
        isRead: false,
        isClaimed: false,
        readAt: null,
        claimedAt: null,
        createdAt: new Date('2026-04-15T10:00:00.000Z'),
        message: {
          id: 'message-1',
          subject: 'Welcome',
          body: 'Hello there',
          senderType: 'system',
          senderName: 'System',
          attachments: null,
          expiresAt: null,
          createdAt: new Date('2026-04-15T10:00:00.000Z'),
        },
      },
    ])
  })

  it('uses a one-minute rate-limit window and returns the inbox payload', async () => {
    const response = await GET(
      makeNextRequest('http://localhost/api/mail?character_id=char-1&page=1&limit=20'),
    )

    expect(response.status).toBe(200)
    expect(mockRateLimit).toHaveBeenCalledWith('mail:list:user-1', 30, 60_000)
    await expect(response.json()).resolves.toMatchObject({
      total: 1,
      page: 1,
      limit: 20,
      unread_count: 1,
      messages: [
        {
          id: 'recipient-1',
          messageId: 'message-1',
          subject: 'Welcome',
          body: 'Hello there',
        },
      ],
    })
  })
})
