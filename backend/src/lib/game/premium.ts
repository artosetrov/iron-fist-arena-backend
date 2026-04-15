// =============================================================================
// premium.ts — Premium entitlement helpers (W3.D5 — IAP-02)
// =============================================================================
//
// Premium can come from two sources:
//   1. Premium Forever (premiumUntil set far in the future)
//   2. Premium Pass subscription (premiumSubscription row)
//
// Shared benefits:
//   1. +10% gold multiplier on ALL gold income
//   2. +25 gems/day on Daily Login
//   3. Premium cosmetic/title entitlements handled elsewhere
//
// Design notes:
//   - The gold multiplier is applied at the END of the reward stack — after
//     CHA bonus, streak, level scaling — so it doesn't compound with CHA.
//   - hasPremium() is pure — give it the fields it needs, it doesn't touch
//     the DB. This lets callers batch-fetch at the top of a transaction.

export const PREMIUM_ENTITLEMENT_USER_SELECT = {
  premiumUntil: true,
  premiumSubscription: {
    select: {
      expiresAt: true,
      status: true,
    },
  },
} as const

const ACTIVE_PREMIUM_SUBSCRIPTION_STATUSES = new Set(['active', 'grace_period'])

export interface PremiumSubscriptionFields {
  readonly expiresAt: Date
  readonly status: string
}

export interface PremiumUserFields {
  readonly premiumUntil: Date | null
  readonly activeSubscriptionExpiresAt?: Date | null
  readonly premiumSubscription?: PremiumSubscriptionFields | null
}

/** Premium gold bonus — +10% on all gold income. */
export const PREMIUM_GOLD_MULTIPLIER = 1.10

/** Premium daily gems — 25 gems claimable once per UTC day. */
export const PREMIUM_DAILY_GEMS = 25

export function getActivePremiumSubscriptionExpiresAt(
  subscription: PremiumSubscriptionFields | null | undefined,
): Date | null {
  if (!subscription) return null
  return ACTIVE_PREMIUM_SUBSCRIPTION_STATUSES.has(subscription.status)
    ? subscription.expiresAt
    : null
}

export function getPremiumExpiresAt(
  user: PremiumUserFields,
): Date | null {
  const subscriptionExpiresAt =
    user.activeSubscriptionExpiresAt
    ?? getActivePremiumSubscriptionExpiresAt(user.premiumSubscription)

  if (!user.premiumUntil) return subscriptionExpiresAt
  if (!subscriptionExpiresAt) return user.premiumUntil

  return user.premiumUntil.getTime() >= subscriptionExpiresAt.getTime()
    ? user.premiumUntil
    : subscriptionExpiresAt
}

/**
 * Is this user currently Premium via Forever ownership or an active Pass?
 */
export function hasPremium(
  user: PremiumUserFields,
  now: Date = new Date(),
): boolean {
  const nowMs = now.getTime()
  const premiumExpiresAt = getPremiumExpiresAt(user)
  if (premiumExpiresAt && premiumExpiresAt.getTime() > nowMs) return true
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
