import { beforeEach, describe, expect, it, vi } from 'vitest'

const prismaMock = vi.hoisted(() => ({
  itemBalanceProfile: {
    findFirst: vi.fn(),
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
