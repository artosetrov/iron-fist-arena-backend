/**
 * Derived stats include passive-tree bonuses on EVERY recalculation —
 * 2026-10-14 balance audit.
 *
 * Eight routes (equip, unequip, upgrade, allocate/respec/buy stat points,
 * prestige, durability repair) called a recalculation that knew nothing about
 * passives, while combat reads the persisted `maxHp`. Unlock "+9% max HP",
 * equip a ring, and the bonus was gone from every subsequent fight.
 */
import { beforeEach, describe, expect, it, vi } from 'vitest'

const { prismaMock, configMock } = vi.hoisted(() => ({
  prismaMock: {
    character: { findUnique: vi.fn(), update: vi.fn(async () => ({})) },
  },
  configMock: { getGameConfig: vi.fn(), getGameConfigs: vi.fn() },
}))

vi.mock('@/lib/prisma', () => ({ prisma: prismaMock }))
vi.mock('../../src/lib/game/config', () => ({
  getGameConfig: configMock.getGameConfig,
  getGameConfigs: configMock.getGameConfigs,
}))
vi.mock('../../src/lib/game/progression', () => ({
  applyPrestigeBonus: async (value: number) => value,
}))

import { recalculateDerivedStats } from '../../src/lib/game/equipment-stats'
import { invalidateItemBalanceProfileCache } from '../../src/lib/game/item-balance'

function character(passives: Array<{ bonusType: string; bonusStat: string | null; bonusValue: number; currentRank?: number }>) {
  return {
    str: 10, agi: 10, vit: 10, end: 10, int: 10, wis: 10, luk: 10, cha: 10,
    prestigeLevel: 0,
    equipment: [],
    characterPassives: passives.map((p) => ({
      currentRank: p.currentRank ?? 1,
      node: { bonusType: p.bonusType, bonusStat: p.bonusStat, bonusValue: p.bonusValue },
    })),
  }
}

describe('recalculateDerivedStats', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    invalidateItemBalanceProfileCache()
    configMock.getGameConfig.mockImplementation(async (_k: string, fallback: unknown) => fallback)
    configMock.getGameConfigs.mockImplementation(async (defaults: Record<string, unknown>) => defaults)
  })

  it('keeps a percent_hp talent in the persisted maxHp', async () => {
    prismaMock.character.findUnique.mockResolvedValueOnce(character([]))
    const without = await recalculateDerivedStats('char-1')

    prismaMock.character.findUnique.mockResolvedValueOnce(
      character([{ bonusType: 'percent_hp', bonusStat: null, bonusValue: 9 }]),
    )
    const withTalent = await recalculateDerivedStats('char-1')

    expect(withTalent.maxHp).toBe(Math.floor(without.maxHp * 1.09))
    expect(prismaMock.character.update).toHaveBeenLastCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ maxHp: withTalent.maxHp }) }),
    )
  })

  it('keeps flat armor and magic resist talents too', async () => {
    prismaMock.character.findUnique.mockResolvedValueOnce(character([]))
    const without = await recalculateDerivedStats('char-1')

    prismaMock.character.findUnique.mockResolvedValueOnce(
      character([
        { bonusType: 'flat_armor', bonusStat: null, bonusValue: 15 },
        { bonusType: 'flat_magic_resist', bonusStat: null, bonusValue: 12 },
      ]),
    )
    const withTalent = await recalculateDerivedStats('char-1')

    expect(withTalent.armor).toBe(without.armor + 15)
    expect(withTalent.magicResist).toBe(without.magicResist + 12)
  })

  it('scales a ranked node by its rank', async () => {
    prismaMock.character.findUnique.mockResolvedValueOnce(character([]))
    const without = await recalculateDerivedStats('char-1')

    prismaMock.character.findUnique.mockResolvedValueOnce(
      character([{ bonusType: 'percent_hp', bonusStat: null, bonusValue: 3, currentRank: 3 }]),
    )
    const r3 = await recalculateDerivedStats('char-1')
    expect(r3.maxHp).toBe(Math.floor(without.maxHp * 1.09))
  })
})
