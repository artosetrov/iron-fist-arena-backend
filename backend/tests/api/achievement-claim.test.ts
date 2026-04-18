import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockGetAchievementCatalog,
  mockClaimAchievementReward,
  mockGetBattlePassConfig,
  mockInvalidatePassiveCache,
  mockInvalidateSkillCache,
} = vi.hoisted(() => ({
  mockGetAuthUser: vi.fn(),
  mockRateLimit: vi.fn(),
  mockGetAchievementCatalog: vi.fn(),
  mockClaimAchievementReward: vi.fn(),
  mockGetBattlePassConfig: vi.fn(),
  mockInvalidatePassiveCache: vi.fn(),
  mockInvalidateSkillCache: vi.fn(),
}))

vi.mock('@/lib/auth', () => ({
  getAuthUser: mockGetAuthUser,
}))

vi.mock('@/lib/rate-limit', () => ({
  rateLimit: mockRateLimit,
}))

vi.mock('@/lib/game/achievement-catalog', () => ({
  getAchievementCatalog: mockGetAchievementCatalog,
}))

vi.mock('@/lib/game/achievement-claims', () => ({
  claimAchievementReward: mockClaimAchievementReward,
}))

vi.mock('@/lib/game/live-config', () => ({
  getBattlePassConfig: mockGetBattlePassConfig,
}))

vi.mock('@/lib/game/combat-loader', () => ({
  invalidatePassiveCache: mockInvalidatePassiveCache,
  invalidateSkillCache: mockInvalidateSkillCache,
}))

import { POST } from '@/app/api/achievements/claim/route'
import { POST as postByKey } from '@/app/api/achievements/[key]/claim/route'

describe('achievement claim routes', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    mockGetAuthUser.mockResolvedValue({ id: 'user-1' })
    mockRateLimit.mockResolvedValue(true)
    mockGetBattlePassConfig.mockResolvedValue({ BP_XP_PER_ACHIEVEMENT: 25 })
    mockGetAchievementCatalog.mockResolvedValue({
      rank_title: {
        target: 1,
        category: 'ranking',
        rewardType: 'title',
        rewardAmount: 1,
        rewardId: 'chosen',
      },
      rank_frame: {
        target: 1,
        category: 'ranking',
        rewardType: 'frame',
        rewardAmount: 1,
        rewardId: 'ornate',
      },
    })
  })

  it('returns cosmetic reward identifiers on the canonical achievement-claim route', async () => {
    mockClaimAchievementReward.mockResolvedValue({
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

    const response = await POST(
      makeNextRequest('http://localhost/api/achievements/claim', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
          achievement_key: 'rank_title',
        }),
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      achievement_key: 'rank_title',
      reward: {
        type: 'title',
        amount: 1,
        id: 'chosen',
      },
      reward_gold: 0,
      reward_gems: 0,
      reward_xp: 0,
      reward_title: 'chosen',
      reward_frame: null,
      gold: 800,
      gems: 12,
      xp: 120,
      leveled_up: false,
    })

    expect(mockInvalidateSkillCache).not.toHaveBeenCalled()
    expect(mockInvalidatePassiveCache).not.toHaveBeenCalled()
    expect(mockClaimAchievementReward).toHaveBeenCalledWith({
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
  })

  it('keeps the keyed claim route aligned for frame rewards', async () => {
    mockClaimAchievementReward.mockResolvedValue({
      rewardType: 'frame',
      rewardAmount: 1,
      rewardId: 'ornate',
      rewardGrantResult: {
        gold: 990,
        gems: 5,
        xp: 240,
        level: 11,
        levelUpResult: null,
      },
    })

    const response = await postByKey(
      makeNextRequest('http://localhost/api/achievements/rank_frame/claim', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
        }),
      }),
      { params: Promise.resolve({ key: 'rank_frame' }) },
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({
      achievement_key: 'rank_frame',
      reward: {
        type: 'frame',
        amount: 1,
        id: 'ornate',
      },
      reward_gold: 0,
      reward_gems: 0,
      reward_xp: 0,
      reward_title: null,
      reward_frame: 'ornate',
      gold: 990,
      gems: 5,
      xp: 240,
      leveled_up: false,
    })
  })
})
