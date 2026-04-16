import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockUpdateDailyQuestProgress,
  mockUpdateWeeklyChallengeProgress,
  mockUpdateTutorialQuestProgress,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  mockUpdateDailyQuestProgress: vi.fn(),
  mockUpdateWeeklyChallengeProgress: vi.fn(),
  mockUpdateTutorialQuestProgress: vi.fn(),
  prismaMock: {
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

vi.mock('@/lib/game/tutorial', () => ({
  updateTutorialQuestProgress: mockUpdateTutorialQuestProgress,
}))

import { POST } from '@/app/api/minigames/shell-game/guess/route'

function makeTx(options?: {
  sessionRow?: {
    id: string
    character_id: string
    status: string
    secret_data: unknown
    bet_amount: number
  } | null
  character?: { userId: string } | null
  userGold?: number
  updatedGold?: number
}) {
  const {
    sessionRow = {
      id: 'session-1',
      character_id: 'char-1',
      status: 'active',
      secret_data: { correctShell: 2 },
      bet_amount: 100,
    },
    character = { userId: 'user-1' },
    userGold = 150,
    updatedGold = 350,
  } = options ?? {}

  return {
    $queryRawUnsafe: vi.fn(async () => (sessionRow ? [sessionRow] : [])),
    character: {
      findUnique: vi.fn(async () => character),
    },
    minigameSession: {
      update: vi.fn(async () => ({})),
    },
    user: {
      findUnique: vi.fn(async () => ({ gold: userGold })),
      update: vi.fn(async () => ({ gold: updatedGold })),
    },
  }
}

type ShellGameGuessTx = ReturnType<typeof makeTx>

function mockTransaction(tx: ShellGameGuessTx) {
  prismaMock.$transaction.mockImplementation(
    async (callback: (innerTx: ShellGameGuessTx) => Promise<unknown>) => callback(tx),
  )
}

describe('POST /api/minigames/shell-game/guess', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
    mockUpdateDailyQuestProgress.mockResolvedValue(undefined)
    mockUpdateWeeklyChallengeProgress.mockResolvedValue(undefined)
    mockUpdateTutorialQuestProgress.mockResolvedValue(undefined)
  })

  it('returns the win payload and gold after a successful locked guess', async () => {
    const tx = makeTx()
    mockTransaction(tx)

    const response = await POST(
      makeNextRequest('http://localhost/api/minigames/shell-game/guess', {
        method: 'POST',
        body: JSON.stringify({ session_id: 'session-1', chosen_cup: 2 }),
      }),
    )

    expect(response.status).toBe(200)
    expect(tx.minigameSession.update).toHaveBeenCalledWith({
      where: { id: 'session-1' },
      data: {
        status: 'completed',
        result: { won: true, chosen_cup: 2, correctShell: 2, win_amount: 200 },
      },
    })
    expect(tx.user.update).toHaveBeenCalledWith({
      where: { id: 'user-1' },
      data: { gold: { increment: 200 } },
      select: { gold: true },
    })
    await expect(response.json()).resolves.toMatchObject({
      won: true,
      winning_cup: 2,
      win_amount: 200,
      gold: 350,
    })
  })

  it('returns 400 when the locked session is no longer active', async () => {
    const tx = makeTx({
      sessionRow: {
        id: 'session-1',
        character_id: 'char-1',
        status: 'completed',
        secret_data: { correctShell: 2 },
        bet_amount: 100,
      },
    })
    mockTransaction(tx)

    const response = await POST(
      makeNextRequest('http://localhost/api/minigames/shell-game/guess', {
        method: 'POST',
        body: JSON.stringify({ session_id: 'session-1', chosen_cup: 2 }),
      }),
    )

    expect(response.status).toBe(400)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Session is no longer active',
    })
  })

  it('returns 500 when the session secret payload is corrupted', async () => {
    const tx = makeTx({
      sessionRow: {
        id: 'session-1',
        character_id: 'char-1',
        status: 'active',
        secret_data: { correctShell: 'broken' },
        bet_amount: 100,
      },
    })
    mockTransaction(tx)

    const response = await POST(
      makeNextRequest('http://localhost/api/minigames/shell-game/guess', {
        method: 'POST',
        body: JSON.stringify({ session_id: 'session-1', chosen_cup: 1 }),
      }),
    )

    expect(response.status).toBe(500)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Session state is invalid',
    })
    expect(tx.minigameSession.update).not.toHaveBeenCalled()
    expect(tx.user.update).not.toHaveBeenCalled()
  })
})
