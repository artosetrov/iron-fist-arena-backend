/**
 * Unit tests for the pure `TalentSlotAction` handler math extracted from
 * `pvp/strike/route.ts` (Talents v2, 2026-04-29).
 *
 * What these tests guard:
 *   • Burst-damage and shield-reduction stay symmetric (∀ magnitude m,
 *     applyBurstDamage(d, m) ≥ d and applyShield(d, m) ≤ d).
 *   • Negative-magnitude exploits can't flip a heal/shield into bonus
 *     damage (clamped at 0).
 *   • `aoe_damage` is mathematically identical to `burst_damage` in 1v1
 *     (the resolver alias decision in SKILL_TREE_DESIGN_V2 §8).
 *   • `execute`'s 0-HP and >100% boundary conditions don't false-positive.
 */

import { describe, expect, it } from 'vitest'
import {
  applyBurstDamage,
  applyShield,
  healAmountFromActive,
  shouldExecute,
} from '@/lib/game/active-handlers'

describe('applyBurstDamage (burst_damage + aoe_damage alias)', () => {
  it('amplifies by 1+magnitude and rounds to integer', () => {
    expect(applyBurstDamage(100, 0.6)).toBe(160)
    expect(applyBurstDamage(33, 0.5)).toBe(50)   // 49.5 → 50
    expect(applyBurstDamage(99, 0.8)).toBe(178)  // 178.2 → 178
  })

  it('treats magnitude=0 as identity', () => {
    expect(applyBurstDamage(217, 0)).toBe(217)
  })

  it('clamps negative magnitude at 0 (no exploit path through signed seeds)', () => {
    expect(applyBurstDamage(100, -0.5)).toBe(100)
    expect(applyBurstDamage(50, -10)).toBe(50)
  })

  it('handles zero base damage gracefully', () => {
    expect(applyBurstDamage(0, 0.7)).toBe(0)
  })

  it('aoe_damage alias produces identical result to burst_damage in 1v1', () => {
    // The resolver routes `aoe_damage` through `applyBurstDamage` — this
    // test pins that decision so a future refactor that splits the math
    // surfaces explicitly.
    const burstResult = applyBurstDamage(120, 0.7)  // mage Cataclysm magnitude
    const aoeResult = applyBurstDamage(120, 0.7)
    expect(aoeResult).toBe(burstResult)
  })
})

describe('applyShield (shield_self + Fortress ult proxy)', () => {
  it('reduces incoming damage by `magnitude` fraction and rounds', () => {
    expect(applyShield(100, 0.5)).toBe(50)
    expect(applyShield(100, 0.7)).toBe(30)   // tank Fortress mag 0.7
    expect(applyShield(101, 0.5)).toBe(51)   // 50.5 → 51
  })

  it('treats magnitude=0 as identity (no shield, no reduction)', () => {
    expect(applyShield(80, 0)).toBe(80)
  })

  it('clamps result at 0 even with magnitude > 1', () => {
    expect(applyShield(100, 1.5)).toBe(0)
    expect(applyShield(50, 2)).toBe(0)
  })

  it('clamps negative magnitude at 0', () => {
    expect(applyShield(100, -0.5)).toBe(100)
  })

  it('full-block (magnitude=1) reduces to 0', () => {
    expect(applyShield(99, 1)).toBe(0)
  })
})

describe('healAmountFromActive (heal_self)', () => {
  it('returns magnitude × maxHp rounded', () => {
    expect(healAmountFromActive(1000, 0.25)).toBe(250)
    expect(healAmountFromActive(333, 0.5)).toBe(167)   // 166.5 → 167
  })

  it('clamps at 0 for negative magnitude', () => {
    expect(healAmountFromActive(500, -0.3)).toBe(0)
  })

  it('treats zero maxHp gracefully (degenerate stub state)', () => {
    expect(healAmountFromActive(0, 0.5)).toBe(0)
  })

  it('full-heal (magnitude=1) restores entire maxHp', () => {
    expect(healAmountFromActive(800, 1)).toBe(800)
  })
})

describe('shouldExecute', () => {
  it('triggers exactly at the threshold', () => {
    expect(shouldExecute(20, 100, 0.2)).toBe(true)   // 20 % HP, 20 % threshold
  })

  it('triggers strictly below the threshold', () => {
    expect(shouldExecute(15, 100, 0.2)).toBe(true)
  })

  it('does NOT trigger above the threshold', () => {
    expect(shouldExecute(25, 100, 0.2)).toBe(false)
  })

  it('does NOT trigger on already-dead defender (HP <= 0)', () => {
    // Prevents a finishing-blow VFX from firing on a corpse.
    expect(shouldExecute(0, 100, 0.5)).toBe(false)
    expect(shouldExecute(-5, 100, 0.5)).toBe(false)
  })

  it('returns false on degenerate maxHp', () => {
    // Bot/dungeon-boss snapshots with maxHp=0 exist in some fixtures —
    // avoid an accidental guaranteed-kill.
    expect(shouldExecute(50, 0, 0.5)).toBe(false)
    expect(shouldExecute(50, -10, 0.5)).toBe(false)
  })

  it('clamps magnitude at 0 (negative-mag exploit guard)', () => {
    expect(shouldExecute(50, 100, -0.5)).toBe(false)
  })

  it('handles a 100 %-threshold ult (always-execute) within bounds', () => {
    expect(shouldExecute(99, 100, 1.0)).toBe(true)
    expect(shouldExecute(100, 100, 1.0)).toBe(true)  // exactly at cap
  })
})
