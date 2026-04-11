/**
 * W3.D4 — Training XP diminishing returns.
 *
 * Tests the pure `trainingXpMultiplier` helper — no DB, no RNG.
 * Pattern: LoL First Win of the Day + RAID dungeon XP brew farming.
 * See: docs/06_game_systems/COMBAT.md + balance.ts TRAINING_XP_DR
 */
import { describe, it, expect } from 'vitest';
import { trainingXpMultiplier, TRAINING_XP_DR } from '../../src/lib/game/balance';

describe('trainingXpMultiplier (W3.D4)', () => {
  const FULL = TRAINING_XP_DR.FULL_XP_CLEARS;
  const HALF = TRAINING_XP_DR.HALF_XP_CLEARS;
  const FLOOR = TRAINING_XP_DR.FLOOR_MULTIPLIER;

  it('returns 1.0 for the very first clear of the day', () => {
    expect(trainingXpMultiplier(0)).toBe(1);
  });

  it('returns 1.0 while inside the full-XP window', () => {
    for (let i = 0; i < FULL; i++) {
      expect(trainingXpMultiplier(i)).toBe(1);
    }
  });

  it('drops to 0.5 on the clear that first exits the full-XP window', () => {
    expect(trainingXpMultiplier(FULL)).toBe(0.5);
  });

  it('stays at 0.5 across the entire half-XP window', () => {
    for (let i = FULL; i < FULL + HALF; i++) {
      expect(trainingXpMultiplier(i)).toBe(0.5);
    }
  });

  it('drops to floor multiplier after the half-XP window', () => {
    expect(trainingXpMultiplier(FULL + HALF)).toBe(FLOOR);
  });

  it('stays at floor for arbitrarily large counts (never zero)', () => {
    expect(trainingXpMultiplier(100)).toBe(FLOOR);
    expect(trainingXpMultiplier(10_000)).toBe(FLOOR);
  });

  it('never returns 0 — anti-brick guarantee', () => {
    // A player who wants to keep playing still gets SOME XP.
    for (let i = 0; i <= 50; i++) {
      expect(trainingXpMultiplier(i)).toBeGreaterThan(0);
    }
  });

  it('defends against negative inputs (treats as 0)', () => {
    expect(trainingXpMultiplier(-1)).toBe(1);
    expect(trainingXpMultiplier(-999)).toBe(1);
  });

  it('constants match the W3.D4 spec values', () => {
    expect(TRAINING_XP_DR.FULL_XP_CLEARS).toBe(6);
    expect(TRAINING_XP_DR.HALF_XP_CLEARS).toBe(6);
    expect(TRAINING_XP_DR.FLOOR_MULTIPLIER).toBe(0.1);
  });

  it('creates a monotone non-increasing curve across the day', () => {
    let prev = trainingXpMultiplier(0);
    for (let i = 1; i <= 30; i++) {
      const cur = trainingXpMultiplier(i);
      expect(cur).toBeLessThanOrEqual(prev);
      prev = cur;
    }
  });
});
