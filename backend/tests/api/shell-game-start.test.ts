import { beforeEach, describe, expect, it, vi } from 'vitest'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockUpdateDailyQuestProgress,
  mockUpdateWeeklyChallengeProgress,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  mockUpdateDailyQuestProgress: vi.fn(),
  mockUpdateWeeklyChallengeProgress: vi.fn(),
  prismaMock: {
    character: {
      findUnique: vi.fn(),
    },
    minigameSession: {
      count: vi.fn(),
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

vi.mock('@/lib/rate-limit', () => ({
  rateLimit: mockRateLimit,
}))

vi.mock('@/lib/game/daily-quests', () => ({
  updateDailyQuestProgress: mockUpdateDailyQuestProgress,
}))

vi.mock('@/lib/game/weekly-challenges', () => ({
  updateWeeklyChallengeProgress: mockUpdateWeeklyChallengeProgress,
}))

import { POST } from '@/app/api/minigames/shell-game/start/route'

describe('POST /api/minigames/shell-game/start', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
    mockUpdateDailyQuestProgress.mockResolvedValue(undefined)
    mockUpdateWeeklyChallengeProgress.mockResolvedValue(undefined)
    prismaMock.character.findUnique.mockResolvedValue({ id: 'char-1', userId: 'user-1' })
    prismaMock.minigameSession.count.mockResolvedValue(3)
  })

  it('creates an active session without revealing the winning cup', async () => {
    const tx = {
      $queryRaw: vi.fn(async () => [{ gold: 500 }]),
      user: {
        update: vi.fn(),
      },
      minigameSession: {
        create: vi.fn(async ({ data }) => ({
          id: 'shell-session-1',
          betAmount: data.betAmount,
          secretData: data.secretData,
        })),
      },
    }

    prismaMock.$transaction.mockImplementation(async (callback: any) => callback(tx))

    const response = await POST(
      new Request('http://localhost/api/minigames/shell-game/start', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1', bet_amount: 100 }),
      }) as any,
    )

    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data).toMatchObject({
      session_id: 'shell-session-1',
      bet_amount: 100,
      plays_remaining: 16,
      plays_limit: 20,
    })
    expect(data).not.toHaveProperty('winning_cup')
    expect(tx.minigameSession.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        characterId: 'char-1',
        gameType: 'shell_game',
        betAmount: 100,
        status: 'active',
        secretData: {
          correctShell: expect.any(Number),
        },
      }),
    })
    const createdSecret = tx.minigameSession.create.mock.calls[0][0].data.secretData.correctShell
    expect(createdSecret).toBeGreaterThanOrEqual(0)
    expect(createdSecret).toBeLessThanOrEqual(2)
    expect(tx.user.update).toHaveBeenCalledWith({
      where: { id: 'user-1' },
      data: { gold: { decrement: 100 } },
    })
  })
})
