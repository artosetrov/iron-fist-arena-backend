import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

const DAILY_LIMIT = 20

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    // Verify ownership
    const character = await prisma.character.findUnique({
      where: { id: characterId },
    })
    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    const today = new Date().toISOString().split('T')[0]
    const todayGames = await prisma.minigameSession.count({
      where: {
        characterId,
        gameType: 'shell_game',
        createdAt: { gte: new Date(today) },
      },
    })

    return NextResponse.json({
      plays_remaining: Math.max(0, DAILY_LIMIT - todayGames),
      plays_limit: DAILY_LIMIT,
    })
  } catch (error) {
    console.error('shell-game status error:', error)
    return NextResponse.json(
      { error: 'Failed to get shell game status' },
      { status: 500 }
    )
  }
}
