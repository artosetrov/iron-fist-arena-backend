import { beforeEach, describe, expect, it, vi } from 'vitest'

const prismaMock = vi.hoisted(() => ({
  itemBalanceProfile: {
    findFirst: vi.fn(),
    findMany: vi.fn(),
  },
}))

const configMock = vi.hoisted(() => ({
  getGameConfig: vi.fn(),
  getGameConfigs: vi.fn(),
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

vi.mock('../../src/lib/game/config', () => ({
  getGameConfig: configMock.getGameConfig,
  getGameConfigs: configMock.getGameConfigs,
}))

import {
  calculateItemPowerScore,
  generateBalancedBaseStats,
  getClassDamageFormula,
  getUpgradeProtectionCost,
  getUpgradeSuccessChance,
  invalidateItemBalanceProfileCache,
  itemPowerScoreWith,
  loadItemPowerContext,
} from '../../src/lib/game/item-balance'
import { getUpgradeChancesConfig } from '../../src/lib/game/live-config'
import { GEM_COSTS, UPGRADE_CHANCES } from '../../src/lib/game/balance'

describe('item-balance.ts', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    invalidateItemBalanceProfileCache()
    configMock.getGameConfig.mockImplementation(async (_key: string, fallback: unknown) => fallback)
    configMock.getGameConfigs.mockImplementation(async (defaults: Record<string, unknown>) => defaults)
  })

  it('keeps profile cache bounded and refreshable after invalidation', async () => {
    prismaMock.itemBalanceProfile.findFirst.mockResolvedValueOnce({
      powerWeight: 2,
      statWeights: { str: 1 },
    })

    const first = await calculateItemPowerScore({ str: 10 }, 'common', 0, 'weapon')

    prismaMock.itemBalanceProfile.findFirst.mockResolvedValueOnce({
      powerWeight: 3,
      statWeights: { str: 1 },
    })

    const second = await calculateItemPowerScore({ str: 10 }, 'common', 0, 'weapon')

    invalidateItemBalanceProfileCache('weapon')
    const third = await calculateItemPowerScore({ str: 10 }, 'common', 0, 'weapon')

    expect(first).toBe(20)
    expect(second).toBe(20)
    expect(third).toBe(30)
    expect(prismaMock.itemBalanceProfile.findFirst).toHaveBeenCalledTimes(2)
  })

  it('sanitizes malformed profile stat weights before generating item stats', async () => {
    prismaMock.itemBalanceProfile.findFirst.mockResolvedValue({
      powerWeight: 1,
      statWeights: {
        str: 1,
        fake: 999,
        agi: -2,
        int: 'oops',
      },
    })

    const stats = await generateBalancedBaseStats('weapon', 'common', 5)

    expect(stats).toEqual({ str: 10 })
  })

  it('falls back to class defaults for malformed class damage scaling config', async () => {
    configMock.getGameConfig.mockImplementation(async (key: string, fallback: unknown) => {
      if (key === 'item_balance.class_damage_scaling') {
        return {
          mage: {
            stat: 'mana',
            multiplier: 'fast',
            levelBonus: -1,
          },
        }
      }
      return fallback
    })

    const formula = await getClassDamageFormula('mage')

    expect(formula).toEqual({
      stat: 'int',
      multiplier: 1.4,
      levelBonus: 2,
    })
  })
})

