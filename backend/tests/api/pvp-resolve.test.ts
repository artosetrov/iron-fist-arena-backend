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
  mockUpdateWeeklyChallengeProgress,
  mockUpdateTutorialQuestProgress,
  mockAwardBattlePassXp,
  mockDegradeEquipment,
  mockCacheDeletePrefix,
  mockUpdateMultipleAchievements,
  mockCreateBattleResultMail,
  mockIsNpcBot,
  mockGenerateBotCombatStats,
  mockGoldBonusMultiplier,
  mockGetStaminaConfig,
  mockGetGoldRewardsConfig,
  mockGetXpRewardsConfig,
  mockGetFirstWinBonusConfig,
  mockGetBattlePassConfig,
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
  mockUpdateWeeklyChallengeProgress: vi.fn(),
  mockUpdateTutorialQuestProgress: vi.fn(),
  mockAwardBattlePassXp: vi.fn(),
  mockDegradeEquipment: vi.fn(),
  mockCacheDeletePrefix: vi.fn(),
  mockUpdateMultipleAchievements: vi.fn(),
  mockCreateBattleResultMail: vi.fn(),
  mockIsNpcBot: vi.fn(() => false),
  mockGenerateBotCombatStats: vi.fn(),
  mockGoldBonusMultiplier: vi.fn(() => 1),
  mockGetStaminaConfig: vi.fn(async () => ({
    FREE_PVP_PER_DAY: 3,
    PVP_COST: 10,
    MAX_STAMINA: 120,
    REGEN_PER_MIN: 1,
    DUNGEON_COST: 20,
  })),
  mockGetGoldRewardsConfig: vi.fn(async () => ({
    PVP_WIN_BASE: 50,
    PVP_LOSS_BASE: 10,
    REVENGE_MULTIPLIER: 1.5,
  })),
  mockGetXpRewardsConfig: vi.fn(async () => ({
    PVP_WIN_XP: 20,
    PVP_LOSS_XP: 5,
  })),
  mockGetFirstWinBonusConfig: vi.fn(async () => ({
    GOLD_MULT: 2,
    XP_MULT: 2,
  })),
  mockGetBattlePassConfig: vi.fn(async () => ({
    BP_XP_PER_PVP: 20,
    BP_XP_PER_DUNGEON_FLOOR: 30,
    BP_XP_PER_QUEST: 50,
    BP_XP_PER_ACHIEVEMENT: 100,
  })),
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
  chaGoldBonus: (value: number) => value,
  streakGoldMultiplier: () => 0,
  lossStreakGoldMultiplier: () => 0,
  levelScaledReward: (value: number) => value,
}))

vi.mock('@/lib/game/live-config', () => ({
  getStaminaConfig: mockGetStaminaConfig,
  getGoldRewardsConfig: mockGetGoldRewardsConfig,
  getXpRewardsConfig: mockGetXpRewardsConfig,
  getFirstWinBonusConfig: mockGetFirstWinBonusConfig,
  getBattlePassConfig: mockGetBattlePassConfig,
}))

vi.mock('@/lib/game/progression', () => ({
  applyLevelUp: mockApplyLevelUp,
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

vi.mock('@/lib/game/battle-pass', () => ({
  awardBattlePassXp: mockAwardBattlePassXp,
}))

vi.mock('@/lib/game/durability', () => ({
  degradeEquipment: mockDegradeEquipment,
}))

vi.mock('@/lib/game/achievements', () => ({
  updateMultipleAchievements: mockUpdateMultipleAchievements,
}))

vi.mock('@/lib/game/battle-mail', () => ({
  createBattleResultMail: mockCreateBattleResultMail,
}))

vi.mock('@/lib/game/npc-bots', () => ({
  isNpcBot: mockIsNpcBot,
  generateBotCombatStats: mockGenerateBotCombatStats,
}))

vi.mock('@/lib/game/premium', () => ({
  goldBonusMultiplier: mockGoldBonusMultiplier,
}))

vi.mock('@/lib/cache', () => ({
  cacheDeletePrefix: mockCacheDeletePrefix,
  cacheGet: vi.fn().mockResolvedValue(null),
  cacheSet: vi.fn().mockResolvedValue(undefined),
}))

import { POST } from '@/app/api/pvp/resolve/route'

describe('POST /api/pvp/resolve', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockIsNpcBot.mockReturnValue(false)
    mockGoldBonusMultiplier.mockReturnValue(1)
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
    mockUpdateWeeklyChallengeProgress.mockResolvedValue(undefined)
    mockUpdateTutorialQuestProgress.mockResolvedValue(undefined)
    mockAwardBattlePassXp.mockResolvedValue(undefined)
    mockRollAndPersistLoot.mockResolvedValue(null)
    mockDegradeEquipment.mockResolvedValue({ degraded: [], anyBroken: false })
    mockUpdateMultipleAchievements.mockResolvedValue(undefined)
    mockCreateBattleResultMail.mockResolvedValue(undefined)
    mockCacheDeletePrefix.mockResolvedValue(undefined)

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
      avatar: null,
      maxHp: 100,
      pvpWins: 0,
      pvpLosses: 0,
      pvpWinStreak: 0,
      pvpLossStreak: 0,
      user: { premiumUntil: null }, // W3.D5 — Premium Forever multiplier input
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

    // Two $queryRawUnsafe calls inside the transaction:
    //   1) lock pvp_battle_tickets row
    //   2) lock characters row for stamina re-validation
    // We detect which is which by inspecting the SQL passed as the first arg.
    const makeTx = () => ({
      $queryRawUnsafe: vi.fn(async (sql: string) => {
        if (sql.includes('pvp_battle_tickets')) {
          return [
            {
              id: 'ticket-1',
              character_id: 'char-1',
              opponent_id: 'char-2',
              revenge_id: null,
              battle_seed: 12345,
              expires_at: new Date('2099-01-01T00:00:00.000Z'),
              consumed_at: battleState.ticketConsumed ? new Date('2026-03-12T00:00:00.000Z') : null,
            },
          ]
        }
        // characters lock row
        return [
          {
            id: 'char-1',
            current_stamina: 120,
            max_stamina: 120,
            last_stamina_update: new Date('2026-03-12T00:00:00.000Z'),
            free_pvp_today: 0,
            free_pvp_date: null,
          },
        ]
      }),
      character: {
        update: vi.fn(async ({ where }: { where: { id: string } }) => ({
          id: where.id,
          maxStamina: 120,
        })),
      },
      user: {
        update: vi.fn(async ({ where }: { where: { id: string } }) => ({
          id: where.id,
          gold: 1000,
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
    })

    prismaMock.$transaction.mockImplementation(async (callback: any) => callback(makeTx()))

    const requestBody = {
      character_id: 'char-1',
      opponent_id: 'char-2',
      battle_seed: 12345,
      battle_ticket_id: 'ticket-1',
      client_winner_id: 'char-1',
    }

    // loadCombatCharacter is called twice per resolve (attacker, defender),
    // so reset the mock for the second request too.
    mockLoadCombatCharacter.mockReset()
    mockLoadCombatCharacter
      .mockResolvedValueOnce({ id: 'char-1', maxHp: 100 })
      .mockResolvedValueOnce({ id: 'char-2', maxHp: 100 })
      .mockResolvedValueOnce({ id: 'char-1', maxHp: 100 })
      .mockResolvedValueOnce({ id: 'char-2', maxHp: 100 })

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
  })
})
