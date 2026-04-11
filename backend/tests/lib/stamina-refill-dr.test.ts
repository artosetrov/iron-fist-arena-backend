/**
 * W3.D4 — Stamina refill diminishing returns.
 *
 * Tests the pure `staminaRefillGemCost` helper — no DB, no rate limits.
 * Pattern: Clash Royale chest slots + Genshin Fragile Resin cap.
 * See: docs/02_product_and_features/ECONOMY.md + balance.ts STAMINA_REFILL_DR
 */
import { describe, it, expect } from 'vitest';
import { staminaRefillGemCost, STAMINA_REFILL_DR } from '../../src/lib/game/balance';

describe('staminaRefillGemCost (W3.D4)', () => {
  const BASE = 30; // base cost per refill (matches GEM_COSTS.STAMINA_REFILL default)

  it('returns the base cost for the very first refill', () => {
    expect(staminaRefillGemCost(BASE, 0)).toBe(Math.ceil(BASE * STAMINA_REFILL_DR.COST_MULTIPLIERS[0]));
  });

  it('applies cost multipliers in order for refills 0..DAILY_CAP-1', () => {
    for (let i = 0; i < STAMINA_REFILL_DR.DAILY_CAP; i++) {
      const expected = Math.ceil(BASE * STAMINA_REFILL_DR.COST_MULTIPLIERS[i]);
      expect(staminaRefillGemCost(BASE, i)).toBe(expected);
    }
  });

  it('is strictly monotone increasing across the day', () => {
    let prev = staminaRefillGemCost(BASE, 0) ?? 0;
    for (let i = 1; i < STAMINA_REFILL_DR.DAILY_CAP; i++) {
      const cur = staminaRefillGemCost(BASE, i);
      expect(cur).not.toBeNull();
      expect(cur!).toBeGreaterThan(prev);
      prev = cur!;
    }
  });

  it('returns null once DAILY_CAP is reached (hard gate)', () => {
    expect(staminaRefillGemCost(BASE, STAMINA_REFILL_DR.DAILY_CAP)).toBeNull();
    expect(staminaRefillGemCost(BASE, STAMINA_REFILL_DR.DAILY_CAP + 5)).toBeNull();
    expect(staminaRefillGemCost(BASE, 999)).toBeNull();
  });

  it('defends against negative inputs (treats as 0)', () => {
    const expected = Math.ceil(BASE * STAMINA_REFILL_DR.COST_MULTIPLIERS[0]);
    expect(staminaRefillGemCost(BASE, -1)).toBe(expected);
    expect(staminaRefillGemCost(BASE, -100)).toBe(expected);
  });

  it('always rounds UP (ceil) so the treasury never rounds against itself', () => {
    // 29 × 1.5 = 43.5 → 44, not 43
    const cost1 = staminaRefillGemCost(29, 1);
    expect(cost1).toBe(44);

    // 31 × 2.5 = 77.5 → 78
    const cost2 = staminaRefillGemCost(31, 2);
    expect(cost2).toBe(78);
  });

  it('constants match the W3.D4 spec values', () => {
    expect(STAMINA_REFILL_DR.DAILY_CAP).toBe(4);
    expect(STAMINA_REFILL_DR.COST_MULTIPLIERS).toEqual([1, 1.5, 2.5, 4]);
  });

  it('full-day total cost is dramatically higher than a naive 4× flat price', () => {
    // Flat pricing: 4 refills × BASE = 120 gems
    // DR pricing: 1× + 1.5× + 2.5× + 4× = 9× BASE = 270 gems
    const flat = BASE * STAMINA_REFILL_DR.DAILY_CAP;
    let drTotal = 0;
    for (let i = 0; i < STAMINA_REFILL_DR.DAILY_CAP; i++) {
      drTotal += staminaRefillGemCost(BASE, i)!;
    }
    expect(drTotal).toBe(270);
    expect(drTotal).toBeGreaterThan(flat * 2);
  });
});
