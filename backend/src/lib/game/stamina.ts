// =============================================================================
// stamina.ts — Stamina regeneration calculation
// =============================================================================

import { STAMINA } from './balance';

export interface StaminaResult {
  stamina: number;
  updated: boolean;
}

/**
 * Calculate the current stamina based on time elapsed since last update.
 *
 * Regenerates 1 point per REGEN_INTERVAL_MINUTES (8 min by default).
 * Capped at maxStamina.
 *
 * @param currentStamina   The stored stamina value
 * @param maxStamina       The character's maximum stamina
 * @param lastUpdate       Timestamp of the last stamina update
 * @returns                The new stamina value and whether it changed
 */
export function calculateCurrentStamina(
  currentStamina: number,
  maxStamina: number,
  lastUpdate: Date,
): StaminaResult {
  if (currentStamina >= maxStamina) {
    return { stamina: maxStamina, updated: false };
  }

  const now = Date.now();
  const elapsed = now - lastUpdate.getTime();
  const minutesElapsed = elapsed / (1000 * 60);

  const pointsToRegen = Math.floor(
    minutesElapsed / STAMINA.REGEN_INTERVAL_MINUTES,
  ) * STAMINA.REGEN_RATE;

  if (pointsToRegen <= 0) {
    return { stamina: currentStamina, updated: false };
  }

  const newStamina = Math.min(currentStamina + pointsToRegen, maxStamina);
  return {
    stamina: newStamina,
    updated: newStamina !== currentStamina,
  };
}
