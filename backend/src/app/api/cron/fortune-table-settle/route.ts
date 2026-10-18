import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { settleAllDueRounds } from '@/lib/game/fortune-table-server'

/**
 * GET /api/cron/fortune-table-settle — Vercel Cron (see backend/vercel.json).
 *
 * Draws and pays Fortune's Table rounds whose lobby ended while nobody was
 * polling (the player closed the app). The draw was fixed when the round
 * opened, so settling late changes nothing but when the gold arrives.
 * Auth: `Authorization: Bearer <CRON_SECRET>`.
 */
export async function GET(req: NextRequest) {
  const secret = process.env.CRON_SECRET
  const auth = req.headers.get('authorization')
  if (!secret || auth !== `Bearer ${secret}`) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const settled = await settleAllDueRounds(prisma, Date.now())
    return NextResponse.json({ settled })
  } catch (error) {
    console.error('cron fortune-table-settle error:', error)
    return NextResponse.json({ error: 'Failed to settle rounds' }, { status: 500 })
  }
}
