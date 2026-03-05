import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json(
        { error: 'character_id is required' },
        { status: 400 }
      )
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Get all uncollected sessions + recently collected ones (last 24h)
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000)

    const sessions = await prisma.goldMineSession.findMany({
      where: {
        characterId,
        OR: [
          { collected: false },
          { collected: true, createdAt: { gte: oneDayAgo } },
        ],
      },
      orderBy: { startedAt: 'desc' },
    })

    return NextResponse.json({
      sessions: sessions.map((s) => ({
        id: s.id,
        slotIndex: s.slotIndex,
        startedAt: s.startedAt,
        endsAt: s.endsAt,
        collected: s.collected,
        reward: s.collected ? s.reward : undefined,
        boosted: s.boosted,
      })),
      totalSlots: character.goldMineSlots,
    })
  } catch (error) {
    console.error('gold-mine status error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch gold mine status' },
      { status: 500 }
    )
  }
}
