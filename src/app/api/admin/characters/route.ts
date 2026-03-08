import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/admin/characters
 * Query params: ?limit=50&offset=0&search=name
 * Returns character list for admin review.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const limit = Math.min(parseInt(req.nextUrl.searchParams.get('limit') ?? '50'), 200)
    const offset = parseInt(req.nextUrl.searchParams.get('offset') ?? '0')
    const search = req.nextUrl.searchParams.get('search')

    const where = search
      ? { characterName: { contains: search, mode: 'insensitive' as const } }
      : {}

    const [rawCharacters, total] = await Promise.all([
      prisma.character.findMany({
        where,
        include: { user: { select: { email: true, username: true } } },
        orderBy: { pvpRating: 'desc' },
        take: limit,
        skip: offset,
      }),
      prisma.character.count({ where }),
    ])

    const characters = rawCharacters.map((c) => ({
      id: c.id,
      characterName: c.characterName,
      class: c.class,
      origin: c.origin,
      level: c.level,
      prestigeLevel: c.prestigeLevel,
      pvpRating: c.pvpRating,
      pvpWins: c.pvpWins,
      pvpLosses: c.pvpLosses,
      gold: c.gold,
      createdAt: c.createdAt,
      lastPlayed: c.lastPlayed,
      user: c.user,
    }))

    return NextResponse.json({ characters, total, limit, offset })
  } catch (error) {
    console.error('admin characters error:', error)
    return NextResponse.json({ error: 'Failed to fetch characters' }, { status: 500 })
  }
}
