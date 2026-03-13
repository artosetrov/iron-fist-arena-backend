import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`dungeons-list:${user.id}`, 30, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json(
        { error: 'character_id is required' },
        { status: 400 },
      )
    }

    // Run all queries in parallel — verify ownership + fetch data simultaneously
    const [character, progressRecords, activeRun] = await Promise.all([
      prisma.character.findFirst({
        where: { id: characterId, userId: user.id },
        select: { id: true },
      }),
      prisma.dungeonProgress.findMany({
        where: { characterId },
        select: { dungeonId: true, bossIndex: true },
        orderBy: { dungeonId: 'asc' },
      }),
      prisma.dungeonRun.findFirst({
        where: {
          characterId,
          difficulty: { not: 'rush' },
        },
        select: { id: true, dungeonId: true, difficulty: true, currentFloor: true },
        orderBy: { createdAt: 'desc' },
      }),
    ])

    if (!character) {
      return NextResponse.json(
        { error: 'Character not found' },
        { status: 404 },
      )
    }

    // Convert to dictionary: { dungeonId: bossIndex }
    const progress: Record<string, number> = {}
    for (const p of progressRecords) {
      progress[p.dungeonId] = p.bossIndex
    }

    return NextResponse.json({
      progress,
      activeRun: activeRun
        ? {
            id: activeRun.id,
            dungeon_id: activeRun.dungeonId,
            difficulty: activeRun.difficulty,
            current_floor: activeRun.currentFloor,
          }
        : null,
    })
  } catch (error) {
    console.error('list dungeon progress error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch dungeon progress' },
      { status: 500 },
    )
  }
}
