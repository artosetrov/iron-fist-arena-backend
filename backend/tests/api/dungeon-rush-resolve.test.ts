import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockIncrementGuildChallenge,
  mockGoldBonusMultiplier,
  mockGrantRewardEntries,
  mockInvalidatePassiveCache,
  mockInvalidateSkillCache,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  mockIncrementGuildChallenge: vi.fn(async () => undefined),
  mockGoldBonusMultiplier: vi.fn(() => 1),
  mockGrantRewardEntries: vi.fn(),
  mockInvalidatePassiveCache: vi.fn(),
  mockInvalidateSkillCache: vi.fn(),
  prismaMock: {
    character: {
      findFirst: vi.fn(),
    },
    dungeonRun: {
      findFirst: vi.fn(),
      delete: vi.fn(),
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

vi.mock('@/lib/game/balance', () => ({
  chaGoldBonus: (value: number) => value,
}))

vi.mock('@/lib/game/guild-challenge', () => ({
  incrementGuildChallenge: mockIncrementGuildChallenge,
}))

vi.mock('@/lib/game/reward-grants', () => ({
  grantRewardEntries: mockGrantRewardEntries,
}))

vi.mock('@/lib/game/combat-loader', () => ({
  invalidatePassiveCache: mockInvalidatePassiveCache,
  invalidateSkillCache: mockInvalidateSkillCache,
}))

vi.mock('@/lib/game/premium', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@/lib/game/premium')>()
  return {
    ...actual,
    goldBonusMultiplier: mockGoldBonusMultiplier,
  }
})

import { POST } from '@/app/api/dungeon-rush/resolve/route'

describe('POST /api/dungeon-rush/resolve', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockGoldBonusMultiplier.mockReturnValue(1)
    mockGrantRewardEntries.mockResolvedValue({
      gold: 650,
      gems: 0,
      xp: 0,
      levelUpResult: {
        leveledUp: false,
        newLevel: 1,
        remainingXp: 0,
        statPointsAwarded: 0,
        passivePointsAwarded: 0,
      },
    })
  })

  it('rejects stale room resolves after the room has already been consumed under lock', async () => {
    const staleState = {
      rooms: [
        { index: 0, type: 'treasure', resolved: false, seed: 11 },
        { index: 1, type: 'event', resolved: false, seed: 22 },
      ],
      currentRoomIndex: 0,
      buffs: [],
      currentHpPercent: 100,
      shopPurchased: [],
      floorsCleared: 0,
      totalGoldEarned: 0,
      totalXpEarned: 0,
    }

    const liveRun = {
      id: 'run-1',
      characterId: 'char-1',
      difficulty: 'rush',
      currentFloor: 1,
      state: structuredClone(staleState),
    }

    prismaMock.character.findFirst.mockResolvedValue({
      id: 'char-1',
      cha: 10,
      // Keep this aligned with the shared premium selector contract.
      user: { premiumUntil: null, premiumSubscription: null },
    })

    // Always return the original unresolved snapshot to simulate a retried request
    // hitting stale pre-transaction state.
    prismaMock.dungeonRun.findFirst.mockImplementation(async () => ({
      id: 'run-1',
      characterId: 'char-1',
      difficulty: 'rush',
      currentFloor: 1,
      state: structuredClone(staleState),
    }))

    const tx = {
      // Called via `lockDungeonRunForUpdate(tx, runId)` helper.
      $queryRaw: vi.fn(async () => []),
      $queryRawUnsafe: vi.fn(async () => [
        {
          id: liveRun.id,
          characterId: liveRun.characterId,
          dungeonId: 'training_camp',
          difficulty: liveRun.difficulty,
          currentFloor: liveRun.currentFloor,
          state: structuredClone(liveRun.state),
        },
      ]),
      character: {
        findUnique: vi.fn(async () => ({
          inventorySlots: 20,
          currentXp: 0,
          level: 1,
        })),
        update: vi.fn(async () => ({ id: 'char-1' })),
      },
      user: {
        findUnique: vi.fn(async () => ({
          gold: 500,
          gems: 0,
        })),
        update: vi.fn(async () => ({ id: 'user-1', gold: 500 })),
      },
      dungeonRun: {
        delete: vi.fn(),
        update: vi.fn(async ({ data }: { data: { currentFloor: number; state: typeof liveRun.state } }) => {
          liveRun.currentFloor = data.currentFloor
          liveRun.state = structuredClone(data.state)
          return { id: liveRun.id }
        }),
      },
    }

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: typeof tx) => Promise<unknown>) => callback(tx),
    )

    const request = makeNextRequest('http://localhost/api/dungeon-rush/resolve', {
      method: 'POST',
      body: JSON.stringify({
        character_id: 'char-1',
        run_id: 'run-1',
      }),
    })

    const firstResponse = await POST(request)
    expect(firstResponse.status).toBe(200)
    expect(liveRun.state.currentRoomIndex).toBe(1)
    expect(mockGrantRewardEntries).toHaveBeenCalledTimes(1)

    const secondResponse = await POST(
      makeNextRequest('http://localhost/api/dungeon-rush/resolve', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
          run_id: 'run-1',
        }),
      }),
    )

    expect(secondResponse.status).toBe(409)
    await expect(secondResponse.json()).resolves.toMatchObject({
      error: 'This dungeon rush room was already resolved. Refresh and continue.',
    })
    expect(mockGrantRewardEntries).toHaveBeenCalledTimes(1)
  })

  it('invalidates combat caches after a leveled-up room reward grant', async () => {
    mockGrantRewardEntries.mockResolvedValue({
      gold: 650,
      gems: 0,
      xp: 120,
      levelUpResult: {
        leveledUp: true,
        newLevel: 2,
        remainingXp: 20,
        statPointsAwarded: 5,
        passivePointsAwarded: 1,
      },
    })

    const liveRun = {
      id: 'run-1',
      characterId: 'char-1',
      difficulty: 'rush',
      currentFloor: 1,
      state: {
        rooms: [
          { index: 0, type: 'treasure', resolved: false, seed: 11 },
          { index: 1, type: 'event', resolved: false, seed: 22 },
        ],
        currentRoomIndex: 0,
        buffs: [],
        currentHpPercent: 100,
        shopPurchased: [],
        floorsCleared: 0,
        totalGoldEarned: 0,
        totalXpEarned: 0,
        artifacts: [],
      },
    }

    prismaMock.character.findFirst.mockResolvedValue({
      id: 'char-1',
      cha: 10,
      user: { premiumUntil: null, premiumSubscription: null },
    })
    prismaMock.dungeonRun.findFirst.mockResolvedValue(structuredClone(liveRun))

    const tx = {
      $queryRaw: vi.fn(async () => []),
      $queryRawUnsafe: vi.fn(async () => [
        {
          id: liveRun.id,
          characterId: liveRun.characterId,
          dungeonId: 'training_camp',
          difficulty: liveRun.difficulty,
          currentFloor: liveRun.currentFloor,
          state: structuredClone(liveRun.state),
        },
      ]),
      dungeonRun: {
        delete: vi.fn(),
        update: vi.fn(async () => ({ id: liveRun.id })),
      },
    }

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: typeof tx) => Promise<unknown>) => callback(tx),
    )

    const response = await POST(
      makeNextRequest('http://localhost/api/dungeon-rush/resolve', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
          run_id: 'run-1',
        }),
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      rushComplete: false,
      leveled_up: true,
      new_level: 2,
      stat_points_awarded: 5,
    })
    expect(mockGrantRewardEntries).toHaveBeenCalledWith(tx, {
      userId: 'user-1',
      characterId: 'char-1',
      rewards: expect.arrayContaining([
        expect.objectContaining({ type: 'gold' }),
      ]),
    })
    expect(mockIncrementGuildChallenge).toHaveBeenCalledWith(
      prismaMock,
      'gold_earned',
      expect.any(Number),
    )
    expect(mockInvalidateSkillCache).toHaveBeenCalledWith('char-1')
    expect(mockInvalidatePassiveCache).toHaveBeenCalledWith('char-1')
  })
})
