/**
 * Hexbound analytics — provider-agnostic event tracking.
 *
 * Contract-first: the 7 critical-funnel events are strongly typed below.
 * Swapping the backend (Firebase, Mixpanel, Segment, Amplitude) happens in
 * exactly one place — `setAnalyticsBackend()` — and does not require touching
 * call-sites.
 *
 * Default backend is `PrismaBackend` → `analytics_events` table (since
 * 2026-10-13; before that events went to a NoopBackend and were lost).
 * `ANALYTICS_BACKEND=noop` disables persistence; tests always use Noop.
 * The admin "Analytics" page reads the table for funnels and retention.
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

/**
 * Client-originated events (iOS). Allowlisted so the public ingest route
 * cannot be used to pollute the table. Keep in sync with
 * `Hexbound/Hexbound/Services/AnalyticsService.swift` ClientEvent.
 */
export const CLIENT_EVENT_NAMES = [
  'session_start',
  'screen_view',
  'onboarding_step',
  'tutorial_complete',
  'iap_started',
  'iap_failed',
  'dungeon_run_start',
  'dungeon_run_end',
  'shop_purchase',
  'pvp_fight_start',
] as const
export type ClientEventName = (typeof CLIENT_EVENT_NAMES)[number]

export interface ClientEvent {
  name: ClientEventName
  userId: string
  characterId?: string | null
  props?: Record<string, unknown>
  /** Client timestamp (ms). Clamped server-side to ±1 day. */
  ts?: number
}

export interface AnalyticsBackend {
  track(event: AnalyticsEvent): Promise<void>
  trackClient?(events: ClientEvent[]): Promise<void>
}

class NoopBackend implements AnalyticsBackend {
  async track(event: AnalyticsEvent): Promise<void> {
    if (process.env.ANALYTICS_DEBUG === 'true') {
      console.log(`[analytics] ${event.name}`, event)
    }
  }
  async trackClient(): Promise<void> {}
}

/**
 * Default production backend: one row per event in `analytics_events`.
 * Prisma is imported lazily so unit tests that never touch the DB (and mock
 * `@/lib/prisma`) are unaffected. Set ANALYTICS_BACKEND=noop to disable.
 */
class PrismaBackend implements AnalyticsBackend {
  private async db() {
    const { prisma } = await import('@/lib/prisma')
    return prisma
  }

  async track(event: AnalyticsEvent): Promise<void> {
    const { name, userId, ...rest } = event
    const characterId = 'characterId' in rest ? (rest as { characterId?: string }).characterId ?? null : null
    const prisma = await this.db()
    await prisma.analyticsEvent.create({
      data: { name, userId, characterId, source: 'server', props: rest as object },
    })
    if (process.env.ANALYTICS_DEBUG === 'true') console.log(`[analytics] ${name}`, event)
  }

  async trackClient(events: ClientEvent[]): Promise<void> {
    if (events.length === 0) return
    const now = Date.now()
    const dayMs = 24 * 60 * 60 * 1000
    const prisma = await this.db()
    await prisma.analyticsEvent.createMany({
      data: events.map((e) => ({
        name: e.name,
        userId: e.userId,
        characterId: e.characterId ?? null,
        source: 'ios',
        props: (e.props ?? {}) as object,
        createdAt: new Date(
          typeof e.ts === 'number' ? Math.min(now + dayMs, Math.max(now - dayMs, e.ts)) : now,
        ),
      })),
    })
  }
}

const useNoop =
  process.env.ANALYTICS_BACKEND === 'noop' ||
  process.env.NODE_ENV === 'test' ||
  process.env.VITEST === 'true'

let backend: AnalyticsBackend = useNoop ? new NoopBackend() : new PrismaBackend()

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
/**
 * Ingest client-originated events (see POST /api/analytics/events).
 * Fire-and-forget like `track()`.
 */
export function trackClientEvents(events: ClientEvent[]): void {
  try {
    void backend.trackClient?.(events).catch((err) => {
      console.error('[analytics] client batch failed:', err)
    })
  } catch (err) {
    console.error('[analytics] client batch synchronous error:', err)
  }
}

export function track(event: AnalyticsEvent): void {
  try {
    void backend.track(event).catch((err) => {
      console.error(`[analytics] ${event.name} track failed:`, err)
    })
  } catch (err) {
    console.error(`[analytics] ${event.name} synchronous track error:`, err)
  }
}
