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
    const progress = await prisma.dungeonProgress.findMany({
      where: { characterId },
      orderBy: { dungeonId: 'asc' },
    })

    // Fetch any active dungeon run (non-rush)
    const activeRun = await prisma.dungeonRun.findFirst({
      where: {
        characterId,
        difficulty: { not: 'rush' },
      },
      orderBy: { createdAt: 'desc' },
    })

    return NextResponse.json({ progress, activeRun })
  } catch (error) {
    console.error('list dungeon progress error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch dungeon progress' },
      { status: 500 },
    )
  }
}
