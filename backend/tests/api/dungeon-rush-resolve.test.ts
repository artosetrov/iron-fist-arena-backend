import { beforeEach, describe, expect, it, vi } from 'vitest'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockGetBattlePassConfig,
  mockIncrementGuildChallenge,
  mockGoldBonusMultiplier,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  mockGetBattlePassConfig: vi.fn(async () => ({
    BP_XP_PER_PVP: 20,
    BP_XP_PER_DUNGEON_FLOOR: 30,
    BP_XP_PER_QUEST: 50,
    BP_XP_PER_ACHIEVEMENT: 100,
  })),
  mockIncrementGuildChallenge: vi.fn(async () => undefined),
  mockGoldBonusMultiplier: vi.fn(() => 1),
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

vi.mock('@/lib/game/live-config', () => ({
  getBattlePassConfig: mockGetBattlePassConfig,
}))

vi.mock('@/lib/game/guild-challenge', () => ({
  incrementGuildChallenge: mockIncrementGuildChallenge,
}))

vi.mock('@/lib/game/premium', () => ({
  PREMIUM_ENTITLEMENT_USER_SELECT: {
    premiumUntil: true,
    premiumSubscription: {
      select: {
        expiresAt: true,
        status: true,
      },
    },
  },
  goldBonusMultiplier: mockGoldBonusMultiplier,
}))

import { POST } from '@/app/api/dungeon-rush/resolve/route'

describe('POST /api/dungeon-rush/resolve', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockGoldBonusMultiplier.mockReturnValue(1)
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

    // Account-level gold moved from Character → User in the
    // `20260409_migrate_gold_to_account_level` migration. The route now writes
    // to `tx.user.update` instead of `tx.character.update` for gold.
    const playerState = {
      gold: 500,
      xp: 0,
    }

    prismaMock.character.findFirst.mockResolvedValue({
      id: 'char-1',
      cha: 10,
      // W3.D5 — route selects `user: { select: { premiumUntil: true } }`
      // to feed into `goldBonusMultiplier`.
      user: { premiumUntil: null },
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
          currentXp: playerState.xp,
          level: 1,
        })),
        update: vi.fn(async ({ data }: { data: { currentXp?: { increment: number } } }) => {
          playerState.xp += data.currentXp?.increment ?? 0
          return { id: 'char-1' }
        }),
      },
      user: {
        findUnique: vi.fn(async () => ({
          gold: playerState.gold,
          gems: 0,
        })),
        update: vi.fn(async ({ data }: { data: { gold?: { increment: number } } }) => {
          playerState.gold += data.gold?.increment ?? 0
          return { id: 'user-1', gold: playerState.gold }
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

    prismaMock.$transaction.mockImplementation(async (callback: any) => callback(tx))

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
    expect(tx.user.update).toHaveBeenCalledTimes(1)

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
    // Gold was incremented exactly once despite two resolve attempts.
    expect(tx.user.update).toHaveBeenCalledTimes(1)
  })
})
