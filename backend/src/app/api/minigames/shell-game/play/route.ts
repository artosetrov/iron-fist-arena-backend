import { NextResponse } from 'next/server'

/**
 * POST /api/minigames/shell-game/play
 * Deprecated one-step shell game route.
 *
 * The supported flow is:
 *   1. POST /api/minigames/shell-game/start
 *   2. POST /api/minigames/shell-game/guess
 *
 * Keeping this route as 410 prevents older clients or scripted callers from
 * bypassing the locked two-step session flow and daily-limit accounting.
 */
export async function POST() {
  return NextResponse.json(
    {
      error: 'This endpoint is deprecated. Use POST /api/minigames/shell-game/start and POST /api/minigames/shell-game/guess instead.',
      deprecated: true,
      redirect: '/api/minigames/shell-game/start',
    },
    { status: 410 }
  )
}
