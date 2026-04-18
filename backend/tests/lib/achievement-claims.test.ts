import { beforeEach, describe, expect, it, vi } from 'vitest'

const { prismaMock, mockAwardBattlePassXp } = vi.hoisted(() => ({
  prismaMock: {
    $transaction: vi.fn(),
  },
  mockAwardBattlePassXp: vi.fn(),
}))

vi.mock('../../src/lib/prisma', () => ({
  prisma: prismaMock,
}))

vi.mock('../../src/lib/game/battle-pass', () => ({
  awardBattlePassXp: mockAwardBattlePassXp,
}))

import { claimAchievementReward } from '../../src/lib/game/achievement-claims'

describe('achievement-claims.ts', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('grants title rewards through the cosmetics table and keeps the reward snapshot authoritative', async () => {
    const characterFindUnique = vi
      .fn()
      .mockResolvedValueOnce({ id: 'char-1', userId: 'user-1' })
      .mockResolvedValueOnce({ currentXp: 120, level: 9 })

    const tx = {
      character: {
        findUnique: characterFindUnique,
      },
      $queryRawUnsafe: vi.fn(async () => [
        {
          id: 'achievement-row',
          progress: 1,
          completed: true,
          rewardClaimed: false,
        },
      ]),
      cosmetic: {
        findFirst: vi.fn(async () => null),
        create: vi.fn(async () => ({})),
      },
      achievement: {
        update: vi.fn(async () => ({})),
      },
      user: {
        findUnique: vi.fn(async () => ({ gold: 800, gems: 12 })),
      },
    }

    prismaMock.$transaction.mockImplementation(
      async (callback: (innerTx: typeof tx) => Promise<unknown>) => callback(tx),
    )

    const result = await claimAchievementReward({
      userId: 'user-1',
      characterId: 'char-1',
      achievementKey: 'rank_title',
      achievementDef: {
        target: 1,
        category: 'ranking',
        rewardType: 'title',
        rewardAmount: 1,
        rewardId: 'chosen',
      },
      battlePassXpAward: 25,
    })

    expect(tx.cosmetic.findFirst).toHaveBeenCalledWith({
      where: {
        userId: 'user-1',
        type: 'title',
        refId: 'chosen',
      },
      select: { id: true },
    })
    expect(tx.cosmetic.create).toHaveBeenCalledWith({
      data: {
        userId: 'user-1',
        type: 'title',
        refId: 'chosen',
      },
    })
    expect(tx.achievement.update).toHaveBeenCalledWith({
      where: { id: 'achievement-row' },
      data: { completed: true, rewardClaimed: true },
    })
    expect(mockAwardBattlePassXp).toHaveBeenCalledWith(tx, 'char-1', 25)
    expect(result).toEqual({
      rewardType: 'title',
      rewardAmount: 1,
      rewardId: 'chosen',
      rewardGrantResult: {
        gold: 800,
        gems: 12,
        xp: 120,
        level: 9,
        levelUpResult: null,
      },
    })
  })
})
