import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'
import { createBotBattleTicketId } from '@/lib/game/bot-ticket'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockCalculateCurrentStamina,
  mockLoadCombatCharacter,
  mockIsNpcBot,
  mockGenerateBotCombatStats,
  mockGetStaminaConfig,
  mockGetCombatConfig,
  mockGetGoldRewardsConfig,
  mockGetXpRewardsConfig,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  mockCalculateCurrentStamina: vi.fn(),
  mockLoadCombatCharacter: vi.fn(),
  mockIsNpcBot: vi.fn(() => true),
  mockGenerateBotCombatStats: vi.fn(),
  mockGetStaminaConfig: vi.fn(async () => ({
    FREE_PVP_PER_DAY: 3,
    PVP_COST: 10,
  })),
  mockGetCombatConfig: vi.fn(async () => ({
    MAX_TURNS: 30,
    MIN_DAMAGE: 1,
    CRIT_MULTIPLIER: 1.5,
    MAX_CRIT_CHANCE: 0.5,
    MAX_DODGE_CHANCE: 0.5,
    ROGUE_DODGE_BONUS: 0.05,
    TANK_DAMAGE_REDUCTION: 0.1,
    DAMAGE_VARIANCE: 0.1,
    POISON_ARMOR_PENETRATION: 0.25,
    CRIT_PER_LUK: 0.01,
    CRIT_PER_AGI: 0.005,
    DODGE_PER_AGI: 0.01,
    DODGE_PER_LUK: 0.005,
    CHA_MISS_PER_POINT: 0.001,
    CHA_MISS_CAP: 0.1,
    ROGUE_EXECUTE_HP_THRESHOLD: 0.25,
    ROGUE_EXECUTE_DAMAGE_BONUS: 0.5,
  })),
  mockGetGoldRewardsConfig: vi.fn(),
  mockGetXpRewardsConfig: vi.fn(),
  prismaMock: {
    character: {
      findUnique: vi.fn(),
      update: vi.fn(),
    },
    revengeQueue: {
      findUnique: vi.fn(),
    },
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

vi.mock('@/lib/game/stamina', () => ({
  calculateCurrentStamina: mockCalculateCurrentStamina,
}))

vi.mock('@/lib/game/combat-loader', () => ({
  loadCombatCharacter: mockLoadCombatCharacter,
}))

vi.mock('@/lib/game/npc-bots', () => ({
  isNpcBot: mockIsNpcBot,
  generateBotCombatStats: mockGenerateBotCombatStats,
}))

vi.mock('@/lib/game/live-config', () => ({
  getStaminaConfig: mockGetStaminaConfig,
  getCombatConfig: mockGetCombatConfig,
  getGoldRewardsConfig: mockGetGoldRewardsConfig,
  getXpRewardsConfig: mockGetXpRewardsConfig,
}))

vi.mock('@/lib/game/balance', () => ({
  STANCE_ZONES: {
    ATTACK_ZONE: [],
    DEFENSE_ZONE: [],
    MISMATCH_OFFENSE_BONUS: 1.2,
    MATCH_DEFENSE_BONUS: 0.8,
  },
}))

import { POST } from '@/app/api/pvp/prepare/route'

const originalSecret = process.env.BOT_TICKET_SECRET
const playerCombatStats = {
  id: 'char-1',
  name: 'Hero',
  class: 'warrior',
  level: 10,
  avatar: 'hero.png',
  str: 12,
  agi: 8,
  vit: 9,
  end: 10,
  int: 3,
  wis: 4,
  luk: 5,
  cha: 5,
  maxHp: 100,
  armor: 15,
  magicResist: 6,
  combatStance: 'balanced',
  equippedSkills: [],
  passiveBonuses: null,
}
const botCombatStats = {
  id: 'bot-training',
  name: 'Training Bot',
  class: 'tank',
  level: 9,
  avatar: 'bot.png',
  str: 10,
  agi: 6,
  vit: 10,
  end: 10,
  int: 2,
  wis: 2,
  luk: 2,
  cha: 1,
  maxHp: 95,
  armor: 12,
  magicResist: 4,
  combatStance: 'defense',
  equippedSkills: [],
  passiveBonuses: null,
}

describe('POST /api/pvp/prepare bot tickets', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    delete process.env.BOT_TICKET_SECRET

    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockCalculateCurrentStamina.mockResolvedValue({ stamina: 120, updated: false })
    prismaMock.character.findUnique.mockResolvedValue({
      id: 'char-1',
      userId: 'user-1',
      currentStamina: 120,
      maxStamina: 120,
      lastStaminaUpdate: new Date('2026-04-13T12:00:00.000Z'),
      freePvpToday: 0,
      freePvpDate: new Date('2026-04-13T00:00:00.000Z'),
      pvpRating: undefined,
      pvpCalibrationGames: 0,
      firstWinToday: false,
      firstWinDate: null,
      level: 10,
      cha: 5,
      luk: 5,
      maxHp: 100,
      currentHp: 100,
      lastHpUpdate: new Date('2026-04-13T12:00:00.000Z'),
    })
    mockLoadCombatCharacter.mockResolvedValue(playerCombatStats)
    mockGenerateBotCombatStats.mockReturnValue(botCombatStats)
  })

  afterEach(() => {
    if (originalSecret === undefined) {
      delete process.env.BOT_TICKET_SECRET
    } else {
      process.env.BOT_TICKET_SECRET = originalSecret
    }
  })

  it('does not issue bot battle tickets without BOT_TICKET_SECRET', async () => {
    const request = makeNextRequest('http://localhost/api/pvp/prepare', {
      method: 'POST',
      body: JSON.stringify({
        character_id: 'char-1',
        opponent_id: 'bot-training',
      }),
    })

    const response = await POST(request)
    const body = await response.json()

    expect(response.status).toBe(503)
    expect(body).toEqual({ error: 'Bot fights are temporarily unavailable.' })
  })

  it('issues a hashed bot battle ticket when BOT_TICKET_SECRET is configured', async () => {
    process.env.BOT_TICKET_SECRET = 'test-bot-ticket-secret'
    vi.spyOn(Math, 'random').mockReturnValue(0.123456789)

    const request = makeNextRequest('http://localhost/api/pvp/prepare', {
      method: 'POST',
      body: JSON.stringify({
        character_id: 'char-1',
        opponent_id: 'bot-training',
      }),
    })

    const response = await POST(request)
    const body = await response.json()

    expect(response.status).toBe(200)
    expect(body.is_bot_fight).toBe(true)
    expect(body.player_stats.id).toBe('char-1')
    expect(body.enemy_stats.id).toBe('bot-training')
    expect(body.stamina).toMatchObject({
      cost: 0,
      has_free_pvp: true,
      free_pvp_remaining: 3,
    })
    expect(body.battle_ticket_id).toBe(
      createBotBattleTicketId('char-1', 'bot-training', body.battle_seed),
    )

    vi.restoreAllMocks()
  })
})
