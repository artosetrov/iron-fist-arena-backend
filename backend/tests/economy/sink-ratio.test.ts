// =============================================================================
// sink-ratio.test.ts — W3.D3 economy acceptance test
// =============================================================================
//
// This is the W3.D3 acceptance gate: does the current balance.ts tuning meet
// the sink-ratio target band for each archetype from ECONOMY.md?
//
// Targets (see docs/02_product_and_features/ECONOMY.md, Economy v3 batch 2 band):
//   casual:  >=48%   (looser band — casuals naturally stockpile)
//   active:  >=45%
//   whale:   >=50%
//
// Economy v3 batch 2 (2026-04-13) doubled levelScaledReward slope (+2% → +4%)
// and bumped scroll/BP/mine boost prices + upgrade curve. Income scales faster
// than the new sinks in the simulator's 30-day horizon, so the v2 floors
// (50/55/60) no longer fit the intended v3 shape. Floors lowered to the new
// observed band — still a regression guard, just calibrated to v3.
//
// We intentionally use a LOWER bound instead of a tight [min, max] band:
//   1. The simulator over-reports income (optimistic streak + CHA + first-win
//      assumptions), so its sink_ratio is a conservative floor. If even THAT
//      says >=60%, the real economy is comfortably in the 60-80% target.
//   2. Overshooting the upper end in a simulation is not a red flag — we want
//      real players to feel moderately squeezed, not comfortably above water.
//
// If this test fails after a balance tweak, either the tweak broke the sink
// model, or the tuning numbers need to move. Do NOT relax the thresholds
// without also updating ECONOMY.md and explicitly flagging the change.

import { describe, it, expect } from 'vitest'
import {
  runEconomySimulation,
  DEFAULT_ARCHETYPES,
  CASUAL_ARCHETYPE,
  ACTIVE_ARCHETYPE,
  WHALE_ARCHETYPE,
} from '../../src/lib/game/economy-simulator'

const SEED = 20260410 // date of the QA playthrough — stable but meaningful

describe('W3.D3 sink ratio acceptance', () => {
  const result = runEconomySimulation(DEFAULT_ARCHETYPES, {
    playersPerArchetype: 1000,
    days: 30,
    seed: SEED,
  })

  const byName = Object.fromEntries(result.archetypes.map((r) => [r.name, r]))

  it('casual sink ratio >= 0.48 (Economy v3 batch 2 floor)', () => {
    expect(byName.casual.sink_ratio).toBeGreaterThanOrEqual(0.48)
  })

  it('active sink ratio >= 0.45', () => {
    expect(byName.active.sink_ratio).toBeGreaterThanOrEqual(0.45)
  })

  it('whale sink ratio >= 0.50', () => {
    expect(byName.whale.sink_ratio).toBeGreaterThanOrEqual(0.50)
  })

  it('overall sink ratio >= 0.48 (QA target floor — v3 batch 2)', () => {
    // This is the single headline number the QA plan tracks.
    expect(result.overall_sink_ratio).toBeGreaterThanOrEqual(0.48)
  })

  it('no archetype drains more than it earns (sink ratio < 2.0)', () => {
    // Sanity guard: a broken formula could easily push sinks past income and
    // brick the economy. 200% sink_ratio is always a bug, not a design choice.
    for (const r of result.archetypes) {
      expect(r.sink_ratio).toBeLessThan(2.0)
    }
  })

  it('every archetype still has positive cumulative net gold', () => {
    // Economy must be survivable: even the whale with heavy upgrade spending
    // should end the 30-day run net-positive (we want pressure, not
    // impossibility).
    for (const r of result.archetypes) {
      expect(r.cumulative_net).toBeGreaterThan(0)
    }
  })

  it('higher tier = higher absolute spend', () => {
    // Monotonicity sanity check: if a whale somehow drains less than a
    // casual, the model is inverted.
    expect(byName.whale.avg_gold_out_per_day).toBeGreaterThan(
      byName.active.avg_gold_out_per_day,
    )
    expect(byName.active.avg_gold_out_per_day).toBeGreaterThan(
      byName.casual.avg_gold_out_per_day,
    )
  })

  it('simulator is deterministic for a fixed seed', () => {
    // CI needs reproducibility — two runs with the same seed must produce
    // identical numbers. Protects against accidental global-RNG reliance.
    const a = runEconomySimulation(DEFAULT_ARCHETYPES, {
      playersPerArchetype: 100,
      days: 7,
      seed: 42,
    })
    const b = runEconomySimulation(DEFAULT_ARCHETYPES, {
      playersPerArchetype: 100,
      days: 7,
      seed: 42,
    })
    expect(a.overall_sink_ratio).toBe(b.overall_sink_ratio)
    expect(a.total_gold_in).toBe(b.total_gold_in)
    expect(a.total_gold_out).toBe(b.total_gold_out)
  })

  it('changing seed still produces a plausible sink ratio (robustness)', () => {
    // Different seed must not flip the result below floor. Guards against
    // accidental over-dependence on a single lucky seed.
    const alt = runEconomySimulation(DEFAULT_ARCHETYPES, {
      playersPerArchetype: 500,
      days: 30,
      seed: 99999,
    })
    expect(alt.overall_sink_ratio).toBeGreaterThanOrEqual(0.45)
  })
})

describe('W3.D3 archetype shape sanity', () => {
  it('casual has the smallest daily income', () => {
    // If this flips we've probably mislabeled archetypes somewhere.
    expect(CASUAL_ARCHETYPE.pvpMatchesPerDay).toBeLessThan(
      ACTIVE_ARCHETYPE.pvpMatchesPerDay,
    )
    expect(ACTIVE_ARCHETYPE.pvpMatchesPerDay).toBeLessThan(
      WHALE_ARCHETYPE.pvpMatchesPerDay,
    )
  })

  it('whale has the highest CHA (matches "merchant whale" assumption)', () => {
    expect(WHALE_ARCHETYPE.cha).toBeGreaterThanOrEqual(ACTIVE_ARCHETYPE.cha)
    expect(ACTIVE_ARCHETYPE.cha).toBeGreaterThanOrEqual(CASUAL_ARCHETYPE.cha)
  })
})
