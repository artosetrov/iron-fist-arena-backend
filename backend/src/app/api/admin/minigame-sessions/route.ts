import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/admin/minigame-sessions
 *
 * Query params: `characterId?`, `gameType?`, `limit=100`, `offset=0`.
 *
 * Returns recent MinigameSession rows with owning character + user attached.
 * Ordered by createdAt DESC. Read-only for Phase 1; reset / mass-delete
 * actions come in Phase 2 (behind AdminLog).
 */
export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const characterId = req.nextUrl.searchParams.get('characterId')
    const gameType = req.nextUrl.searchParams.get('gameType')
    const limit = Math.min(parseInt(req.nextUrl.searchParams.get('limit') ?? '100'), 500)
    const offset = parseInt(req.nextUrl.searchParams.get('offset') ?? '0')

    const where: Record<string, unknown> = {}
    if (characterId) where.characterId = characterId
    if (gameType) where.gameType = gameType

    const [sessions, total, perGameCounts] = await Promise.all([
      prisma.minigameSession.findMany({
        where,
        include: {
          character: {
            select: {
              id: true, characterName: true,
              user: { select: { email: true, username: true } },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      prisma.minigameSession.count({ where }),
      prisma.minigameSession.groupBy({
        by: ['gameType'],
        _count: true,
        orderBy: { gameType: 'asc' },
      }),
    ])

    return NextResponse.json({
      sessions: sessions.map((s) => ({
        id: s.id,
        characterId: s.characterId,
        characterName: s.character.characterName,
        userEmail: s.character.user?.email ?? null,
        userUsername: s.character.user?.username ?? null,
        gameType: s.gameType,
        status: s.status,
        betAmount: s.betAmount,
        claimedGold: s.claimedGold ?? null,
        claimedGems: s.claimedGems ?? null,
        result: s.result ?? null,
        createdAt: s.createdAt,
        claimedAt: s.claimedAt,
        expiresAt: s.expiresAt,
      })),
      total,
      limit,
      offset,
      perGameCounts: perGameCounts.map((g) => ({ gameType: g.gameType, count: g._count })),
    })
  } catch (error) {
    console.error('admin minigame-sessions list error:', error)
    return NextResponse.json({ error: 'Failed to fetch minigame sessions' }, { status: 500 })
  }
}
