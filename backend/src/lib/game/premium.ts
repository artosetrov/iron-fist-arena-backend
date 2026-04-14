// =============================================================================
// premium.ts — Premium Forever entitlement helpers (W3.D5 — IAP-02)
// =============================================================================
//
// Premium Forever is a one-time $9.99 IAP that grants:
//   1. +10% gold multiplier on ALL gold income (PvP wins, dungeons, chests)
//   2. +25 gems/day claim on Daily Login
//   3. "Chosen" cosmetic title
//   4. Ad-free (existing behavior, not relevant to backend)
//
// Design notes:
//   - The gold multiplier is applied at the END of the reward stack — after
//     CHA bonus, streak, level scaling — so it doesn't compound with CHA
//     (which is capped at +80%, see W3.D3 CHA_GOLD_BONUS_CAP). Protecting
//     the sink-ratio work from W3.D3 is explicit.
//   - Ownership check uses premiumUntil > now. For Premium Forever the value
//     is set to 2099-12-31 in verify-receipt, so effectively any user with a
//     future premiumUntil date is a Premium holder.
//   - hasPremium() is pure — give it the fields it needs, it doesn't touch
//     the DB. This lets callers batch-fetch at the top of a transaction.

export interface PremiumUserFields {
  readonly premiumUntil: Date | null
  // Phase 2 (2026-04-14) — Premium Pass subscription. Null for users without a
  // subscription row, or for legacy Premium Forever owners (who use premiumUntil).
  // hasPremium() returns true if EITHER source is active — so grandfathered
  // Forever owners keep access indefinitely, and subscribers get access while
  // their subscription is in good standing.
  // Pass the expiresAt value from the PremiumSubscription row, but ONLY when
  // status is 'active' or 'grace_period' — expired/refunded rows should be null.
  readonly activeSubscriptionExpiresAt?: Date | null
}

/** Premium gold bonus — +10% on all gold income. */
export const PREMIUM_GOLD_MULTIPLIER = 1.10

/** Premium daily gems — 25 gems claimable once per UTC day. */
export const PREMIUM_DAILY_GEMS = 25

/**
 * Is this user currently a Premium Forever (or any future premium SKU)
 * holder? Premium is active iff premiumUntil is set AND in the future.
 */
export function hasPremium(
  user: PremiumUserFields,
  now: Date = new Date(),
): boolean {
  const nowMs = now.getTime()
  if (user.premiumUntil && user.premiumUntil.getTime() > nowMs) return true
  if (user.activeSubscriptionExpiresAt && user.activeSubscriptionExpiresAt.getTime() > nowMs) return true
  return false
}

/**
 * Gold multiplier to apply at the END of the reward stack.
 *   - non-premium → 1.0 (no-op)
 *   - premium     → PREMIUM_GOLD_MULTIPLIER (1.10)
 *
 * Usage:
 *   const finalGold = Math.floor(baseGold * streakMul * chaMul * goldBonusMultiplier(user))
 *
 * IMPORTANT: apply AFTER CHA to avoid compounding with the W3.D3 CHA cap.
 */
export function goldBonusMultiplier(
  user: PremiumUserFields,
  now: Date = new Date(),
): number {
  return hasPremium(user, now) ? PREMIUM_GOLD_MULTIPLIER : 1.0
}

/**
 * Has this user already claimed their Premium daily gems today (UTC)?
 * Compares premiumGemClaimDate to today's UTC date (yyyy-mm-dd).
 */
export function hasPremiumGemsClaimedToday(
  premiumGemClaimDate: Date | null,
  now: Date = new Date(),
): boolean {
  if (!premiumGemClaimDate) return false
  const todayUtc = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
  )
  const claimUtc = new Date(
    Date.UTC(
      premiumGemClaimDate.getUTCFullYear(),
      premiumGemClaimDate.getUTCMonth(),
      premiumGemClaimDate.getUTCDate(),
    ),
  )
  return claimUtc.getTime() === todayUtc.getTime()
}
