import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  try {
    const limitParam = req.nextUrl.searchParams.get('limit')
    const limit = Math.min(Math.max(parseInt(limitParam || '100', 10) || 100, 1), 500)

    const characters = await prisma.character.findMany({
      select: {
        id: true,
        characterName: true,
        level: true,
        class: true,
        origin: true,
        pvpRating: true,
        pvpWins: true,
      },
      orderBy: { pvpRating: 'desc' },
      take: limit,
    })

    return NextResponse.json({ leaderboard: characters })
  } catch (error) {
    console.error('leaderboard error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch leaderboard' },
      { status: 500 }
    )
  }
}
