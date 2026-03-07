import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

const MATCHMAKING_RANGE = 200
const MAX_OPPONENTS = 5

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

    const minRating = character.pvpRating - MATCHMAKING_RANGE
    const maxRating = character.pvpRating + MATCHMAKING_RANGE

    // Find opponents within ELO range, excluding own character
    const opponents = await prisma.character.findMany({
      where: {
        id: { not: characterId },
        pvpRating: {
          gte: minRating,
          lte: maxRating,
        },
      },
      select: {
        id: true,
        characterName: true,
        class: true,
        origin: true,
        level: true,
        pvpRating: true,
        pvpWins: true,
        pvpLosses: true,
        pvpWinStreak: true,
        maxHp: true,
        armor: true,
        magicResist: true,
      },
      orderBy: {
        pvpRating: 'asc',
      },
    })

    // Sort by rating closeness and take top 3
    const sorted = opponents
      .map((opp) => ({
        ...opp,
        ratingDiff: Math.abs(opp.pvpRating - character.pvpRating),
      }))
      .sort((a, b) => a.ratingDiff - b.ratingDiff)
      .slice(0, MAX_OPPONENTS)

    return NextResponse.json({
      opponents: sorted,
      playerRating: character.pvpRating,
      searchRange: { min: minRating, max: maxRating },
    })
  } catch (error) {
    console.error('pvp opponents error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch opponents' },
      { status: 500 }
    )
  }
}
