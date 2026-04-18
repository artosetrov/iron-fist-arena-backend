import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockGetAchievementCatalog,
  prismaMock,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockGetAchievementCatalog: vi.fn(),
  prismaMock: {
    character: {
      findUnique: vi.fn(),
    },
    achievement: {
      findMany: vi.fn(),
      createMany: vi.fn(),
    },
  },
}))

vi.mock('@/lib/auth', () => ({
  getAuthUser: mockGetAuthUser,
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

vi.mock('@/lib/game/achievement-catalog', () => ({
  getAchievementCatalog: mockGetAchievementCatalog,
}))

import { GET } from '@/app/api/achievements/route'

describe('GET /api/achievements', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    prismaMock.character.findUnique.mockResolvedValue({ userId: 'user-1' })
    prismaMock.achievement.createMany.mockResolvedValue({ count: 0 })
  })

  it('prefers admin-authored titles and descriptions from live definitions', async () => {
    mockGetAchievementCatalog.mockResolvedValue({
      rank_title: {
        target: 1,
        category: 'ranking',
        title: 'Chosen One',
        description: 'Reach the chosen rank',
        rewardType: 'title',
        rewardAmount: 1,
        rewardId: 'chosen',
      },
    })
    prismaMock.achievement.findMany.mockResolvedValue([
      {
        achievementKey: 'rank_title',
        target: 1,
        progress: 1,
        completed: true,
        rewardClaimed: false,
      },
    ])

    const response = await GET(
      makeNextRequest('http://localhost/api/achievements?character_id=char-1'),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toEqual({
      achievements: [
        {
          key: 'rank_title',
          category: 'ranking',
          title: 'Chosen One',
          description: 'Reach the chosen rank',
          target: 1,
          progress: 1,
          completed: true,
          rewardClaimed: false,
          reward: { title: 'chosen' },
        },
      ],
    })
    expect(prismaMock.achievement.createMany).not.toHaveBeenCalled()
  })
})
