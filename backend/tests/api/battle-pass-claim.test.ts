import { beforeEach, describe, expect, it, vi } from 'vitest'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockApplyLevelUp,
  mockCalculateCurrentStamina,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  mockApplyLevelUp: vi.fn(),
  mockCalculateCurrentStamina: vi.fn(),
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

vi.mock('@/lib/game/progression', () => ({
  applyLevelUp: mockApplyLevelUp,
}))

vi.mock('@/lib/game/stamina', () => ({
  calculateCurrentStamina: mockCalculateCurrentStamina,
}))

vi.mock('@/lib/game/balance', () => ({
  bpXpForLevel: () => 100,
}))

import { POST } from '@/app/api/battle-pass/claim/[level]/route'

describe('POST /api/battle-pass/claim/[level]', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockCalculateCurrentStamina.mockReturnValue({ stamina: 50, updated: false })
    mockApplyLevelUp.mockResolvedValue({
      leveledUp: false,
      newLevel: 12,
      remainingXp: 0,
      statPointsAwarded: 0,
      passivePointsAwarded: 0,
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

    const tx = {
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
            premium: true,
            bp_xp: 600,
          }]
        }

        return []
      }),
      battlePass: {
        create: vi.fn(),
      },
      battlePassReward: {
        findMany: vi.fn(async () => [
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
        ]),
      },
      battlePassClaim: {
        findMany: vi.fn(async () => []),
        create: vi.fn(async () => {
          state.claimsCreated += 1
          return { id: `claim-${state.claimsCreated}` }
        }),
      },
      character: {
        update: vi.fn(async () => {
          state.characterUpdates += 1
          state.gold += 250
          return { id: 'char-1' }
        }),
      },
      user: {
        update: vi.fn(async () => {
          state.userUpdates += 1
          return { id: 'user-1' }
        }),
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

    prismaMock.$transaction.mockImplementation(async (callback: (innerTx: typeof tx) => Promise<unknown>) => callback(tx))

    const response = await POST(
      new Request('http://localhost/api/battle-pass/claim/3', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
        }),
      }) as any,
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
    expect(mockApplyLevelUp).not.toHaveBeenCalled()
  })
})
