import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

async function requireAdmin(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return null
  const dbUser = await prisma.user.findUnique({ where: { id: user.id } })
  if (!dbUser || dbUser.role !== 'admin') return null
  return user
}

/**
 * GET /api/admin/characters
 * Query params: ?limit=50&offset=0&search=name
 * Returns character list for admin review.
 */
export async function GET(req: NextRequest) {
  const user = await requireAdmin(req)
  if (!user) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

  try {
    const limit = Math.min(parseInt(req.nextUrl.searchParams.get('limit') ?? '50'), 200)
    const offset = parseInt(req.nextUrl.searchParams.get('offset') ?? '0')
    const search = req.nextUrl.searchParams.get('search')

    const where = search
      ? { characterName: { contains: search, mode: 'insensitive' as const } }
      : {}

    const [characters, total] = await Promise.all([
      prisma.character.findMany({
        where,
        select: {
          id: true,
          characterName: true,
          class: true,
          origin: true,
          level: true,
          prestigeLevel: true,
          pvpRating: true,
          pvpWins: true,
          pvpLosses: true,
          gold: true,
          createdAt: true,
          lastPlayed: true,
          user: { select: { email: true, username: true } },
        },
        orderBy: { pvpRating: 'desc' },
        take: limit,
        skip: offset,
      }),
      prisma.character.count({ where }),
    ])

    return NextResponse.json({ characters, total, limit, offset })
  } catch (error) {
    console.error('admin characters error:', error)
    return NextResponse.json({ error: 'Failed to fetch characters' }, { status: 500 })
  }
}
