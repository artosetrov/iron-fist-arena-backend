import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

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

vi.mock('@/lib/game/premium', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@/lib/game/premium')>()
  return {
    ...actual,
    goldBonusMultiplier: mockGoldBonusMultiplier,
  }
})

vi.mock('@/lib/cache', () => ({
  cacheDeletePrefix: mockCacheDeletePrefix,
  cacheGet: vi.fn().mockResolvedValue(null),
  cacheSet: vi.fn().mockResolvedValue(undefined),
}))

import { POST } from '@/app/api/pvp/resolve/route'

type PvpResolveTx = {
  $queryRawUnsafe: ReturnType<typeof vi.fn>
  character: {
    update: ReturnType<typeof vi.fn>
  }
  user: {
    update: ReturnType<typeof vi.fn>
  }
  pvpMatch: {
    create: ReturnType<typeof vi.fn>
  }
  revengeQueue: {
    update: ReturnType<typeof vi.fn>
  }
  pvpBattleTicket: {
    update: ReturnType<typeof vi.fn>
  }
}

const defaultRequestBody = {
  character_id: 'char-1',
  opponent_id: 'char-2',
  battle_seed: 12345,
  battle_ticket_id: 'ticket-1',
  client_winner_id: 'char-1',
}
const originalBotTicketSecret = process.env.BOT_TICKET_SECRET

function seedCombatCharacters(requestCount = 1) {
  mockLoadCombatCharacter.mockReset()
  for (let index = 0; index < requestCount; index += 1) {
    mockLoadCombatCharacter
      .mockResolvedValueOnce({ id: 'char-1', maxHp: 100 })
      .mockResolvedValueOnce({ id: 'char-2', maxHp: 100 })
  }
}

