import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/admin/matches
 * Query params: ?limit=50&offset=0&character_id=xxx
 * Returns PvP match history for admin review.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const limit = Math.min(parseInt(req.nextUrl.searchParams.get('limit') ?? '50'), 200)
    const offset = parseInt(req.nextUrl.searchParams.get('offset') ?? '0')
    const characterId = req.nextUrl.searchParams.get('character_id')
    const matchType = req.nextUrl.searchParams.get('match_type')

    const where: Record<string, unknown> = {}
    if (characterId) {
      where.OR = [{ player1Id: characterId }, { player2Id: characterId }]
    }
    if (matchType) {
      where.matchType = matchType
    }

    const [matches, total] = await Promise.all([
      prisma.pvpMatch.findMany({
        where,
        select: {
          id: true,
          player1Id: true,
          player2Id: true,
          player1RatingBefore: true,
          player1RatingAfter: true,
          player2RatingBefore: true,
          player2RatingAfter: true,
          winnerId: true,
          loserId: true,
          matchType: true,
          isRevenge: true,
          goldReward: true,
          xpReward: true,
          turnsTaken: true,
          seasonNumber: true,
          playedAt: true,
          player1: { select: { characterName: true } },
          player2: { select: { characterName: true } },
        },
        orderBy: { playedAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      prisma.pvpMatch.count({ where }),
    ])

    return NextResponse.json({ matches, total, limit, offset })
  } catch (error) {
    console.error('admin matches error:', error)
    return NextResponse.json({ error: 'Failed to fetch matches' }, { status: 500 })
  }
}
