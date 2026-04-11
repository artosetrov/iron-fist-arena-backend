/**
 * W3.D1 — CHA miss chance (replaces legacy intimidation damage reduction).
 *
 * Tests the pure `chaMissChance` helper directly — no RNG, no DB.
 * See: docs/06_game_systems/COMBAT.md "CHA Miss Chance"
 */
import { describe, it, expect } from 'vitest';
import { chaMissChance } from '../../src/lib/game/combat';
import { COMBAT } from '../../src/lib/game/balance';

const cfg = {
  CHA_MISS_PER_POINT: COMBAT.CHA_MISS_PER_POINT,
  CHA_MISS_CAP: COMBAT.CHA_MISS_CAP,
};

describe('chaMissChance (W3.D1)', () => {
  it('returns 0 when defender CHA is zero', () => {
    expect(chaMissChance(0, cfg)).toBe(0);
  });

  it('returns 0 when defender CHA is negative (defensive)', () => {
    expect(chaMissChance(-5, cfg)).toBe(0);
  });

  it('scales linearly with CHA below the cap', () => {
    // 10 CHA * 0.2%/pt = 2%
    expect(chaMissChance(10, cfg)).toBeCloseTo(2, 5);
    // 50 CHA * 0.2%/pt = 10%
    expect(chaMissChance(50, cfg)).toBeCloseTo(10, 5);
  });

  it('caps miss chance at CHA_MISS_CAP', () => {
    // 200 CHA would uncapped = 40%, but cap is 20
    expect(chaMissChance(200, cfg)).toBe(cfg.CHA_MISS_CAP);
  });

  it('reaches the cap exactly at CHA = cap / per_point', () => {
    const breakEven = cfg.CHA_MISS_CAP / cfg.CHA_MISS_PER_POINT; // 20 / 0.2 = 100
    expect(chaMissChance(breakEven, cfg)).toBe(cfg.CHA_MISS_CAP);
    expect(chaMissChance(breakEven + 1, cfg)).toBe(cfg.CHA_MISS_CAP);
    expect(chaMissChance(breakEven - 1, cfg)).toBeLessThan(cfg.CHA_MISS_CAP);
  });

  it('uses balance.ts constants as source of truth', () => {
    expect(cfg.CHA_MISS_PER_POINT).toBe(0.2);
    expect(cfg.CHA_MISS_CAP).toBe(20);
  });

  it('is monotonic non-decreasing in CHA', () => {
    let prev = -1;
    for (let cha = 0; cha <= 150; cha += 5) {
      const val = chaMissChance(cha, cfg);
      expect(val).toBeGreaterThanOrEqual(prev);
      prev = val;
    }
  });
});
