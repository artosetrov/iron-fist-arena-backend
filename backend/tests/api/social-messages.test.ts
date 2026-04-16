import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  prismaMock: {
    character: {
      findUnique: vi.fn(),
    },
    friendship: {
      findFirst: vi.fn(),
    },
    $transaction: vi.fn(),
  },
}))

vi.mock('@/lib/auth', () => ({
  getAuthUser: mockGetAuthUser,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

import { POST } from '@/app/api/social/messages/route'

type SocialMessagesTx = {
  $queryRawUnsafe: ReturnType<typeof vi.fn>
  directMessage: {
    count: ReturnType<typeof vi.fn>
    findFirst: ReturnType<typeof vi.fn>
    create: ReturnType<typeof vi.fn>
  }
}

function mockTransaction(tx: SocialMessagesTx) {
  prismaMock.$transaction.mockImplementation(
    async (callback: (innerTx: SocialMessagesTx) => Promise<unknown>) => callback(tx),
  )
}

describe('POST /api/social/messages', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    prismaMock.character.findUnique
      .mockResolvedValueOnce({ id: 'char-1', userId: 'user-1' })
      .mockResolvedValueOnce({ id: 'char-2', characterName: 'Target' })
    prismaMock.friendship.findFirst.mockResolvedValue(null)
  })

  it('rejects send when the sender already hit the daily limit inside the locked transaction', async () => {
    const tx = {
      $queryRawUnsafe: vi.fn(async () => [{ id: 'char-1' }]),
      directMessage: {
        count: vi.fn(async () => 50),
        findFirst: vi.fn(async () => null),
        create: vi.fn(),
      },
    }
    mockTransaction(tx)

    const response = await POST(
      makeNextRequest('http://localhost/api/social/messages', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
          action: 'send',
          target_id: 'char-2',
          content: 'Hello',
        }),
      }),
    )

    expect(response.status).toBe(429)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Daily message limit reached (50)',
    })
    expect(tx.directMessage.create).not.toHaveBeenCalled()
  })

  it('creates the message through the locked transaction when guards pass', async () => {
    const now = new Date('2026-04-15T17:30:00.000Z')
    const tx = {
      $queryRawUnsafe: vi.fn(async () => [{ id: 'char-1' }]),
      directMessage: {
        count: vi.fn(async () => 3),
        findFirst: vi.fn(async () => new Date(now.getTime() - 10_000) && {
          createdAt: new Date(now.getTime() - 10_000),
        }),
        create: vi.fn(async ({ data }) => ({
          id: 'msg-1',
          ...data,
          isRead: false,
          createdAt: now,
          updatedAt: now,
        })),
      },
    }
    mockTransaction(tx)

    const response = await POST(
      makeNextRequest('http://localhost/api/social/messages', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
          action: 'send',
          target_id: 'char-2',
          content: 'Hello',
        }),
      }),
    )

    expect(response.status).toBe(200)
    expect(tx.$queryRawUnsafe).toHaveBeenCalled()
    expect(tx.directMessage.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        senderId: 'char-1',
        receiverId: 'char-2',
        content: 'Hello',
        isQuick: false,
      }),
    })
    await expect(response.json()).resolves.toMatchObject({
      message: {
        id: 'msg-1',
        content: 'Hello',
      },
    })
  })
})
