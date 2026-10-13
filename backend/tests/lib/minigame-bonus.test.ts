/**
 * Gold-mine minigame bonus derivation.
 *
 * Regression cover for two findings in the 2026-09-10 audit:
 *   - the gem cap shipped at 3 while the design note in the same file said 1;
 *   - the reward was the client's self-reported claim, merely clamped, so a
 *     scripted client always collected the maximum and the minigame was
 *     decorative.
 *
 * See: docs/10_operations/HEXBOUND_FULL_AUDIT_2026-09-10.md
 */
import { describe, it, expect } from 'vitest';
import {
  deriveMinigameBonus,
  MINIGAME_GEM_CAP,
  MINIGAME_GEM_CATCH_THRESHOLD,
  expectedSpawnCount,
} from '../../src/lib/game/shaft-catalog';

describe('MINIGAME_GEM_CAP', () => {
  it('matches the documented design value', () => {
    expect(MINIGAME_GEM_CAP).toBe(1);
  });
});

describe('deriveMinigameBonus', () => {
  const base = { capGold: 100, passivePool: 500 };

  it('pays nothing when nothing was caught', () => {
    expect(deriveMinigameBonus({ ...base, caught: 0, spawned: 40 })).toEqual({
      gold: 0,
      gems: 0,
      catchRatio: 0,
    });
  });

  it('pays the full cap for a perfect run', () => {
    const result = deriveMinigameBonus({ ...base, caught: 40, spawned: 40 });
    expect(result.gold).toBe(100);
    expect(result.gems).toBe(MINIGAME_GEM_CAP);
  });

  it('scales gold with the share of coins caught', () => {
    expect(deriveMinigameBonus({ ...base, caught: 20, spawned: 40 }).gold).toBe(50);
    expect(deriveMinigameBonus({ ...base, caught: 10, spawned: 40 }).gold).toBe(25);
  });

  it('never pays more gold than the passive pool holds', () => {
    const result = deriveMinigameBonus({
      capGold: 100,
      passivePool: 30,
      caught: 40,
      spawned: 40,
    });
    expect(result.gold).toBe(30);
  });

  it('awards the gem only at or above the catch threshold', () => {
    const spawned = 100;
    const justBelow = Math.floor(MINIGAME_GEM_CATCH_THRESHOLD * spawned) - 1;
    const atThreshold = Math.ceil(MINIGAME_GEM_CATCH_THRESHOLD * spawned);

    expect(deriveMinigameBonus({ ...base, caught: justBelow, spawned }).gems).toBe(0);
    expect(deriveMinigameBonus({ ...base, caught: atThreshold, spawned }).gems).toBe(
      MINIGAME_GEM_CAP,
    );
  });

  it('clamps an inflated catch count to the spawn count instead of scaling past it', () => {
    // `caught` is still client-reported, so the guarantee here is a BOUND, not
    // proof of play: a claim of 9999 catches out of 40 spawns pays the same as
    // a perfect run and never more. `spawned` itself must come from the server
    // (expectedSpawnCount, pinned into the session at /start) — passing a
    // client-supplied value here would make the ratio meaningless.
    const result = deriveMinigameBonus({ ...base, caught: 9999, spawned: 40 });
    expect(result.catchRatio).toBe(1);
    expect(result.gold).toBe(100); // the cap, never more
    expect(result.gems).toBe(MINIGAME_GEM_CAP);
  });

  it('uses a stable server-side spawn count', () => {
    // Pinned per session so a later balance tweak cannot retroactively change
    // the denominator of a session already in flight.
    expect(expectedSpawnCount()).toBe(164);
    expect(Number.isInteger(expectedSpawnCount())).toBe(true);
  });

  it('treats a session with no spawns as a zero payout, not a division by zero', () => {
    const result = deriveMinigameBonus({ ...base, caught: 5, spawned: 0 });
    expect(result.catchRatio).toBe(0);
    expect(result.gold).toBe(0);
    expect(result.gems).toBe(0);
    expect(Number.isNaN(result.catchRatio)).toBe(false);
  });
});
