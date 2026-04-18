import { describe, expect, it, vi } from 'vitest'
import { buildAchievementCatalogFromDefinitions } from '../../src/lib/game/achievement-catalog'

describe('achievement-catalog.ts', () => {
  it('builds a catalog from valid DB definitions and preserves reward ids', () => {
    const catalog = buildAchievementCatalogFromDefinitions([
      {
        key: 'rank_title',
        title: 'Chosen One',
        description: 'Reach the chosen rank',
        target: 1,
        category: 'ranking',
        rewardType: 'title',
        rewardAmount: 1,
        rewardId: 'chosen',
      },
      {
        key: 'pvp_wins_10',
        title: 'Ten Wins',
        description: 'Win ten PvP battles',
        target: 10,
        category: 'pvp',
        rewardType: 'gold',
        rewardAmount: 500,
        rewardId: null,
      },
    ])

    expect(catalog).toEqual({
      rank_title: {
        target: 1,
        category: 'ranking',
        title: 'Chosen One',
        description: 'Reach the chosen rank',
        rewardType: 'title',
        rewardAmount: 1,
        rewardId: 'chosen',
      },
      pvp_wins_10: {
        target: 10,
        category: 'pvp',
        title: 'Ten Wins',
        description: 'Win ten PvP battles',
        rewardType: 'gold',
        rewardAmount: 500,
      },
    })
  })

  it('skips unsupported DB reward types instead of polluting the runtime catalog', () => {
    const warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})

    const catalog = buildAchievementCatalogFromDefinitions([
      {
        key: 'bad_reward',
        title: 'Bad Reward',
        description: 'Should be dropped',
        target: 1,
        category: 'pvp',
        rewardType: 'skin',
        rewardAmount: 1,
        rewardId: 'legendary',
      },
    ])

    expect(catalog).toEqual({})
    expect(warnSpy).toHaveBeenCalledWith(
      '[achievement-catalog] skipping unsupported reward type "skin" for key "bad_reward"',
    )

    warnSpy.mockRestore()
  })
})
