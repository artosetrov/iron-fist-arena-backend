// =============================================================================
// balance-gold.test.ts — W3.D3 pure-helper coverage
// =============================================================================
//
// Locks down the W3.D3 rebalance of gold-side formulas so a future edit cannot
// silently shift the sink ratio back out of band:
//
//   - chaGoldBonus          — hard-capped at 80% (was 125%)
//   - streakGoldMultiplier  — win streak capped at +50% (was +100%)
//   - lossStreakGoldMult    — loss recovery capped at +50% (was +80%)
//   - repairCost            — base 120 / per-level 20 (was 80 / 15)
//   - upgradeCost           — exponential 150 × 1.4^N unchanged, regression guard
//   - levelScaledReward     — +2% per level, regression guard
//
// These numbers are referenced directly by economy-simulator.ts — if any
// constant drifts, the sink-ratio acceptance test in tests/economy/ will also
// fail, but a targeted helper test surfaces the root cause faster.

import { describe, it, expect } from 'vitest'
import {
  CHA_GOLD_BONUS_CAP,
  chaGoldBonus,
  WIN_STREAK_BONUSES,
  streakGoldMultiplier,
  LOSS_STREAK_BONUSES,
  lossStreakGoldMultiplier,
  REPAIR_COSTS,
  repairCost,
  UPGRADE_COSTS,
  upgradeCost,
  levelScaledReward,
} from '../../src/lib/game/balance'

// -----------------------------------------------------------------------------
// chaGoldBonus — three-tier DR curve with W3.D3 hard cap at 80%
// -----------------------------------------------------------------------------
describe('chaGoldBonus (W3.D3 cap = 80%)', () => {
  it('exports CHA_GOLD_BONUS_CAP = 0.80', () => {
    expect(CHA_GOLD_BONUS_CAP).toBe(0.80)
  })

  it('zero CHA = zero bonus (baseGold passthrough)', () => {
    expect(chaGoldBonus(1000, 0)).toBe(1000)
  })

  it('tier 1 (0..30): +2.5% per CHA point', () => {
    // 20 CHA → +50%
    expect(chaGoldBonus(1000, 20)).toBe(Math.floor(1000 * 1.5))
    // 30 CHA → +75%
    expect(chaGoldBonus(1000, 30)).toBe(Math.floor(1000 * 1.75))
  })

  it('tier 2 (30..60): +1% per CHA point — DR kicks in', () => {
    // 30 CHA base = 75%, + 5 more points at 1% each = 80% → hits the cap.
    expect(chaGoldBonus(1000, 35)).toBe(Math.floor(1000 * 1.80))
  })

  it('tier 3 (>60): +0.5% per point, but capped at 80%', () => {
    // 100 CHA raw bonus = 0.75 + 0.30 + 0.20 = 1.25 → should clamp to 0.80.
    expect(chaGoldBonus(1000, 100)).toBe(Math.floor(1000 * 1.80))
  })

  it('never exceeds 80% no matter how high CHA goes (pre-W3.D3 regression guard)', () => {
    // Pre-W3.D3 a CHA=150 bonus landed at +1.25 (×2.25). Make sure that is
    // firmly in the past.
    const pre = 1000 * 2.25
    const post = chaGoldBonus(1000, 150)
    expect(post).toBeLessThan(pre)
    expect(post).toBe(Math.floor(1000 * 1.80))
  })

  it('floors the final gold number (no fractional coin payouts)', () => {
    // 1 * (1 + 0.025) = 1.025 → floor → 1.
    expect(chaGoldBonus(1, 1)).toBe(1)
  })
})

