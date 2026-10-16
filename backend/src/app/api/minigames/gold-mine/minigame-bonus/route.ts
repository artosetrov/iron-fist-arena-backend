/**
 * POST /api/minigames/gold-mine/minigame-bonus — RETIRED 2026-10-16.
 *
 * This was the Phase 1 (aggregate) bonus-round finaliser. No client calls it
 * any more: the bonus run is per cart (/slot-minigame/start + /submit) and
 * optional. It also advanced the expedition without a cart being collected,
 * which let a player fill the expedition chest by replaying bonus rounds, so
 * it now refuses every request.
 */

import { NextResponse } from 'next/server'

export async function POST() {
  return NextResponse.json(
    {
      error: 'This endpoint was retired. Use /api/minigames/gold-mine/slot-minigame/submit.',
      code: 'GONE',
    },
    { status: 410 }
  )
}
