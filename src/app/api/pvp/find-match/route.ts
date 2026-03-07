import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'

const MATCHMAKING_RANGE = 200
const MAX_OPPONENTS = 3

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`find-match:${user.id}`, 20, 60_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json(
        { error: 'character_id is required' },
        { status: 400 }
      )
    }

    const character = await prisma.character.findUnique({
      where: { id: character_id },
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
    // Note: avoid explicit select with 'class' field (reserved SQL keyword, no @map)
    const rawOpponents = await prisma.character.findMany({
      where: {
        id: { not: character_id },
        pvpRating: {
          gte: minRating,
          lte: maxRating,
        },
      },
      orderBy: {
        pvpRating: 'asc',
      },
    })

    const opponents = rawOpponents.map((opp) => ({
      id: opp.id,
      characterName: opp.characterName,
      class: opp.class,
      origin: opp.origin,
      level: opp.level,
      pvpRating: opp.pvpRating,
      pvpWins: opp.pvpWins,
      pvpLosses: opp.pvpLosses,
      pvpWinStreak: opp.pvpWinStreak,
      maxHp: opp.maxHp,
      armor: opp.armor,
      magicResist: opp.magicResist,
    }))

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
    console.error('find match error:', error)
    return NextResponse.json(
      { error: 'Failed to find opponents' },
      { status: 500 }
    )
  }
}
