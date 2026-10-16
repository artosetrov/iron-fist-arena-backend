import { describe, expect, it } from 'vitest'
import {
  BASE_STAT_VALUE,
  CLASS_BONUSES,
  CLASS_MAIN_STAT,
  ORIGIN_BONUSES,
  STAT_KEYS,
  baseStatsFor,
  calculateMaxHp,
} from '../../src/lib/game/creation-stats'

describe('creation-stats', () => {
  it('applies base + origin + class bonuses', () => {
    const s = baseStatsFor('warrior', 'orc')
    expect(s.str).toBe(BASE_STAT_VALUE + 3 + 3)
    expect(s.vit).toBe(BASE_STAT_VALUE + 2)
    expect(s.int).toBe(BASE_STAT_VALUE - 1)
    expect(s.agi).toBe(BASE_STAT_VALUE)
  })

  it('stacks bonuses on the same stat (skeleton tank END)', () => {
    const s = baseStatsFor('tank', 'skeleton')
    expect(s.end).toBe(BASE_STAT_VALUE + 2 + 2)
    expect(s.vit).toBe(BASE_STAT_VALUE + 3)
  })

  it('returns every stat key for every combination', () => {
    for (const cls of Object.keys(CLASS_BONUSES) as (keyof typeof CLASS_BONUSES)[]) {
      for (const origin of Object.keys(ORIGIN_BONUSES) as (keyof typeof ORIGIN_BONUSES)[]) {
        const s = baseStatsFor(cls, origin)
        expect(Object.keys(s).sort()).toEqual([...STAT_KEYS].sort())
      }
    }
  })

  it('each class bonus totals +5 and boosts its main stat by 3', () => {
    for (const [cls, bonus] of Object.entries(CLASS_BONUSES)) {
      const total = Object.values(bonus).reduce((a, b) => a + (b ?? 0), 0)
      expect(total).toBe(5)
      expect(bonus[CLASS_MAIN_STAT[cls as keyof typeof CLASS_MAIN_STAT]]).toBe(3)
    }
  })

  it('calculateMaxHp matches 80 + 5·VIT + 3·END', () => {
    expect(calculateMaxHp(10, 10)).toBe(160)
    expect(calculateMaxHp(15, 12)).toBe(80 + 75 + 36)
  })
})
