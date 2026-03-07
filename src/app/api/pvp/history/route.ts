import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

const DEFAULT_LIMIT = 20
const MAX_LIMIT = 100

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    const limitParam = req.nextUrl.searchParams.get('limit')

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

    const limit = Math.min(
      Math.max(1, parseInt(limitParam ?? '', 10) || DEFAULT_LIMIT),
      MAX_LIMIT
    )

    // Note: avoid explicit select with 'class' field (reserved SQL keyword, no @map)
    const matches = await prisma.pvpMatch.findMany({
      where: {
        OR: [
          { player1Id: characterId },
          { player2Id: characterId },
        ],
      },
      orderBy: { playedAt: 'desc' },
      take: limit,
      include: {
        player1: true,
        player2: true,
      },
    })

    // Shape the response to indicate win/loss from this character's perspective
    const history = matches.map((match) => {
      const isPlayer1 = match.player1Id === characterId
      const opponent = isPlayer1 ? match.player2 : match.player1
      const won = match.winnerId === characterId
      const ratingBefore = isPlayer1
        ? match.player1RatingBefore
        : match.player2RatingBefore
      const ratingAfter = isPlayer1
        ? match.player1RatingAfter
        : match.player2RatingAfter

      return {
        matchId: match.id,
        opponent: {
          id: opponent.id,
          name: opponent.characterName,
          class: opponent.class,
          level: opponent.level,
        },
        won,
        ratingBefore,
        ratingAfter,
        ratingChange: ratingAfter - ratingBefore,
        goldReward: match.goldReward,
        xpReward: match.xpReward,
        turnsTaken: match.turnsTaken,
        matchType: match.matchType,
        isRevenge: match.isRevenge,
        playedAt: match.playedAt,
      }
    })

    return NextResponse.json({
      history,
      total: history.length,
      characterId,
    })
  } catch (error) {
    console.error('pvp history error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch PvP history' },
      { status: 500 }
    )
  }
}
