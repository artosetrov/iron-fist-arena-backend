import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  try {
    const query = req.nextUrl.searchParams.get('q')?.trim()
    if (!query || query.length < 2) {
      return NextResponse.json({ results: [] })
    }

    // Limit query length to prevent abuse
    const sanitized = query.slice(0, 30)

    const characters = await prisma.character.findMany({
      where: {
        characterName: {
          contains: sanitized,
          mode: 'insensitive',
        },
      },
      select: {
        id: true,
        characterName: true,
        class: true,
        pvpRating: true,
        level: true,
      },
      orderBy: { pvpRating: 'desc' },
      take: 20,
    })

    const results = characters.map((c) => ({
      characterId: c.id,
      characterName: c.characterName,
      class: c.class,
      rating: c.pvpRating,
      level: c.level,
    }))

    return NextResponse.json({ results })
  } catch (error) {
    console.error('leaderboard search error:', error)
    return NextResponse.json({ error: 'Failed to search players' }, { status: 500 })
  }
}
