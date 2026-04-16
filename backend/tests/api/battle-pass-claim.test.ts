import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockCalculateCurrentStamina,
  mockGrantRewardEntries,
  mockInvalidatePassiveCache,
  mockInvalidateSkillCache,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  mockCalculateCurrentStamina: vi.fn(),
  mockGrantRewardEntries: vi.fn(),
  mockInvalidatePassiveCache: vi.fn(),
  mockInvalidateSkillCache: vi.fn(),
  prismaMock: {
    character: {
      findUnique: vi.fn(),
    },
    season: {
      findFirst: vi.fn(),
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

vi.mock('@/lib/game/stamina', () => ({
  calculateCurrentStamina: mockCalculateCurrentStamina,
}))

vi.mock('@/lib/game/reward-grants', () => ({
  grantRewardEntries: mockGrantRewardEntries,
}))

vi.mock('@/lib/game/combat-loader', () => ({
  invalidatePassiveCache: mockInvalidatePassiveCache,
  invalidateSkillCache: mockInvalidateSkillCache,
}))

vi.mock('@/lib/game/reward-display', () => ({
  formatRewardTypeName: (rewardType: string) => `formatted:${rewardType}`,
}))

vi.mock('@/lib/game/balance', () => ({
  bpXpForLevel: () => 100,
}))

import { POST } from '@/app/api/battle-pass/claim/[level]/route'

type BattlePassClaimTx = {
  $queryRawUnsafe: ReturnType<typeof vi.fn>
  battlePass: {
    create: ReturnType<typeof vi.fn>
  }
  battlePassReward: {
    findMany: ReturnType<typeof vi.fn>
  }
  battlePassClaim: {
    findMany: ReturnType<typeof vi.fn>
    create: ReturnType<typeof vi.fn>
  }
  character: {
    update: ReturnType<typeof vi.fn>
  }
  user: {
    update: ReturnType<typeof vi.fn>
  }
  item: {
    findUnique: ReturnType<typeof vi.fn>
  }
  consumableInventory: {
    upsert: ReturnType<typeof vi.fn>
  }
  equipmentInventory: {
    count: ReturnType<typeof vi.fn>
    create: ReturnType<typeof vi.fn>
  }
  appearanceSkin: {
    findFirst: ReturnType<typeof vi.fn>
  }
  cosmetic: {
    findFirst: ReturnType<typeof vi.fn>
    create: ReturnType<typeof vi.fn>
  }
}

function createBattlePassClaimTx({
  bpXp = 600,
  premium = true,
  rewards = [],
  existingClaims = [],
}: {
  bpXp?: number
  premium?: boolean
  rewards?: Array<{
    id: string
    rewardType: string
    rewardId: string | null
    rewardAmount: number
    isPremium: boolean
  }>
  existingClaims?: Array<{ rewardId: string }>
} = {}): BattlePassClaimTx {
  return {
    $queryRawUnsafe: vi.fn(async (query: string) => {
      if (query.includes('FROM characters')) {
        return [{
          id: 'char-1',
          user_id: 'user-1',
          current_stamina: 50,
          max_stamina: 120,
          last_stamina_update: new Date('2026-03-12T00:00:00.000Z'),
          inventory_slots: 20,
        }]
      }

      if (query.includes('FROM users')) {
        return [{ id: 'user-1' }]
      }

      if (query.includes('FROM battle_pass')) {
        return [{
          id: 'bp-1',
          premium,
          bp_xp: bpXp,
        }]
      }

      return []
    }),
    battlePass: {
      create: vi.fn(),
    },
    battlePassReward: {
      findMany: vi.fn(async () => rewards),
    },
    battlePassClaim: {
      findMany: vi.fn(async () => existingClaims),
      create: vi.fn(async ({ data }) => ({ id: `claim-${data.rewardId}` })),
    },
    character: {
      update: vi.fn(async () => ({ id: 'char-1' })),
    },
    user: {
      update: vi.fn(async () => ({ id: 'user-1' })),
    },
    item: {
      findUnique: vi.fn(),
    },
    consumableInventory: {
      upsert: vi.fn(),
    },
    equipmentInventory: {
      count: vi.fn(async () => 0),
      create: vi.fn(),
    },
    appearanceSkin: {
      findFirst: vi.fn(),
    },
    cosmetic: {
      findFirst: vi.fn(),
      create: vi.fn(),
    },
  }
}

describe('POST /api/battle-pass/claim/[level]', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockCalculateCurrentStamina.mockReturnValue({ stamina: 50, updated: false })
    mockGrantRewardEntries.mockResolvedValue({
      gold: 0,
      gems: 0,
      xp: 0,
      levelUpResult: {
        leveledUp: false,
        newLevel: 12,
        remainingXp: 0,
        statPointsAwarded: 0,
        passivePointsAwarded: 0,
      },
    })

    prismaMock.character.findUnique.mockResolvedValue({
      id: 'char-1',
      userId: 'user-1',
    })
    prismaMock.season.findFirst.mockResolvedValue({
      id: 'season-1',
    })
  })

  it('rolls back the whole claim when reward config is invalid, without partial payouts or claim rows', async () => {
    const state = {
      gold: 1000,
      claimsCreated: 0,
      characterUpdates: 0,
      userUpdates: 0,
    }

    const tx = createBattlePassClaimTx({
      rewards: [
        {
          id: 'reward-gold',
          rewardType: 'gold',
          rewardId: null,
          rewardAmount: 250,
          isPremium: false,
        },
        {
          id: 'reward-bad-item',
          rewardType: 'item',
          rewardId: null,
          rewardAmount: 1,
          isPremium: true,
        },
      ],
    })

    tx.battlePassClaim.create = vi.fn(async () => {
      state.claimsCreated += 1
      return { id: `claim-${state.claimsCreated}` }
    })
    tx.character.update = vi.fn(async () => {
      state.characterUpdates += 1
      state.gold += 250
      return { id: 'char-1' }
    })
    tx.user.update = vi.fn(async () => {
      state.userUpdates += 1
      return { id: 'user-1' }
    })

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: BattlePassClaimTx) => Promise<unknown>) => callback(tx),
    )

    const response = await POST(
      makeNextRequest('http://localhost/api/battle-pass/claim/3', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
        }),
      }),
      { params: Promise.resolve({ level: '3' }) },
    )

    expect(response.status).toBe(500)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Battle pass reward configuration is invalid. Claim was not applied.',
    })
    expect(state.gold).toBe(1000)
    expect(state.claimsCreated).toBe(0)
    expect(state.characterUpdates).toBe(0)
    expect(state.userUpdates).toBe(0)
    expect(mockGrantRewardEntries).not.toHaveBeenCalled()
  })

  it('returns 400 when the requested battle pass level has not been reached yet', async () => {
    const tx = createBattlePassClaimTx({
      bpXp: 200,
      rewards: [
        {
          id: 'reward-gold',
          rewardType: 'gold',
          rewardId: null,
          rewardAmount: 250,
          isPremium: false,
        },
      ],
    })

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: BattlePassClaimTx) => Promise<unknown>) => callback(tx),
    )

    const response = await POST(
      makeNextRequest('http://localhost/api/battle-pass/claim/3', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
        }),
      }),
      { params: Promise.resolve({ level: '3' }) },
    )

    expect(response.status).toBe(400)
    await expect(response.json()).resolves.toMatchObject({
      error: 'Battle pass level 3 not yet reached (current: 2)',
    })
    expect(tx.battlePassReward.findMany).not.toHaveBeenCalled()
    expect(mockGrantRewardEntries).not.toHaveBeenCalled()
  })

  it('returns 400 when no rewards at the level are claimable for the current pass state', async () => {
    const tx = createBattlePassClaimTx({
      premium: false,
      rewards: [
        {
          id: 'reward-premium-only',
          rewardType: 'gems',
          rewardId: null,
          rewardAmount: 50,
          isPremium: true,
        },
      ],
    })

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: BattlePassClaimTx) => Promise<unknown>) => callback(tx),
    )

    const response = await POST(
      makeNextRequest('http://localhost/api/battle-pass/claim/3', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
        }),
      }),
      { params: Promise.resolve({ level: '3' }) },
    )

    expect(response.status).toBe(400)
    await expect(response.json()).resolves.toMatchObject({
      error: 'No claimable rewards at this level (already claimed or premium required)',
    })
    expect(tx.battlePassClaim.create).not.toHaveBeenCalled()
    expect(mockGrantRewardEntries).not.toHaveBeenCalled()
  })

  it('returns the claimed rewards and invalidates combat caches when the claim grants a level-up', async () => {
    mockGrantRewardEntries.mockResolvedValue({
      gold: 1250,
      gems: 25,
      xp: 75,
      levelUpResult: {
        leveledUp: true,
        newLevel: 13,
        remainingXp: 25,
        statPointsAwarded: 5,
        passivePointsAwarded: 1,
      },
    })

    const tx = createBattlePassClaimTx({
      premium: true,
      rewards: [
        {
          id: 'reward-gold',
          rewardType: 'gold',
          rewardId: null,
          rewardAmount: 250,
          isPremium: false,
        },
        {
          id: 'reward-stamina',
          rewardType: 'stamina',
          rewardId: null,
          rewardAmount: 15,
          isPremium: true,
        },
      ],
    })

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: BattlePassClaimTx) => Promise<unknown>) => callback(tx),
    )

    const response = await POST(
      makeNextRequest('http://localhost/api/battle-pass/claim/3', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
        }),
      }),
      { params: Promise.resolve({ level: '3' }) },
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      level: 3,
      rewards: [
        {
          rewardType: 'gold',
          rewardName: 'formatted:gold',
          rewardId: null,
          rewardAmount: 250,
          isPremium: false,
        },
        {
          rewardType: 'stamina',
          rewardName: 'formatted:stamina',
          rewardId: null,
          rewardAmount: 15,
          isPremium: true,
        },
      ],
      gold: 1250,
      gems: 25,
      xp: 75,
      leveled_up: true,
      new_level: 13,
      stat_points_awarded: 5,
    })
    expect(tx.battlePassClaim.create).toHaveBeenCalledTimes(2)
    expect(tx.character.update).toHaveBeenCalledWith({
      where: { id: 'char-1' },
      data: {
        currentStamina: 65,
        lastStaminaUpdate: expect.any(Date),
      },
    })
    expect(mockGrantRewardEntries).toHaveBeenCalledWith(tx, {
      userId: 'user-1',
      characterId: 'char-1',
      rewards: [{ type: 'gold', quantity: 250 }],
    })
    expect(mockInvalidateSkillCache).toHaveBeenCalledWith('char-1')
    expect(mockInvalidatePassiveCache).toHaveBeenCalledWith('char-1')
  })
})
