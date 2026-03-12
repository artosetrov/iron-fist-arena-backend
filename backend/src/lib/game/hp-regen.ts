// =============================================================================
// hp-regen.ts — HP regeneration calculation
// =============================================================================

import { HP_REGEN } from './balance';

export interface HpRegenResult {
  hp: number;
  updated: boolean;
}

/**
 * Calculate the current HP based on time elapsed since last update.
 *
 * Regenerates REGEN_RATE% of maxHp per REGEN_INTERVAL_MINUTES (default: 1% every 5 min).
 * Capped at maxHp.
 */
export function calculateCurrentHp(
  currentHp: number,
  maxHp: number,
  lastUpdate: Date,
): HpRegenResult {
  if (currentHp >= maxHp) {
    return { hp: maxHp, updated: false };
  }

  const now = Date.now();
  const elapsed = now - lastUpdate.getTime();
  const minutesElapsed = elapsed / (1000 * 60);

  const intervals = Math.floor(
    minutesElapsed / HP_REGEN.REGEN_INTERVAL_MINUTES,
  );

  if (intervals <= 0) {
    return { hp: currentHp, updated: false };
  }

  const regenAmount = Math.floor(maxHp * HP_REGEN.REGEN_RATE * intervals / 100);

  if (regenAmount <= 0) {
    return { hp: currentHp, updated: false };
  }

  const newHp = Math.min(currentHp + regenAmount, maxHp);
  return {
    hp: newHp,
    updated: newHp !== currentHp,
  };
}
