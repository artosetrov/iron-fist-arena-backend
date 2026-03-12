// =============================================================================
// daily-login.ts — Daily login reward logic
// =============================================================================

import { DAILY_LOGIN_REWARDS, type DailyLoginRewardDef } from './balance';

/**
 * Check whether the player is eligible to claim their daily login reward.
 * Returns true if 24+ hours have passed since the last claim, or if they
 * have never claimed before.
 *
 * @param lastClaimDate  The date/time of the last claim, or null if never claimed
 * @returns              Whether the player can claim today
 */
export function canClaimDailyLogin(lastClaimDate: Date | null): boolean {
  if (!lastClaimDate) {
    return true;
  }

  // Compare calendar days in UTC — claim resets at midnight UTC
  const now = new Date();
  const todayUTC = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  const lastUTC = Date.UTC(lastClaimDate.getUTCFullYear(), lastClaimDate.getUTCMonth(), lastClaimDate.getUTCDate());

  return todayUTC > lastUTC;
}

/**
 * Check whether the player's streak should be reset.
 * The streak resets if more than 48 hours have passed since the last claim.
 *
 * @param lastClaimDate  The date/time of the last claim
 * @returns              Whether the streak should be reset to day 1
 */
export function shouldResetStreak(lastClaimDate: Date | null): boolean {
  if (!lastClaimDate) {
    return true;
  }

  // Streak resets if the player missed a full calendar day (2+ days gap)
  const now = new Date();
  const todayUTC = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  const lastUTC = Date.UTC(lastClaimDate.getUTCFullYear(), lastClaimDate.getUTCMonth(), lastClaimDate.getUTCDate());
  const daysDiff = (todayUTC - lastUTC) / (1000 * 60 * 60 * 24);

  return daysDiff >= 2;
}

/**
 * Get the daily login reward for a given day in the 7-day cycle.
 *
 * Days cycle: 1-7, 1-7, 1-7, ...
 *
 * @param day  The current streak day (1-based)
 * @returns    The reward definition for that day
 */
export function getDailyReward(day: number): DailyLoginRewardDef {
  // Cycle through the 7-day reward table
  const index = ((day - 1) % DAILY_LOGIN_REWARDS.length);
  return DAILY_LOGIN_REWARDS[index];
}
