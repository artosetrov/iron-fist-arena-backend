import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { rateLimit } from '@/lib/rate-limit'
import { CLIENT_EVENT_NAMES, trackClientEvents, type ClientEvent, type ClientEventName } from '@/lib/analytics'

const MAX_BATCH = 50
const MAX_PROPS_BYTES = 2048
const NAME_SET = new Set<string>(CLIENT_EVENT_NAMES)

/**
 * POST /api/analytics/events
 * Body: { events: [{ name, characterId?, props?, ts? }] }
 *
 * Client-side funnel events (screen views, onboarding steps, IAP started…).
 * userId always comes from the auth token, never from the body. Names are
 * allowlisted and props are size-capped so this cannot be used as a free
 * write endpoint. Always 202 on accepted input — analytics must never
 * surface errors to the player.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`analytics:${user.id}`, 30, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = (await req.json()) as { events?: unknown }
    const raw = Array.isArray(body.events) ? body.events.slice(0, MAX_BATCH) : []

    const events: ClientEvent[] = []
    for (const item of raw) {
      if (!item || typeof item !== 'object') continue
      const e = item as Record<string, unknown>
      if (typeof e.name !== 'string' || !NAME_SET.has(e.name)) continue
      const props = e.props && typeof e.props === 'object' && !Array.isArray(e.props)
        ? (e.props as Record<string, unknown>)
        : undefined
      if (props && JSON.stringify(props).length > MAX_PROPS_BYTES) continue
      events.push({
        name: e.name as ClientEventName,
        userId: user.id,
        // iOS APIClient encodes bodies with convertToSnakeCase.
        characterId: typeof e.character_id === 'string' ? e.character_id
          : typeof e.characterId === 'string' ? e.characterId : null,
        props,
        ts: typeof e.ts === 'number' ? e.ts : undefined,
      })
    }

    trackClientEvents(events)
    return NextResponse.json({ accepted: events.length }, { status: 202 })
  } catch (error) {
    console.error('analytics ingest error:', error)
    return NextResponse.json({ accepted: 0 }, { status: 202 })
  }
}
