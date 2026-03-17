// =============================================================================
// stamina.ts — Stamina regeneration calculation
// =============================================================================

import { getStaminaConfig } from './live-config';

export interface StaminaResult {
  stamina: number;
  updated: boolean;
}

/**
 * Calculate the current stamina based on time elapsed since last update.
 *
 * Regenerates REGEN_RATE point(s) per REGEN_INTERVAL_MINUTES.
 * Capped at maxStamina.
 *
 * @param currentStamina   The stored stamina value
 * @param maxStamina       The character's maximum stamina
 * @param lastUpdate       Timestamp of the last stamina update
 * @returns                The new stamina value and whether it changed
 */
export async function calculateCurrentStamina(
  currentStamina: number,
  maxStamina: number,
  lastUpdate: Date,
): Promise<StaminaResult> {
  if (currentStamina >= maxStamina) {
    return { stamina: maxStamina, updated: false };
  }

  const staminaConfig = await getStaminaConfig();

  const now = Date.now();
  const elapsed = now - lastUpdate.getTime();
  const minutesElapsed = elapsed / (1000 * 60);

  const pointsToRegen = Math.floor(
    minutesElapsed / staminaConfig.REGEN_INTERVAL_MINUTES,
  ) * staminaConfig.REGEN_RATE;

  if (pointsToRegen <= 0) {
    return { stamina: currentStamina, updated: false };
  }

  const newStamina = Math.min(currentStamina + pointsToRegen, maxStamina);
  return {
    stamina: newStamina,
    updated: newStamina !== currentStamina,
  };
}