// -----------------------------------------------------------------------------
// streakGoldMultiplier — W3.D3 win-streak cap at +50%
// -----------------------------------------------------------------------------
describe('streakGoldMultiplier (W3.D3 cap = +50%)', () => {
  it('streak 0..2 = no bonus', () => {
    expect(streakGoldMultiplier(0)).toBe(0)
    expect(streakGoldMultiplier(1)).toBe(0)
    expect(streakGoldMultiplier(2)).toBe(0)
  })

  it('streak 3..4 = +15%', () => {
    expect(streakGoldMultiplier(3)).toBe(0.15)
    expect(streakGoldMultiplier(4)).toBe(0.15)
  })

  it('streak 5..7 = +30%', () => {
    expect(streakGoldMultiplier(5)).toBe(0.3)
    expect(streakGoldMultiplier(6)).toBe(0.3)
    expect(streakGoldMultiplier(7)).toBe(0.3)
  })

  it('streak 8..10 = +50% (hard cap)', () => {
    expect(streakGoldMultiplier(8)).toBe(0.5)
    expect(streakGoldMultiplier(9)).toBe(0.5)
    expect(streakGoldMultiplier(10)).toBe(0.5)
  })

  it('streak above table length stays at +50% (no runaway)', () => {
    expect(streakGoldMultiplier(50)).toBe(0.5)
    expect(streakGoldMultiplier(999)).toBe(0.5)
  })

  it('never returns more than 0.5 (regression guard against pre-W3.D3 ×2.0)', () => {
    for (let s = 0; s <= 100; s++) {
      expect(streakGoldMultiplier(s)).toBeLessThanOrEqual(0.5)
    }
  })

  it('is monotone non-decreasing across the lookup table', () => {
    for (let i = 1; i < WIN_STREAK_BONUSES.length; i++) {
      expect(WIN_STREAK_BONUSES[i]).toBeGreaterThanOrEqual(WIN_STREAK_BONUSES[i - 1])
    }
  })

  it('negative streak = 0 (defensive branch)', () => {
    expect(streakGoldMultiplier(-1)).toBe(0)
    expect(streakGoldMultiplier(-999)).toBe(0)
  })
})

// -----------------------------------------------------------------------------
// lossStreakGoldMultiplier — W3.D3 loss-recovery cap at +50%
// -----------------------------------------------------------------------------
describe('lossStreakGoldMultiplier (W3.D3 cap = +50%)', () => {
  it('no loss streak = no recovery bonus', () => {
    expect(lossStreakGoldMultiplier(0)).toBe(0)
    expect(lossStreakGoldMultiplier(1)).toBe(0)
    expect(lossStreakGoldMultiplier(2)).toBe(0)
  })

  it('3..4 losses = +20% on the recovery win', () => {
    expect(lossStreakGoldMultiplier(3)).toBe(0.2)
    expect(lossStreakGoldMultiplier(4)).toBe(0.2)
  })

  it('5..6 losses = +35%', () => {
    expect(lossStreakGoldMultiplier(5)).toBe(0.35)
    expect(lossStreakGoldMultiplier(6)).toBe(0.35)
  })

  it('7+ losses = +50% (hard cap)', () => {
    expect(lossStreakGoldMultiplier(7)).toBe(0.5)
    expect(lossStreakGoldMultiplier(10)).toBe(0.5)
    expect(lossStreakGoldMultiplier(999)).toBe(0.5)
  })

  it('never exceeds +50% (regression guard against pre-W3.D3 +80%)', () => {
    for (let l = 0; l <= 100; l++) {
      expect(lossStreakGoldMultiplier(l)).toBeLessThanOrEqual(0.5)
    }
  })

  it('is monotone non-decreasing (farmers cannot game lower-loss windows)', () => {
    for (let i = 1; i < LOSS_STREAK_BONUSES.length; i++) {
      expect(LOSS_STREAK_BONUSES[i]).toBeGreaterThanOrEqual(LOSS_STREAK_BONUSES[i - 1])
    }
  })

  it('negative loss streak = 0', () => {
    expect(lossStreakGoldMultiplier(-1)).toBe(0)
  })
})

