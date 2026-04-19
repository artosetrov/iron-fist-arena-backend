/**
 * Hexbound analytics — provider-agnostic event tracking.
 *
 * Contract-first: the 7 critical-funnel events are strongly typed below.
 * Swapping the backend (Firebase, Mixpanel, Segment, Amplitude) happens in
 * exactly one place — `setAnalyticsBackend()` — and does not require touching
 * call-sites.
 *
 * Defaults to `NoopBackend`, which logs to stdout when
 * `ANALYTICS_DEBUG=true` and is silent otherwise. Chosen so the event schema
 * can ship to production before the SDK decision lands.
 *
 * Current boundary: this generic analytics layer is still a dormant scaffold.
 * The typed event contract exists, but there are no live backend emitters
 * wired into request/runtime flows yet. The active instrumentation path today
 * is `backend/src/lib/game/tutorial-analytics.ts`.
 *
 * Call-site rule: `track()` is fire-and-forget. Never await it, never let it
 * throw into request handlers. A failed analytics write must not degrade user
 * experience or produce 500s.
 */

export type AuthProvider = 'email' | 'guest' | 'google' | 'apple'

/**
 * Strongly-typed critical-funnel events. Adding a new event type here
 * forces every backend implementation to handle it — the union is exhaustive
 * by construction.
 */
export type AnalyticsEvent =
  | {
      name: 'signup'
      userId: string
      authProvider: AuthProvider
      hasUsername: boolean
    }
  | {
      name: 'first_pvp'
      userId: string
      characterId: string
      won: boolean
      totalTurns: number
      ratingAfter: number
    }
  | {
      name: 'iap_purchase'
      userId: string
      productId: string
      transactionId: string
      gemsAwarded: number
      goldAwarded: number
    }
  | {
      name: 'bp_claim'
      userId: string
      characterId: string
      seasonId: string
      level: number
      isPremium: boolean
    }
  | {
      name: 'daily_login'
      userId: string
      characterId: string
      day: number
      streak: number
      resetStreak: boolean
    }
  | {
      name: 'level_up'
      userId: string
      characterId: string
      fromLevel: number
      toLevel: number
    }
  | {
      name: 'shop_upgrade'
      userId: string
      characterId: string
      itemId: string
      catalogId: string
      fromLevel: number
      toLevel: number
      success: boolean
    }

export type EventName = AnalyticsEvent['name']

export interface AnalyticsBackend {
  track(event: AnalyticsEvent): Promise<void>
}

class NoopBackend implements AnalyticsBackend {
  async track(event: AnalyticsEvent): Promise<void> {
    if (process.env.ANALYTICS_DEBUG === 'true') {
      console.log(`[analytics] ${event.name}`, event)
    }
  }
}

let backend: AnalyticsBackend = new NoopBackend()

/**
 * Swap in a real SDK backend (Firebase / Mixpanel / Segment / Amplitude) at
 * app startup. Typically called once from a bootstrap module.
 */
export function setAnalyticsBackend(b: AnalyticsBackend): void {
  backend = b
}

/**
 * Fire-and-forget track. Never throws, never awaits into the caller's request
 * path, logs failures to stderr. Safe to call anywhere — including inside
 * Prisma transactions (though track() should generally be called *after* the
 * transaction commits so we don't emit events for rolled-back operations).
 */
export function track(event: AnalyticsEvent): void {
  try {
    void backend.track(event).catch((err) => {
      console.error(`[analytics] ${event.name} track failed:`, err)
    })
  } catch (err) {
    console.error(`[analytics] ${event.name} synchronous track error:`, err)
  }
}
