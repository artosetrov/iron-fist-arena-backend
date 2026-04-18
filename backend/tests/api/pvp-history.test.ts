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
    pvpMatch: {
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

import { GET } from '@/app/api/pvp/history/route'

describe('GET /api/pvp/history', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    prismaMock.character.findUnique.mockResolvedValue({ userId: 'user-1' })
    prismaMock.pvpMatch.findMany.mockResolvedValue([])
  })

  it('skips history rows whose opponent relation is missing instead of crashing the whole response', async () => {
    prismaMock.pvpMatch.findMany.mockResolvedValueOnce([
      {
        id: 'match-bot',
        player1Id: 'char-1',
        player2Id: null,
        player1RatingBefore: 1000,
        player1RatingAfter: 1010,
        player2RatingBefore: 0,
        player2RatingAfter: 0,
        winnerId: 'char-1',
        goldReward: 10,
        xpReward: 20,
        turnsTaken: 5,
        matchType: 'bot',
        isRevenge: false,
        playedAt: new Date('2026-04-18T10:00:00.000Z'),
        player1: {
          id: 'char-1',
          characterName: 'Hero',
          class: 'warrior',
          level: 10,
        },
        player2: null,
      },
      {
        id: 'match-pvp',
        player1Id: 'char-1',
        player2Id: 'char-2',
        player1RatingBefore: 1010,
        player1RatingAfter: 1020,
        player2RatingBefore: 990,
        player2RatingAfter: 980,
        winnerId: 'char-1',
        goldReward: 15,
        xpReward: 25,
        turnsTaken: 6,
        matchType: 'ranked',
        isRevenge: false,
        playedAt: new Date('2026-04-18T11:00:00.000Z'),
        player1: {
          id: 'char-1',
          characterName: 'Hero',
          class: 'warrior',
          level: 10,
        },
        player2: {
          id: 'char-2',
          characterName: 'Villain',
          class: 'mage',
          level: 11,
        },
      },
    ])

    const response = await GET(
      makeNextRequest('http://localhost/api/pvp/history?character_id=char-1'),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      total: 1,
      history: [
        {
          matchId: 'match-pvp',
          opponent: {
            id: 'char-2',
            name: 'Villain',
          },
        },
      ],
    })
  })
})