// 2026-10-14 balance audit: the roll and the table shown to the player used
// to read the same config key with DIFFERENT fallbacks (v2 25/15 vs v3
// 30/20), so with the key unseeded the UI advertised one chance and the
// server rolled another.
// The loot pipeline scores gear inside an interactive transaction. The score
// must be pure arithmetic there: config/profile reads through the global
// client starved the pool past the tx timeout (P2028, 2026-11-15).
describe('item power context — no I/O while scoring', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    invalidateItemBalanceProfileCache()
    configMock.getGameConfig.mockImplementation(async (_key: string, fallback: unknown) => fallback)
    configMock.getGameConfigs.mockImplementation(async (defaults: Record<string, unknown>) => defaults)
  })

  it('loads every profile in one query and scores like calculateItemPowerScore', async () => {
    prismaMock.itemBalanceProfile.findMany.mockResolvedValueOnce([
      { itemType: 'weapon', powerWeight: 2, statWeights: { str: 1 } },
      { itemType: 'ring', powerWeight: 0.5, statWeights: { luk: 1 } },
    ])

    const ctx = await loadItemPowerContext()
    expect(prismaMock.itemBalanceProfile.findMany).toHaveBeenCalledTimes(1)

    // Scoring with the context touches neither prisma nor config.
    prismaMock.itemBalanceProfile.findFirst.mockClear()
    configMock.getGameConfig.mockClear()
    const weapon = itemPowerScoreWith(ctx, { str: 10, agi: 4 }, 'rare', 3, 'weapon')
    const ring = itemPowerScoreWith(ctx, { luk: 8 }, 'epic', 0, 'ring')
    const unprofiled = itemPowerScoreWith(ctx, { str: 10 }, 'common', 0, 'boots')
    expect(prismaMock.itemBalanceProfile.findFirst).not.toHaveBeenCalled()
    expect(configMock.getGameConfig).not.toHaveBeenCalled()

    // Same numbers as the async path (which reads the cache the load filled).
    expect(weapon).toBe(await calculateItemPowerScore({ str: 10, agi: 4 }, 'rare', 3, 'weapon'))
    expect(ring).toBe(await calculateItemPowerScore({ luk: 8 }, 'epic', 0, 'ring'))
    // (10 str × 1.0) × common 1.0 × no upgrade × no profile 1.0
    expect(unprofiled).toBe(10)
  })

  it('does not query again while the profiles are fresh', async () => {
    const all = ['weapon', 'helmet', 'chest', 'gloves', 'legs', 'boots', 'accessory', 'amulet', 'belt', 'relic', 'necklace', 'ring']
    prismaMock.itemBalanceProfile.findMany.mockResolvedValue(
      all.map((itemType) => ({ itemType, powerWeight: 1, statWeights: { str: 1 } })),
    )
    await loadItemPowerContext()
    await loadItemPowerContext()
    expect(prismaMock.itemBalanceProfile.findMany).toHaveBeenCalledTimes(1)
  })

  it('still scores when the profile query fails', async () => {
    prismaMock.itemBalanceProfile.findMany.mockRejectedValueOnce(new Error('pool timeout'))
    const ctx = await loadItemPowerContext()
    expect(itemPowerScoreWith(ctx, { str: 10 }, 'common', 0, 'weapon')).toBe(10)
  })
})

describe('upgrade config has one source', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    configMock.getGameConfig.mockImplementation(async (_key: string, fallback: unknown) => fallback)
  })

  it('rolls the same chances it ships to the client when nothing is seeded', async () => {
    const shown = await getUpgradeChancesConfig()
    for (let level = 0; level < shown.length; level++) {
      expect(await getUpgradeSuccessChance(level)).toBe(shown[level])
    }
    expect(shown).toEqual([...UPGRADE_CHANCES])
  })

  it('follows a seeded table for both, not just one', async () => {
    const seeded = [100, 100, 100, 100, 100, 80, 60, 40, 25, 15]
    configMock.getGameConfig.mockImplementation(async (key: string, fallback: unknown) =>
      key === 'upgrade_chances' ? seeded : fallback,
    )
    expect(await getUpgradeChancesConfig()).toEqual(seeded)
    expect(await getUpgradeSuccessChance(9)).toBe(15)
  })

  it('returns 0 past the table, so a +11 attempt can never succeed', async () => {
    expect(await getUpgradeSuccessChance(10)).toBe(0)
  })

  it('prices the protection scroll from balance.ts, not a third number', async () => {
    expect(await getUpgradeProtectionCost()).toBe(GEM_COSTS.UPGRADE_PROTECTION)
  })
})
