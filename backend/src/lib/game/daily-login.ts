// =============================================================================
// daily-login.ts — Daily login reward logic
// =============================================================================

import { getDailyLoginRewardsConfig } from './live-config';
import { type DailyLoginRewardDef } from './balance';

/**
 * Minimum cooldown between daily login claims (20 hours).
 * Using 20h instead of 24h gives players a 4-hour flexibility window
 * so they can claim slightly earlier each day without losing their streak.
 * This prevents the old calendar-day exploit (claim at 23:59 + 00:01 UTC).
 */
const CLAIM_COOLDOWN_MS = 20 * 60 * 60 * 1000; // 20 hours

/**
 * Check whether the player is eligible to claim their daily login reward.
 * Returns true if 20+ hours have passed since the last claim, or if they
 * have never claimed before.
 *
 * Uses a fixed time cooldown (not calendar days) to prevent the midnight
 * UTC double-claim exploit.
 *
 * @param lastClaimDate  The date/time of the last claim, or null if never claimed
 * @returns              Whether the player can claim today
 */
export function canClaimDailyLogin(lastClaimDate: Date | null): boolean {
  if (!lastClaimDate) {
    return true;
  }

  const now = new Date();
  const elapsed = now.getTime() - lastClaimDate.getTime();

  return elapsed >= CLAIM_COOLDOWN_MS;
}

/**
 * Check whether the player's streak should be reset.
 * The streak resets if more than 48 hours have passed since the last claim,
 * meaning the player missed at least one full day.
 *
 * Uses fixed time comparison (not calendar days) for consistency with
 * the claim cooldown logic.
 *
 * @param lastClaimDate  The date/time of the last claim
 * @returns              Whether the streak should be reset to day 1
 */
export function shouldResetStreak(lastClaimDate: Date | null): boolean {
  if (!lastClaimDate) {
    return true;
  }

  const now = new Date();
  const elapsed = now.getTime() - lastClaimDate.getTime();
  const STREAK_RESET_MS = 48 * 60 * 60 * 1000; // 48 hours

  return elapsed >= STREAK_RESET_MS;
}

/**
 * Get the daily login reward for a given day in the cycle.
 *
 * Days cycle through the rewards from live config.
 *
 * @param day  The current streak day (1-based)
 * @returns    The reward definition for that day
 */
export async function getDailyReward(day: number): Promise<DailyLoginRewardDef> {
  const rewards = await getDailyLoginRewardsConfig();
  // Cycle through the reward table
  const index = ((day - 1) % rewards.length);
  return rewards[index];
}
