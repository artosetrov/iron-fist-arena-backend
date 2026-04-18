import { describe, expect, it } from 'vitest'
import {
  buildEffectiveItemStats,
  calculateEffectiveItemPower,
  combineItemStats,
  sumCoreEquipmentStats,
} from '@/lib/game/item-stats'

describe('item-stats helpers', () => {
  it('combines base and rolled stats before upgrade bonuses', () => {
    expect(
      combineItemStats(
        { str: 5, damageMin: 2 },
        { str: 3, luk: 4 },
      ),
    ).toEqual({
      str: 8,
      damageMin: 2,
      luk: 4,
    })
  })

  it('builds effective stats from merged stat sources', () => {
    expect(
      buildEffectiveItemStats(
        { str: 5, damageMin: 2 },
        { str: 3, luk: 4 },
        2,
        2,
      ),
    ).toEqual({
      str: 12,
      damageMin: 6,
      luk: 8,
    })
  })

  it('sums only gameplay core stat keys', () => {
    expect(
      sumCoreEquipmentStats(
        { str: 4, damageMin: 9 },
        { vit: 2, str: 1, critChance: 7 },
        1,
        3,
      ),
    ).toEqual({
      str: 8,
      agi: 0,
      vit: 5,
      end: 0,
      int: 0,
      wis: 0,
      luk: 0,
      cha: 0,
    })
  })

  it('calculates item power from merged effective stats', () => {
    expect(
      calculateEffectiveItemPower(
        { str: 4, agi: 1 },
        { str: 2, damageMax: 3 },
        1,
        2,
      ),
    ).toBe(16)
  })

  it('ignores invalid stat payloads safely', () => {
    expect(combineItemStats(null, ['bad'])).toEqual({})
    expect(
      buildEffectiveItemStats(
        { str: 5, bad: 'x' },
        { agi: 2, weird: null },
        1,
        1,
      ),
    ).toEqual({ str: 6, agi: 3 })
  })
})
