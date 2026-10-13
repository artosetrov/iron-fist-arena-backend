import { NextResponse } from 'next/server'

/**
 * POST /api/combat/buy-extra — RETIRED (AUDIT-2026-10-13 H9).
 *
 * Sold stamina for gems with no daily cap, bypassing the diminishing-returns
 * cap on /api/stamina/refill. No client ever called it (iOS only carried the
 * constant). Kept as a 410 so stale builds get a clear redirect.
 */
export async function POST() {
  return NextResponse.json(
    {
      error: 'This endpoint is deprecated. Use POST /api/stamina/refill instead.',
      deprecated: true,
      redirect: '/api/stamina/refill',
    },
    { status: 410 }
  )
}
