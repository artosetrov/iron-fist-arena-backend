import { NextRequest, NextResponse } from 'next/server'
import { rateLimit } from '@/lib/rate-limit'
import {
  BASE_STAT_VALUE, CLASS_BONUSES, CLASS_MAIN_STAT, ORIGIN_BONUSES,
} from '@/lib/game/creation-stats'

/**
 * GET /api/characters/creation-options
 * Public, static: the stat tables character creation applies, so the client
 * renders the server's numbers instead of its own copy.
 */
export async function GET(req: NextRequest) {
  const ip = req.headers.get('x-forwarded-for')?.split(',')[0] || 'unknown'
  if (!(await rateLimit('creation-options:' + ip, 60, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }
  try {
    return NextResponse.json(
      {
        baseStat: BASE_STAT_VALUE,
        origins: ORIGIN_BONUSES,
        classes: Object.fromEntries(
          Object.entries(CLASS_BONUSES).map(([k, bonus]) => [
            k,
            { bonus, mainStat: CLASS_MAIN_STAT[k as keyof typeof CLASS_MAIN_STAT] },
          ]),
        ),
      },
      { headers: { 'Cache-Control': 'public, max-age=300' } },
    )
  } catch (error) {
    console.error('creation-options error:', error)
    return NextResponse.json({ error: 'Internal error' }, { status: 500 })
  }
}
