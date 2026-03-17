// =============================================================================
// daily-login.ts — Daily login reward logic
// =============================================================================

import { getDailyLoginRewardsConfig, type DailyLoginRewardDef } from './live-config';

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
