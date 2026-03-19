import { beforeEach, describe, expect, it, vi } from 'vitest'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockInitCombatConfig,
  mockRunCombat,
  mockLoadCombatCharacter,
  mockGetKFactor,
  mockCalculateCurrentStamina,
  mockRollAndPersistLoot,
  mockApplyLevelUp,
  mockUpdateDailyQuestProgress,
  mockAwardBattlePassXp,
  mockDegradeEquipment,
  mockCacheDeletePrefix,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  mockInitCombatConfig: vi.fn(),
  mockRunCombat: vi.fn(),
  mockLoadCombatCharacter: vi.fn(),
  mockGetKFactor: vi.fn(() => 32),
  mockCalculateCurrentStamina: vi.fn(),
  mockRollAndPersistLoot: vi.fn(),
  mockApplyLevelUp: vi.fn(),
  mockUpdateDailyQuestProgress: vi.fn(),
  mockAwardBattlePassXp: vi.fn(),
  mockDegradeEquipment: vi.fn(),
  mockCacheDeletePrefix: vi.fn(),
  prismaMock: {
    character: {
      findUnique: vi.fn(),
    },
    revengeQueue: {
      findUnique: vi.fn(),
      create: vi.fn(),
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

vi.mock('@/lib/game/combat', () => ({
  initCombatConfig: mockInitCombatConfig,
  runCombat: mockRunCombat,
}))

vi.mock('@/lib/game/combat-loader', () => ({
  loadCombatCharacter: mockLoadCombatCharacter,
}))

vi.mock('@/lib/game/elo', () => ({
  getKFactor: mockGetKFactor,
}))

vi.mock('@/lib/game/stamina', () => ({
  calculateCurrentStamina: mockCalculateCurrentStamina,
}))

vi.mock('@/lib/game/loot', () => ({
  rollAndPersistLoot: mockRollAndPersistLoot,
}))

vi.mock('@/lib/game/balance', () => ({
  STAMINA: { FREE_PVP_PER_DAY: 3, PVP_COST: 10 },
  GOLD_REWARDS: {
    PVP_WIN_BASE: 50,
    PVP_LOSS_BASE: 10,
    REVENGE_MULTIPLIER: 1.5,
  },
  XP_REWARDS: {
    PVP_WIN_XP: 20,
    PVP_LOSS_XP: 5,
  },
  FIRST_WIN_BONUS: {
    GOLD_MULT: 2,
    XP_MULT: 2,
  },
  BATTLE_PASS: {
    BP_XP_PER_PVP: 20,
  },
  chaGoldBonus: (value: number) => value,
  streakGoldMultiplier: () => 0,
  levelScaledReward: (value: number) => value,
}))

vi.mock('@/lib/game/progression', () => ({
  applyLevelUp: mockApplyLevelUp,
}))

vi.mock('@/lib/game/daily-quests', () => ({
  updateDailyQuestProgress: mockUpdateDailyQuestProgress,
}))

vi.mock('@/lib/game/battle-pass', () => ({
  awardBattlePassXp: mockAwardBattlePassXp,
}))

vi.mock('@/lib/game/durability', () => ({
  degradeEquipment: mockDegradeEquipment,
}))

vi.mock('@/lib/cache', () => ({
  cacheDeletePrefix: mockCacheDeletePrefix,
  cacheGet: vi.fn().mockResolvedValue(null),
  cacheSet: vi.fn().mockResolvedValue(undefined),
}))

vi.mock('@/lib/game/config', () => ({
  getGameConfig: vi.fn(async (_key: string, fallback: unknown) => fallback),
  getGameConfigs: vi.fn(async (keys: Record<string, unknown>) => keys),
}))

import { POST } from '@/app/api/pvp/resolve/route'

describe('POST /api/pvp/resolve', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockCalculateCurrentStamina.mockReturnValue({ stamina: 120, updated: false })
    mockLoadCombatCharacter
      .mockResolvedValueOnce({ id: 'char-1', maxHp: 100 })
      .mockResolvedValueOnce({ id: 'char-2', maxHp: 100 })
    mockRunCombat.mockReturnValue({
      winnerId: 'char-1',
      loserId: 'char-2',
      totalTurns: 3,
      turns: [],
      finalHp: {
        'char-1': 88,
        'char-2': 0,
      },
    })
    mockApplyLevelUp.mockResolvedValue({
      leveledUp: false,
      newLevel: 10,
      remainingXp: 0,
      statPointsAwarded: 0,
      passivePointsAwarded: 0,
    })
    mockUpdateDailyQuestProgress.mockResolvedValue(undefined)
    mockAwardBattlePassXp.mockResolvedValue(undefined)
    mockRollAndPersistLoot.mockResolvedValue(null)
    mockDegradeEquipment.mockResolvedValue({ degraded: [], anyBroken: false })

    prismaMock.revengeQueue.findUnique.mockResolvedValue(null)
    prismaMock.revengeQueue.create.mockResolvedValue({ id: 'revenge-1' })

    const attacker = {
      id: 'char-1',
      userId: 'user-1',
      currentStamina: 120,
      maxStamina: 120,
      lastStaminaUpdate: new Date('2026-03-12T00:00:00.000Z'),
      pvpRating: 1000,
      pvpCalibrationGames: 0,
      freePvpToday: 0,
      freePvpDate: null,
      firstWinToday: false,
      firstWinDate: null,
      highestPvpRank: 1000,
      cha: 10,
      level: 10,
      luk: 10,
      characterName: 'Hero',
      class: 'warrior',
      origin: 'human',
      gold: 100,
      maxHp: 100,
      pvpWins: 0,
      pvpLosses: 0,
      pvpWinStreak: 0,
      pvpLossStreak: 0,
    }

    const defender = {
      ...attacker,
      id: 'char-2',
      userId: 'user-2',
      characterName: 'Villain',
    }

    prismaMock.character.findUnique.mockImplementation(async ({ where }: { where: { id: string } }) => {
      if (where.id === 'char-1') return attacker
      if (where.id === 'char-2') return defender
      return null
    })
  })

  it('consumes a battle ticket exactly once and rejects replayed resolve requests', async () => {
    const battleState = {
      ticketConsumed: false,
      matchCount: 0,
    }

    const tx = {
      $queryRawUnsafe: vi.fn(async () => [
        {
          id: 'ticket-1',
          character_id: 'char-1',
          opponent_id: 'char-2',
          revenge_id: null,
          battle_seed: 12345,
          expires_at: new Date('2099-01-01T00:00:00.000Z'),
          consumed_at: battleState.ticketConsumed ? new Date('2026-03-12T00:00:00.000Z') : null,
        },
      ]),
      character: {
        update: vi.fn(async ({ where }: { where: { id: string } }) => ({
          id: where.id,
          maxStamina: 120,
        })),
      },
      pvpMatch: {
        create: vi.fn(async () => {
          battleState.matchCount += 1
          return { id: `match-${battleState.matchCount}` }
        }),
      },
      revengeQueue: {
        update: vi.fn(),
      },
      pvpBattleTicket: {
        update: vi.fn(async () => {
          battleState.ticketConsumed = true
          return { id: 'ticket-1' }
        }),
      },
    }

    prismaMock.$transaction.mockImplementation(async (callback: (innerTx: typeof tx) => Promise<unknown>) => callback(tx))

    const requestBody = {
      character_id: 'char-1',
      opponent_id: 'char-2',
      battle_seed: 12345,
      battle_ticket_id: 'ticket-1',
      client_winner_id: 'char-1',
    }

    const firstResponse = await POST(
      new Request('http://localhost/api/pvp/resolve', {
        method: 'POST',
        body: JSON.stringify(requestBody),
      }) as any,
    )

    expect(firstResponse.status).toBe(200)
    expect(battleState.ticketConsumed).toBe(true)
    expect(battleState.matchCount).toBe(1)

    const secondResponse = await POST(
      new Request('http://localhost/api/pvp/resolve', {
        method: 'POST',
        body: JSON.stringify(requestBody),
      }) as any,
    )

    expect(secondResponse.status).toBe(409)
    await expect(secondResponse.json()).resolves.toMatchObject({
      error: 'This battle was already resolved.',
    })
    expect(battleState.matchCount).toBe(1)
    expect(prismaMock.revengeQueue.create).toHaveBeenCalledTimes(1)
  })
})
