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
        { status: 400 },
      )
    }

    // Verify character belongs to user
    const character = await prisma.character.findFirst({
      where: { id: characterId, userId: user.id },
    })
    if (!character) {
      return NextResponse.json(
        { error: 'Character not found' },
        { status: 404 },
      )
    }

    // Fetch all dungeon progress records for this character
    const progressRecords = await prisma.dungeonProgress.findMany({
      where: { characterId },
      orderBy: { dungeonId: 'asc' },
    })

    // Convert to dictionary: { dungeonId: bossIndex }
    // bossIndex = number of bosses defeated (e.g. 5 means bosses 1-5 are beaten)
    const progress: Record<string, number> = {}
    for (const p of progressRecords) {
      progress[p.dungeonId] = p.bossIndex
    }

    // Fetch any active dungeon run (non-rush)
    const activeRun = await prisma.dungeonRun.findFirst({
      where: {
        characterId,
        difficulty: { not: 'rush' },
      },
      orderBy: { createdAt: 'desc' },
    })

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
