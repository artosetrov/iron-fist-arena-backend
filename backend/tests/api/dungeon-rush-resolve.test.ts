import { beforeEach, describe, expect, it, vi } from 'vitest'

const { mockGetAuthUser, mockRateLimit, prismaMock } = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
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
  BATTLE_PASS: {
    BP_XP_PER_PVP: 20,
    BP_XP_PER_DUNGEON_FLOOR: 30,
    BP_XP_PER_QUEST: 50,
    BP_XP_PER_ACHIEVEMENT: 100,
  },
  chaGoldBonus: (value: number) => value,
}))

import { POST } from '@/app/api/dungeon-rush/resolve/route'

describe('POST /api/dungeon-rush/resolve', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
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

    const playerState = {
      gold: 500,
      xp: 0,
    }

    prismaMock.character.findFirst.mockResolvedValue({
      id: 'char-1',
      cha: 10,
      gold: playerState.gold,
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
        update: vi.fn(async ({ data }: { data: { gold?: { increment: number }; currentXp?: { increment: number } } }) => {
          playerState.gold += data.gold?.increment ?? 0
          playerState.xp += data.currentXp?.increment ?? 0
          return { id: 'char-1' }
        }),
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

    prismaMock.$transaction.mockImplementation(async (callback: (innerTx: typeof tx) => Promise<unknown>) => callback(tx))

    const request = new Request('http://localhost/api/dungeon-rush/resolve', {
      method: 'POST',
      body: JSON.stringify({
        character_id: 'char-1',
        run_id: 'run-1',
      }),
    }) as any

    const firstResponse = await POST(request)
    expect(firstResponse.status).toBe(200)
    expect(playerState.gold).toBeGreaterThan(500)
    expect(liveRun.state.currentRoomIndex).toBe(1)

    const secondResponse = await POST(
      new Request('http://localhost/api/dungeon-rush/resolve', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
          run_id: 'run-1',
        }),
      }) as any,
    )

    expect(secondResponse.status).toBe(409)
    await expect(secondResponse.json()).resolves.toMatchObject({
      error: 'This dungeon rush room was already resolved. Refresh and continue.',
    })
    expect(playerState.gold).toBeGreaterThan(500)
    expect(tx.character.update).toHaveBeenCalledTimes(1)
  })
})
