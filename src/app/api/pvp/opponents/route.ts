import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

const LEVEL_RANGE = 3
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
      select: { userId: true, pvpRating: true, level: true },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const minLevel = Math.max(1, character.level - LEVEL_RANGE)
    const maxLevel = character.level + LEVEL_RANGE

    // Find opponents within level range, excluding own character
    const rawOpponents = await prisma.character.findMany({
      where: {
        id: { not: characterId },
        level: {
          gte: minLevel,
          lte: maxLevel,
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
        gender: true,
        avatar: true,
      },
      orderBy: {
        pvpRating: 'asc',
      },
      take: 50,
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

    // Sort by level closeness and take top 5
    const sorted = opponents
      .map((opp) => ({
        ...opp,
        levelDiff: Math.abs(opp.level - character.level),
      }))
      .sort((a, b) => a.levelDiff - b.levelDiff)
      .slice(0, MAX_OPPONENTS)

    return NextResponse.json({
      opponents: sorted,
      playerRating: character.pvpRating,
      playerLevel: character.level,
      searchRange: { minLevel, maxLevel },
    })
  } catch (error) {
    console.error('pvp opponents error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch opponents' },
      { status: 500 }
    )
  }
}
