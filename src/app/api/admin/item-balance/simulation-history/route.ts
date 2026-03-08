import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/admin/item-balance/simulation-history
 * Returns past simulation runs.
 * Query params: ?runType=combat_sim&limit=20&offset=0
 */
export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const runType = req.nextUrl.searchParams.get('runType') ?? undefined
    const limit = Math.min(parseInt(req.nextUrl.searchParams.get('limit') ?? '20'), 100)
    const offset = parseInt(req.nextUrl.searchParams.get('offset') ?? '0')

    const where = runType ? { runType } : {}

    const [runs, total] = await Promise.all([
      prisma.balanceSimulationRun.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      prisma.balanceSimulationRun.count({ where }),
    ])

    return NextResponse.json({
      runs,
      total,
      limit,
      offset,
    })
  } catch (error) {
    console.error('get simulation history error:', error)
    return NextResponse.json({ error: 'Failed to fetch simulation history' }, { status: 500 })
  }
}
