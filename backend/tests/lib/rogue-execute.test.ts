/**
 * W3.D2 — Rogue Execute finisher.
 *
 * Tests the pure `applyRogueExecute` helper directly — no DB, no RNG.
 * See: docs/06_game_systems/COMBAT.md "Rogue Execute"
 */
import { describe, it, expect } from 'vitest';
import { applyRogueExecute } from '../../src/lib/game/combat';
import { COMBAT } from '../../src/lib/game/balance';

const cfg = {
  ROGUE_EXECUTE_HP_THRESHOLD: COMBAT.ROGUE_EXECUTE_HP_THRESHOLD,
  ROGUE_EXECUTE_DAMAGE_BONUS: COMBAT.ROGUE_EXECUTE_DAMAGE_BONUS,
};

describe('applyRogueExecute (W3.D2)', () => {
  it('boosts damage when rogue attacks a defender at or below HP threshold', () => {
    // Defender at 35% HP (exactly threshold) — should trigger
    const result = applyRogueExecute(100, 'rogue', 35, 100, cfg);
    expect(result).toBeCloseTo(100 * (1 + cfg.ROGUE_EXECUTE_DAMAGE_BONUS), 5);
  });

  it('boosts damage when rogue attacks a defender well below threshold', () => {
    // Defender at 10% HP
    const result = applyRogueExecute(100, 'rogue', 10, 100, cfg);
    expect(result).toBeCloseTo(115, 5);
  });

  it('does NOT boost damage when defender HP ratio exceeds threshold', () => {
    // Defender at 36% HP — just above threshold (assuming default 0.35)
    const result = applyRogueExecute(100, 'rogue', 36, 100, cfg);
    expect(result).toBe(100);
  });

  it('does NOT boost damage when defender is at full HP', () => {
    const result = applyRogueExecute(100, 'rogue', 100, 100, cfg);
    expect(result).toBe(100);
  });

  it('does NOT boost damage for non-rogue classes even at low HP', () => {
    const warriorResult = applyRogueExecute(100, 'warrior', 10, 100, cfg);
    const mageResult = applyRogueExecute(100, 'mage', 10, 100, cfg);
    const tankResult = applyRogueExecute(100, 'tank', 10, 100, cfg);
    expect(warriorResult).toBe(100);
    expect(mageResult).toBe(100);
    expect(tankResult).toBe(100);
  });

  it('handles zero max HP defensively without NaN/Infinity', () => {
    const result = applyRogueExecute(100, 'rogue', 0, 0, cfg);
    expect(result).toBe(100);
  });

  it('handles defender at exactly 0 current HP (overkill scenario)', () => {
    // 0 / 100 = 0 — below threshold, should still boost
    const result = applyRogueExecute(100, 'rogue', 0, 100, cfg);
    expect(result).toBeCloseTo(115, 5);
  });

  it('respects the balance.ts constants (sanity check)', () => {
    expect(cfg.ROGUE_EXECUTE_HP_THRESHOLD).toBe(0.35);
    expect(cfg.ROGUE_EXECUTE_DAMAGE_BONUS).toBe(0.15);
  });
});
