import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

const LEVEL_RANGE = 10
const MAX_OPPONENTS = 5
const GEAR_SCORE_TOLERANCE = 0.8 // ±80% gear score range

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
      select: { userId: true, pvpRating: true, level: true, gearScore: true },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const minLevel = Math.max(1, character.level - LEVEL_RANGE)
    const maxLevel = character.level + LEVEL_RANGE

    // Gear score range: ±30% (minimum floor of 0)
    const playerGearScore = character.gearScore ?? 0
    const minGear = Math.max(0, Math.floor(playerGearScore * (1 - GEAR_SCORE_TOLERANCE)))
    const maxGear = Math.ceil(playerGearScore * (1 + GEAR_SCORE_TOLERANCE)) + 10

    const selectFields = {
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
      gearScore: true,
    } as const

    // Find opponents within level AND gear score range
    const rawOpponents = await prisma.character.findMany({
      where: {
        id: { not: characterId },
        level: { gte: minLevel, lte: maxLevel },
        gearScore: { gte: minGear, lte: maxGear },
      },
      select: selectFields,
      orderBy: { level: 'asc' },
      take: 15,
    })

    // If gear-filtered results are too few, widen to level-only (fallback)
    let candidates = rawOpponents
    if (candidates.length < MAX_OPPONENTS) {
      const fallback = await prisma.character.findMany({
        where: {
          id: { not: characterId },
          level: { gte: minLevel, lte: maxLevel },
        },
        select: selectFields,
        orderBy: { level: 'asc' },
        take: 15,
      })
      const seenIds = new Set(candidates.map((c) => c.id))
      for (const fb of fallback) {
        if (!seenIds.has(fb.id)) candidates.push(fb)
      }
    }

    // Final fallback: if still too few, fetch ANY characters (no level/gear filter)
    if (candidates.length < MAX_OPPONENTS) {
      const anyFallback = await prisma.character.findMany({
        where: {
          id: { not: characterId },
        },
        select: selectFields,
        orderBy: { level: 'asc' },
        take: 15,
      })
      const seenIds = new Set(candidates.map((c) => c.id))
      for (const fb of anyFallback) {
        if (!seenIds.has(fb.id)) candidates.push(fb)
      }
    }

    // Sort by combined level + gear score closeness, take top 5
    const sorted = candidates
      .map((opp) => ({
        ...opp,
        levelDiff: Math.abs(opp.level - character.level),
        gearDiff: Math.abs((opp.gearScore ?? 0) - playerGearScore),
      }))
      .sort((a, b) => a.levelDiff - b.levelDiff || a.gearDiff - b.gearDiff)
      .slice(0, MAX_OPPONENTS)

    return NextResponse.json({
      opponents: sorted,
      playerRating: character.pvpRating,
      playerLevel: character.level,
      playerGearScore,
      searchRange: { minLevel, maxLevel, minGear, maxGear },
    })
  } catch (error) {
    console.error('pvp opponents error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch opponents' },
      { status: 500 }
    )
  }
}