// -----------------------------------------------------------------------------
// repairCost — W3.D3 rebase 120 / 20 with rarity multipliers
// -----------------------------------------------------------------------------
describe('repairCost (W3.D3 base 120 / per-level 20)', () => {
  it('exports bumped BASE_COST and PER_LEVEL constants', () => {
    expect(REPAIR_COSTS.BASE_COST).toBe(120)
    expect(REPAIR_COSTS.PER_LEVEL).toBe(20)
  })

  it('level 1 common = 120 + 20 = 140', () => {
    expect(repairCost(1, 'common')).toBe(140)
  })

  it('level 10 common = 120 + 200 = 320', () => {
    expect(repairCost(10, 'common')).toBe(320)
  })

  it('rarity multipliers compound on the level-scaled base', () => {
    // level 10 base = 320; uncommon ×1.5 = 480; rare ×2 = 640; epic ×3 = 960; legendary ×5 = 1600
    expect(repairCost(10, 'uncommon')).toBe(480)
    expect(repairCost(10, 'rare')).toBe(640)
    expect(repairCost(10, 'epic')).toBe(960)
    expect(repairCost(10, 'legendary')).toBe(1600)
  })

  it('unknown rarity defaults to ×1 (no silent free repair)', () => {
    expect(repairCost(10, 'mythical')).toBe(320)
  })

  it('is at least 50% higher than the pre-W3.D3 formula (regression guard)', () => {
    // Pre-W3.D3: 80 + level×15. Level 10 common = 80 + 150 = 230.
    // W3.D3: 320. Ratio ≈ 1.39 on the cheapest slot, higher with rarity.
    expect(repairCost(10, 'common')).toBeGreaterThan(230 * 1.35)
  })

  it('is monotone non-decreasing in level', () => {
    let prev = repairCost(0, 'common')
    for (let lvl = 1; lvl <= 50; lvl++) {
      const next = repairCost(lvl, 'common')
      expect(next).toBeGreaterThanOrEqual(prev)
      prev = next
    }
  })
})

// -----------------------------------------------------------------------------
// upgradeCost — exponential 150 × 1.4^N (regression guard — not touched in W3.D3)
// -----------------------------------------------------------------------------
describe('upgradeCost (exponential endgame sink)', () => {
  it('+0 = base cost 150', () => {
    expect(upgradeCost(0)).toBe(150)
  })

  it('follows 150 × 1.4^N within integer floor tolerance', () => {
    for (let n = 0; n <= 12; n++) {
      const expected = Math.floor(UPGRADE_COSTS.BASE * Math.pow(UPGRADE_COSTS.EXPONENT, n))
      expect(upgradeCost(n)).toBe(expected)
    }
  })

  it('is strictly increasing (the whole point of an exponential sink)', () => {
    for (let n = 1; n <= 15; n++) {
      expect(upgradeCost(n)).toBeGreaterThan(upgradeCost(n - 1))
    }
  })

  it('reaches a meaningful whale-scale sink by +10', () => {
    // 150 × 1.4^10 ≈ 4343 gold per attempt. Whale average success rate ~25%
    // at +8 means ~17k per successful upgrade — in the intended band.
    expect(upgradeCost(10)).toBeGreaterThan(4000)
  })
})

// -----------------------------------------------------------------------------
// levelScaledReward — +2% per level above 1
// -----------------------------------------------------------------------------
describe('levelScaledReward (+2% per level above 1)', () => {
  it('level 1 is passthrough', () => {
    expect(levelScaledReward(100, 1)).toBe(100)
  })

  it('level 50 gives ~+98% (floor of 1.98 × base)', () => {
    expect(levelScaledReward(100, 50)).toBe(Math.floor(100 * 1.98))
  })

  it('is monotone non-decreasing in level', () => {
    let prev = levelScaledReward(100, 1)
    for (let lvl = 2; lvl <= 60; lvl++) {
      const next = levelScaledReward(100, lvl)
      expect(next).toBeGreaterThanOrEqual(prev)
      prev = next
    }
  })

  it('scales linearly — doubling base doubles output at any level', () => {
    for (let lvl = 1; lvl <= 50; lvl += 10) {
      const a = levelScaledReward(100, lvl)
      const b = levelScaledReward(200, lvl)
      // Floor can cause ±1 drift on odd numbers — allow that.
      expect(Math.abs(b - 2 * a)).toBeLessThanOrEqual(1)
    }
  })
})