function createPvpResolveTx(
  battleState: { ticketConsumed: boolean; matchCount: number },
  options?: {
    ticketOverrides?: Partial<{
      character_id: string
      opponent_id: string
      revenge_id: string | null
      battle_seed: number
      expires_at: Date
      consumed_at: Date | null
    }>
    lockedRowOverrides?: Partial<{
      current_stamina: number
      max_stamina: number
      last_stamina_update: Date
      free_pvp_today: number
      free_pvp_date: Date | null
    }>
  },
): PvpResolveTx {
  const ticketRow = {
    character_id: 'char-1',
    opponent_id: 'char-2',
    revenge_id: null,
    battle_seed: 12345,
    expires_at: new Date('2099-01-01T00:00:00.000Z'),
    consumed_at: battleState.ticketConsumed ? new Date('2026-03-12T00:00:00.000Z') : null,
    ...options?.ticketOverrides,
  }

  const lockedRow = {
    current_stamina: 120,
    max_stamina: 120,
    last_stamina_update: new Date('2026-03-12T00:00:00.000Z'),
    free_pvp_today: 0,
    free_pvp_date: null,
    ...options?.lockedRowOverrides,
  }

  return {
    $queryRawUnsafe: vi.fn(async (sql: string) => {
      if (sql.includes('pvp_battle_tickets')) {
        return [
          {
            id: 'ticket-1',
            ...ticketRow,
          },
        ]
      }

      return [
        {
          id: 'char-1',
          ...lockedRow,
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
  }
}

describe('POST /api/pvp/resolve', () => {
  afterEach(() => {
    if (originalBotTicketSecret === undefined) {
      delete process.env.BOT_TICKET_SECRET
    } else {
      process.env.BOT_TICKET_SECRET = originalBotTicketSecret
    }
  })

  beforeEach(() => {
    vi.clearAllMocks()

    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockIsNpcBot.mockReturnValue(false)
    mockGoldBonusMultiplier.mockReturnValue(1)
    mockCalculateCurrentStamina.mockReturnValue({ stamina: 120, updated: false })
    seedCombatCharacters(1)
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
      user: { premiumUntil: null, premiumSubscription: null }, // Keep this aligned with the shared premium selector contract.
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
    const makeTx = () => createPvpResolveTx(battleState)

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: PvpResolveTx) => Promise<unknown>) => callback(makeTx()),
    )

    seedCombatCharacters(2)

    const firstResponse = await POST(
      makeNextRequest('http://localhost/api/pvp/resolve', {
        method: 'POST',
        body: JSON.stringify(defaultRequestBody),
      }),
    )

    expect(firstResponse.status).toBe(200)
    expect(battleState.ticketConsumed).toBe(true)
    expect(battleState.matchCount).toBe(1)

    const secondResponse = await POST(
      makeNextRequest('http://localhost/api/pvp/resolve', {
        method: 'POST',
        body: JSON.stringify(defaultRequestBody),
      }),
    )

    expect(secondResponse.status).toBe(409)
    await expect(secondResponse.json()).resolves.toMatchObject({
      error: 'This battle was already resolved.',
    })
    expect(battleState.matchCount).toBe(1)
  })

  it('returns the authoritative server result when the client reports the wrong winner', async () => {
    const battleState = {
      ticketConsumed: false,
      matchCount: 0,
    }
    const tx = createPvpResolveTx(battleState)

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: PvpResolveTx) => Promise<unknown>) => callback(tx),
    )

    seedCombatCharacters(1)

    const response = await POST(
      makeNextRequest('http://localhost/api/pvp/resolve', {
        method: 'POST',
        body: JSON.stringify({
          ...defaultRequestBody,
          client_winner_id: 'char-2',
        }),
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      verified: true,
      server_winner_id: 'char-1',
      client_matches: false,
      result: {
        is_win: true,
        winner_id: 'char-1',
        gold_reward: 100,
        xp_reward: 40,
        first_win_bonus: true,
      },
      stamina: {
        current: 120,
        max: 120,
      },
      matchId: 'match-1',
    })
    expect(mockCacheDeletePrefix).toHaveBeenCalledWith('leaderboard:')
    expect(mockUpdateDailyQuestProgress).toHaveBeenCalledWith(prismaMock, 'char-1', 'pvp_wins')
    expect(mockAwardBattlePassXp).toHaveBeenCalledWith(prismaMock, 'char-1', 20)
    expect(mockCreateBattleResultMail).toHaveBeenCalled()
  })

  it('rejects the resolve when the locked character row no longer has enough stamina', async () => {
    const battleState = {
      ticketConsumed: false,
      matchCount: 0,
    }
    const tx = createPvpResolveTx(battleState, {
      lockedRowOverrides: {
        current_stamina: 5,
        free_pvp_today: 3,
        free_pvp_date: new Date(),
      },
    })

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: PvpResolveTx) => Promise<unknown>) => callback(tx),
    )

    mockCalculateCurrentStamina
      .mockReturnValueOnce({ stamina: 120, updated: false })
      .mockReturnValueOnce({ stamina: 5, updated: false })
    seedCombatCharacters(1)

    const response = await POST(
      makeNextRequest('http://localhost/api/pvp/resolve', {
        method: 'POST',
        body: JSON.stringify(defaultRequestBody),
      }),
    )

    expect(response.status).toBe(400)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Not enough stamina',
      required: 0,
    })
    expect(tx.pvpMatch.create).not.toHaveBeenCalled()
    expect(tx.pvpBattleTicket.update).not.toHaveBeenCalled()
    expect(mockAwardBattlePassXp).not.toHaveBeenCalled()
  })

  it('rejects mismatched battle ticket payloads before creating the match', async () => {
    const battleState = {
      ticketConsumed: false,
      matchCount: 0,
    }
    const tx = createPvpResolveTx(battleState, {
      ticketOverrides: {
        opponent_id: 'char-999',
      },
    })

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: PvpResolveTx) => Promise<unknown>) => callback(tx),
    )

    seedCombatCharacters(1)

    const response = await POST(
      makeNextRequest('http://localhost/api/pvp/resolve', {
        method: 'POST',
        body: JSON.stringify(defaultRequestBody),
      }),
    )

    expect(response.status).toBe(400)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Battle preparation does not match this resolve request.',
    })
    expect(tx.pvpMatch.create).not.toHaveBeenCalled()
    expect(tx.pvpBattleTicket.update).not.toHaveBeenCalled()
  })

  it('rejects invalid bot battle tickets before running the bot fight', async () => {
    mockIsNpcBot.mockReturnValue(true)
    process.env.BOT_TICKET_SECRET = 'test-bot-ticket-secret'

    const response = await POST(
      makeNextRequest('http://localhost/api/pvp/resolve', {
        method: 'POST',
        body: JSON.stringify({
          ...defaultRequestBody,
          opponent_id: 'bot-training',
          battle_ticket_id: 'invalid-ticket',
        }),
      }),
    )

    expect(response.status).toBe(400)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Invalid bot battle ticket.',
    })
    expect(mockLoadCombatCharacter).not.toHaveBeenCalled()
    expect(prismaMock.$transaction).not.toHaveBeenCalled()
  })
})
