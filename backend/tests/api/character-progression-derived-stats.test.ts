import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockRecalculateDerivedStats,
  mockInvalidateSkillCache,
  mockInvalidatePassiveCache,
  mockCheckPrestige,
  mockGetPrestigeConfig,
  mockUpdateMultipleAchievements,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(() => true),
  mockRecalculateDerivedStats: vi.fn(),
  mockInvalidateSkillCache: vi.fn(),
  mockInvalidatePassiveCache: vi.fn(),
  mockCheckPrestige: vi.fn(),
  mockGetPrestigeConfig: vi.fn(),
  mockUpdateMultipleAchievements: vi.fn(),
  prismaMock: {
    $transaction: vi.fn(),
    character: {
      findUnique: vi.fn(),
    },
    user: {
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

vi.mock('@/lib/game/equipment-stats', () => ({
  recalculateDerivedStats: mockRecalculateDerivedStats,
}))

vi.mock('@/lib/game/combat-loader', () => ({
  invalidateSkillCache: mockInvalidateSkillCache,
  invalidatePassiveCache: mockInvalidatePassiveCache,
}))

vi.mock('@/lib/game/progression', () => ({
  checkPrestige: mockCheckPrestige,
}))

vi.mock('@/lib/game/live-config', () => ({
  getPrestigeConfig: mockGetPrestigeConfig,
}))

vi.mock('@/lib/game/achievements', () => ({
  updateMultipleAchievements: mockUpdateMultipleAchievements,
}))

vi.mock('@/lib/game/balance', () => ({
  STAT_PURCHASE: {
    GLOBAL_CAP: 100,
    DAILY_LIMIT: 3,
    ESCALATION: [10, 20, 30],
  },
}))

import { POST as allocateStatsPOST } from '@/app/api/characters/[id]/allocate-stats/route'
import { POST as buyStatPointsPOST } from '@/app/api/characters/[id]/buy-stat-points/route'
import { POST as respecStatsPOST } from '@/app/api/characters/[id]/respec-stats/route'
import { POST as prestigePOST } from '@/app/api/prestige/route'

type AllocateStatsTx = {
  $queryRawUnsafe: ReturnType<typeof vi.fn>
  character: {
    update: ReturnType<typeof vi.fn>
  }
}

type BuyStatPointsTx = {
  character: {
    findUnique: ReturnType<typeof vi.fn>
    update: ReturnType<typeof vi.fn>
  }
  user: {
    findUnique: ReturnType<typeof vi.fn>
    update: ReturnType<typeof vi.fn>
  }
}

type RespecStatsTx = {
  character: {
    findUnique: ReturnType<typeof vi.fn>
    update: ReturnType<typeof vi.fn>
  }
  user: {
    findUnique: ReturnType<typeof vi.fn>
    update: ReturnType<typeof vi.fn>
  }
}

type PrestigeTx = {
  $queryRawUnsafe: ReturnType<typeof vi.fn>
  character: {
    update: ReturnType<typeof vi.fn>
  }
  characterPassive: {
    deleteMany: ReturnType<typeof vi.fn>
  }
}

describe('character progression routes keep derived stat recalculation inside the write transaction', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
    mockRecalculateDerivedStats.mockResolvedValue({
      maxHp: 100,
      armor: 10,
      magicResist: 5,
    })
    mockInvalidateSkillCache.mockResolvedValue(undefined)
    mockInvalidatePassiveCache.mockResolvedValue(undefined)
    mockCheckPrestige.mockResolvedValue({
      canPrestige: true,
      newPrestigeLevel: 2,
      statBonusPercent: 10,
    })
    mockGetPrestigeConfig.mockResolvedValue({
      STAT_POINTS_PER_LEVEL: 3,
      STAT_BONUS_PER_PRESTIGE: 0.05,
    })
    mockUpdateMultipleAchievements.mockResolvedValue(undefined)
  })

  it('recalculates derived stats inside allocate-stats transaction', async () => {
    const tx: AllocateStatsTx = {
      $queryRawUnsafe: vi.fn(async () => [
        {
          id: 'char-1',
          user_id: 'user-1',
          stat_points_available: 3,
          str: 10,
          agi: 10,
          vit: 10,
          end: 10,
          int: 10,
          wis: 10,
          luk: 10,
          cha: 10,
        },
      ]),
      character: {
        update: vi.fn(async () => ({})),
      },
    }

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: AllocateStatsTx) => Promise<unknown>) => callback(tx),
    )
    prismaMock.character.findUnique.mockResolvedValue({ id: 'char-1' })
    prismaMock.user.findUnique.mockResolvedValue({ gold: 500, gems: 25 })

    const response = await allocateStatsPOST(
      makeNextRequest('http://localhost/api/characters/char-1/allocate-stats', {
        method: 'POST',
        body: JSON.stringify({ str: 2 }),
      }),
      { params: Promise.resolve({ id: 'char-1' }) },
    )

    expect(response.status).toBe(200)
    expect(mockRecalculateDerivedStats).toHaveBeenCalledWith('char-1', tx)
    expect(mockInvalidateSkillCache).toHaveBeenCalledWith('char-1')
    expect(mockInvalidatePassiveCache).toHaveBeenCalledWith('char-1')
  })

  it('recalculates derived stats inside buy-stat-points transaction', async () => {
    const tx: BuyStatPointsTx = {
      character: {
        findUnique: vi.fn(async () => ({
          userId: 'user-1',
          statPointsAvailable: 2,
          statPurchasesToday: 0,
          statPurchasesDate: new Date(),
          statPurchasesTotal: 0,
        })),
        update: vi.fn(async () => ({})),
      },
      user: {
        findUnique: vi.fn(async () => ({ gems: 100 })),
        update: vi.fn(async () => ({})),
      },
    }

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: BuyStatPointsTx) => Promise<unknown>) => callback(tx),
    )
    prismaMock.character.findUnique.mockResolvedValue({ id: 'char-1' })
    prismaMock.user.findUnique.mockResolvedValue({ gold: 100, gems: 90 })

    const response = await buyStatPointsPOST(
      makeNextRequest('http://localhost/api/characters/char-1/buy-stat-points', {
        method: 'POST',
      }),
      { params: Promise.resolve({ id: 'char-1' }) },
    )

    expect(response.status).toBe(200)
    expect(mockRecalculateDerivedStats).toHaveBeenCalledWith('char-1', tx)
    expect(mockInvalidateSkillCache).toHaveBeenCalledWith('char-1')
    expect(mockInvalidatePassiveCache).toHaveBeenCalledWith('char-1')
  })

  it('recalculates derived stats inside respec-stats transaction', async () => {
    const tx: RespecStatsTx = {
      character: {
        findUnique: vi.fn(async () => ({
          userId: 'user-1',
          level: 10,
          origin: 'human',
          str: 12,
          agi: 10,
          vit: 10,
          end: 10,
          int: 10,
          wis: 11,
          luk: 10,
          cha: 13,
          statPointsAvailable: 0,
        })),
        update: vi.fn(async () => ({})),
      },
      user: {
        findUnique: vi.fn(async () => ({ gems: 100 })),
        update: vi.fn(async () => ({})),
      },
    }

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: RespecStatsTx) => Promise<unknown>) => callback(tx),
    )
    prismaMock.character.findUnique.mockResolvedValue({ id: 'char-1' })
    prismaMock.user.findUnique.mockResolvedValue({ gold: 200, gems: 50 })

    const response = await respecStatsPOST(
      makeNextRequest('http://localhost/api/characters/char-1/respec-stats', {
        method: 'POST',
      }),
      { params: Promise.resolve({ id: 'char-1' }) },
    )

    expect(response.status).toBe(200)
    expect(mockRecalculateDerivedStats).toHaveBeenCalledWith('char-1', tx)
    expect(mockInvalidateSkillCache).toHaveBeenCalledWith('char-1')
    expect(mockInvalidatePassiveCache).toHaveBeenCalledWith('char-1')
  })

  it('recalculates derived stats inside prestige transaction', async () => {
    const tx: PrestigeTx = {
      $queryRawUnsafe: vi.fn(async () => [
        {
          id: 'char-1',
          user_id: 'user-1',
          level: 50,
          prestige_level: 1,
        },
      ]),
      character: {
        update: vi.fn(async () => ({})),
      },
      characterPassive: {
        deleteMany: vi.fn(async () => ({ count: 3 })),
      },
    }

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: PrestigeTx) => Promise<unknown>) => callback(tx),
    )

    const response = await prestigePOST(
      makeNextRequest('http://localhost/api/prestige', {
        method: 'POST',
        body: JSON.stringify({ character_id: 'char-1' }),
      }),
    )

    expect(response.status).toBe(200)
    expect(mockRecalculateDerivedStats).toHaveBeenCalledWith('char-1', tx)
    expect(mockInvalidateSkillCache).toHaveBeenCalledWith('char-1')
    expect(mockInvalidatePassiveCache).toHaveBeenCalledWith('char-1')
    expect(mockUpdateMultipleAchievements).toHaveBeenCalled()
  })
})
