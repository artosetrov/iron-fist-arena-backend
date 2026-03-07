import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  try {
    const limitParam = req.nextUrl.searchParams.get('limit')
    const limit = Math.min(Math.max(parseInt(limitParam || '100', 10) || 100, 1), 500)

    const baseSelect = { id: true, characterName: true, class: true, pvpRating: true, level: true }

    const [byRating, byLevel, byGold] = await Promise.all([
      prisma.character.findMany({ select: baseSelect, orderBy: { pvpRating: 'desc' }, take: limit }),
      prisma.character.findMany({ select: baseSelect, orderBy: { level: 'desc' }, take: limit }),
      prisma.character.findMany({ select: { ...baseSelect, gold: true }, orderBy: { gold: 'desc' }, take: limit }),
    ])

    return NextResponse.json({
      rating: byRating.map((c, i) => ({ characterId: c.id, characterName: c.characterName, class: c.class, value: c.pvpRating, rank: i + 1 })),
      level: byLevel.map((c, i) => ({ characterId: c.id, characterName: c.characterName, class: c.class, value: c.level, rank: i + 1 })),
      gold: byGold.map((c, i) => ({ characterId: c.id, characterName: c.characterName, class: c.class, value: c.gold, rank: i + 1 })),
    })
  } catch (error) {
    console.error('leaderboard error:', error)
    return NextResponse.json({ error: 'Failed to fetch leaderboard' }, { status: 500 })
  }
}
