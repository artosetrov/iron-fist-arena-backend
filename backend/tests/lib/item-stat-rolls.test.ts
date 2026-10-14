/**
 * Per-copy stat rolls (2026-10-14). `rolledStats` had existed in the schema,
 * the client and every stat reader for months and was never written.
 */
import { describe, expect, it } from 'vitest'
import { rollItemStats, STAT_ROLL_MAX, combineItemStats, buildEffectiveItemStats } from '@/lib/game/item-stats'

describe('rollItemStats', () => {
  const base = { str: 50, agi: 22, luk: 15, vit: 10 }

  it('rolls nothing at the bottom of the range and the full share at the top', () => {
    expect(rollItemStats(base, 'legendary', () => 0)).toEqual({})
    expect(rollItemStats(base, 'legendary', () => 1)).toEqual({ str: 13, agi: 6, luk: 4, vit: 3 })
  })

  it('never exceeds STAT_ROLL_MAX[rarity] of the base stat, per stat', () => {
    for (const rarity of Object.keys(STAT_ROLL_MAX)) {
      for (let i = 0; i < 200; i++) {
        const rolled = rollItemStats(base, rarity)
        for (const [k, v] of Object.entries(rolled)) {
          expect(v).toBeGreaterThan(0)
          expect(v).toBeLessThanOrEqual(Math.round(base[k as keyof typeof base] * STAT_ROLL_MAX[rarity]))
        }
      }
    }
  })

  it('scales the ceiling with rarity (legendary > common)', () => {
    const common = rollItemStats(base, 'common', () => 1)
    const legendary = rollItemStats(base, 'legendary', () => 1)
    expect(legendary.str).toBeGreaterThan(common.str)
  })

  it('ignores non-numeric and non-positive stats and unknown rarities fall back to common', () => {
    expect(rollItemStats({ str: 0, agi: -3, foo: 'x' }, 'epic', () => 1)).toEqual({})
    expect(rollItemStats({ str: 100 }, 'mythic', () => 1)).toEqual({ str: 10 })
    expect(rollItemStats(null, 'rare')).toEqual({})
  })

  it('clamps an out-of-range rng into [0, 1]', () => {
    expect(rollItemStats({ str: 100 }, 'legendary', () => 7)).toEqual({ str: 25 })
    expect(rollItemStats({ str: 100 }, 'legendary', () => -1)).toEqual({})
  })

  it('is added to base, with the flat upgrade bonus stacking on top of both', () => {
    const rolled = rollItemStats({ str: 100 }, 'legendary', () => 1) // +25
    expect(combineItemStats({ str: 100 }, rolled)).toEqual({ str: 125 })
    const plusTen = buildEffectiveItemStats({ str: 100 }, rolled, 10, 0.5)
    const plusTenNoRoll = buildEffectiveItemStats({ str: 100 }, null, 10, 0.5)
    expect(plusTenNoRoll.str).toBe(105)
    expect(plusTen.str).toBe(130)
  })
})
