import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockRunCombat,
  mockInitCombatConfig,
  mockLoadCombatCharacter,
  mockGetKFactor,
  mockGetGoldRewardsConfig,
  mockGetXpRewardsConfig,
  mockChaGoldBonus,
  mockLevelScaledReward,
  mockCacheDeletePrefix,
  mockApplyLevelUp,
  mockUpdateDailyQuestProgress,
  mockDegradeEquipment,
  mockCreateBattleResultMail,
  mockCreateBattleInviteMail,
  mockUpdateBattleInviteStatus,
  mockGoldBonusMultiplier,
  mockUpdateWeeklyChallengeProgress,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRunCombat: vi.fn(),
  mockInitCombatConfig: vi.fn(),
  mockLoadCombatCharacter: vi.fn(),
  mockGetKFactor: vi.fn(),
  mockGetGoldRewardsConfig: vi.fn(),
  mockGetXpRewardsConfig: vi.fn(),
  mockChaGoldBonus: vi.fn((value: number) => value),
  mockLevelScaledReward: vi.fn((value: number) => value),
  mockCacheDeletePrefix: vi.fn(),
  mockApplyLevelUp: vi.fn(),
  mockUpdateDailyQuestProgress: vi.fn(),
  mockDegradeEquipment: vi.fn(),
  mockCreateBattleResultMail: vi.fn(),
  mockCreateBattleInviteMail: vi.fn(),
  mockUpdateBattleInviteStatus: vi.fn(),
  mockGoldBonusMultiplier: vi.fn(() => 1),
  mockUpdateWeeklyChallengeProgress: vi.fn(),
  prismaMock: {
    character: {
      findUnique: vi.fn(),
    },
    challenge: {
      findUnique: vi.fn(),
      update: vi.fn(),
      updateMany: vi.fn(),
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

vi.mock('@/lib/game/combat', () => ({
  runCombat: mockRunCombat,
  initCombatConfig: mockInitCombatConfig,
}))

vi.mock('@/lib/game/combat-loader', () => ({
  loadCombatCharacter: mockLoadCombatCharacter,
}))

vi.mock('@/lib/game/elo', () => ({
  getKFactor: mockGetKFactor,
}))

vi.mock('@/lib/game/live-config', () => ({
  getStaminaConfig: vi.fn(),
  getGoldRewardsConfig: mockGetGoldRewardsConfig,
  getXpRewardsConfig: mockGetXpRewardsConfig,
}))

vi.mock('@/lib/game/balance', () => ({
  chaGoldBonus: mockChaGoldBonus,
  levelScaledReward: mockLevelScaledReward,
}))

vi.mock('@/lib/cache', () => ({
  cacheDeletePrefix: mockCacheDeletePrefix,
}))

vi.mock('@/lib/game/progression', () => ({
  applyLevelUp: mockApplyLevelUp,
}))

vi.mock('@/lib/game/daily-quests', () => ({
  updateDailyQuestProgress: mockUpdateDailyQuestProgress,
}))

vi.mock('@/lib/game/durability', () => ({
  degradeEquipment: mockDegradeEquipment,
}))

vi.mock('@/lib/game/battle-mail', () => ({
  createBattleResultMail: mockCreateBattleResultMail,
  createBattleInviteMail: mockCreateBattleInviteMail,
  updateBattleInviteStatus: mockUpdateBattleInviteStatus,
}))

vi.mock('@/lib/game/premium', () => ({
  goldBonusMultiplier: mockGoldBonusMultiplier,
  PREMIUM_ENTITLEMENT_USER_SELECT: {},
}))

vi.mock('@/lib/game/weekly-challenges', () => ({
  updateWeeklyChallengeProgress: mockUpdateWeeklyChallengeProgress,
}))

import { POST } from '@/app/api/social/challenges/route'

type SocialChallengesTx = {
  $queryRawUnsafe: ReturnType<typeof vi.fn>
  pvpMatch: {
    create: ReturnType<typeof vi.fn>
  }
  character: {
    update: ReturnType<typeof vi.fn>
  }
  user: {
    update: ReturnType<typeof vi.fn>
  }
  challenge: {
    update: ReturnType<typeof vi.fn>
  }
}

function mockTransaction(tx: SocialChallengesTx) {
  prismaMock.$transaction.mockImplementation(
    async (callback: (innerTx: SocialChallengesTx) => Promise<unknown>) => callback(tx),
  )
}

describe('POST /api/social/challenges accept', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    prismaMock.challenge.updateMany.mockResolvedValue({ count: 0 })
    mockInitCombatConfig.mockResolvedValue(undefined)
    mockRunCombat.mockResolvedValue({
      winnerId: 'char-2',
      finalHp: { 'char-1': 12, 'char-2': 34 },
      turns: [{ turn: 1 }],
      totalTurns: 1,
    })
    mockLoadCombatCharacter.mockImplementation(async (id: string) => ({
      id,
      name: id === 'char-2' ? 'Challenger' : 'Defender',
      class: id === 'char-2' ? 'rogue' : 'warrior',
      level: 10,
      maxHp: 100,
      avatar: null,
    }))
    mockGetKFactor.mockResolvedValue(32)
    mockGetGoldRewardsConfig.mockResolvedValue({
      PVP_WIN_BASE: 100,
      PVP_LOSS_BASE: 50,
    })
    mockGetXpRewardsConfig.mockResolvedValue({
      PVP_WIN_XP: 40,
      PVP_LOSS_XP: 20,
    })
    mockCacheDeletePrefix.mockResolvedValue(undefined)
    mockApplyLevelUp.mockResolvedValue(undefined)
    mockUpdateDailyQuestProgress.mockResolvedValue(undefined)
    mockUpdateWeeklyChallengeProgress.mockResolvedValue(undefined)
    mockDegradeEquipment.mockResolvedValue(undefined)
    mockUpdateBattleInviteStatus.mockResolvedValue(undefined)
    mockCreateBattleResultMail.mockReturnValue(Promise.resolve())
    mockCreateBattleInviteMail.mockReturnValue(Promise.resolve())

    prismaMock.challenge.findUnique.mockResolvedValue({
      id: 'challenge-1',
      challengerId: 'char-2',
      defenderId: 'char-1',
      status: 'pending',
      expiresAt: new Date('2099-01-01T00:00:00.000Z'),
      challenger: {
        characterName: 'Challenger',
        avatar: null,
        class: 'rogue',
      },
    })

    prismaMock.character.findUnique.mockImplementation(async ({ where, select }: { where: { id: string }, select?: Record<string, unknown> }) => {
      if (select?.currentStamina) {
        return {
          id: 'char-1',
          userId: 'user-1',
          currentStamina: 100,
          maxStamina: 100,
          lastStaminaUpdate: new Date('2026-04-15T00:00:00.000Z'),
          pvpRating: 1000,
          pvpCalibrationGames: 0,
          freePvpToday: 0,
          freePvpDate: null,
          firstWinToday: false,
          firstWinDate: null,
          highestPvpRank: 1000,
          cha: 10,
          luk: 8,
          level: 10,
          characterName: 'Defender',
          class: 'warrior',
          pvpWins: 0,
          pvpLosses: 0,
          pvpWinStreak: 0,
          pvpLossStreak: 0,
          currentHp: 100,
          avatar: null,
        }
      }

      if (select?.origin) {
        return { origin: where.id === 'char-2' ? 'elf' : 'human' }
      }

      if (select?.user) {
        return where.id === 'char-2'
          ? {
              id: 'char-2',
              userId: 'user-2',
              level: 10,
              cha: 10,
              luk: 9,
              pvpWins: 5,
              pvpLosses: 2,
              pvpWinStreak: 2,
              pvpLossStreak: 0,
              pvpRating: 1100,
              pvpCalibrationGames: 5,
              highestPvpRank: 1100,
              firstWinToday: false,
              firstWinDate: null,
              currentHp: 100,
              user: {},
            }
          : {
              id: 'char-1',
              userId: 'user-1',
              level: 10,
              cha: 8,
              pvpWins: 3,
              pvpLosses: 4,
              pvpWinStreak: 0,
              pvpLossStreak: 1,
              pvpRating: 1000,
              pvpCalibrationGames: 5,
              highestPvpRank: 1000,
              currentHp: 100,
              user: {},
            }
      }

      return null
    })
  })

  it('awards duel XP and completes the challenge inside the final locked transaction', async () => {
    const tx = {
      $queryRawUnsafe: vi.fn(async () => [{
        id: 'challenge-1',
        defenderId: 'char-1',
        status: 'pending',
        expiresAt: new Date('2099-01-01T00:00:00.000Z'),
      }]),
      pvpMatch: {
        create: vi.fn(async () => ({ id: 'match-1' })),
      },
      character: {
        update: vi.fn(async () => ({})),
      },
      user: {
        update: vi.fn(async () => ({})),
      },
      challenge: {
        update: vi.fn(async () => ({})),
      },
    }
    mockTransaction(tx)

    const response = await POST(
      makeNextRequest('http://localhost/api/social/challenges', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
          action: 'accept',
          challenge_id: 'challenge-1',
        }),
      }),
    )

    expect(response.status).toBe(200)
    expect(tx.character.update).toHaveBeenNthCalledWith(1, expect.objectContaining({
      where: { id: 'char-2' },
      data: expect.objectContaining({
        currentXp: { increment: 40 },
      }),
    }))
    expect(tx.character.update).toHaveBeenNthCalledWith(2, expect.objectContaining({
      where: { id: 'char-1' },
      data: expect.objectContaining({
        currentXp: { increment: 20 },
      }),
    }))
    expect(tx.challenge.update).toHaveBeenCalledWith({
      where: { id: 'challenge-1' },
      data: expect.objectContaining({
        status: 'completed',
        matchId: 'match-1',
      }),
    })
    expect(prismaMock.challenge.update).not.toHaveBeenCalled()
    await expect(response.json()).resolves.toMatchObject({
      result: {
        matchId: 'match-1',
        challengeId: 'challenge-1',
      },
    })
  })

  it('returns 409 instead of 500 when the challenge is no longer pending under the final lock', async () => {
    const tx = {
      $queryRawUnsafe: vi.fn(async () => [{
        id: 'challenge-1',
        defenderId: 'char-1',
        status: 'accepted',
        expiresAt: new Date('2099-01-01T00:00:00.000Z'),
      }]),
      pvpMatch: {
        create: vi.fn(async () => ({ id: 'match-1' })),
      },
      character: {
        update: vi.fn(async () => ({})),
      },
      user: {
        update: vi.fn(async () => ({})),
      },
      challenge: {
        update: vi.fn(async () => ({})),
      },
    }
    mockTransaction(tx)

    const response = await POST(
      makeNextRequest('http://localhost/api/social/challenges', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
          action: 'accept',
          challenge_id: 'challenge-1',
        }),
      }),
    )

    expect(response.status).toBe(409)
    expect(tx.pvpMatch.create).not.toHaveBeenCalled()
    await expect(response.json()).resolves.toEqual({
      error: 'Challenge is no longer pending',
    })
  })
})
