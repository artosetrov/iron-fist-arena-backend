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
  invalidateItemBalanceProfileCache,
} from '../../src/lib/game/item-balance'

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
