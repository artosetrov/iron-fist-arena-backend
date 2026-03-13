import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`rush-abandon:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json(
        { error: 'character_id is required' },
        { status: 400 },
      )
    }

    // Parallel: verify character (select only id) + find active rush run
    const [character, run] = await Promise.all([
      prisma.character.findFirst({
        where: { id: character_id, userId: user.id },
        select: { id: true },
      }),
      prisma.dungeonRun.findFirst({
        where: {
          characterId: character_id,
          difficulty: 'rush',
        },
      }),
    ])

    if (!character) {
      return NextResponse.json(
        { error: 'Character not found' },
        { status: 404 },
      )
    }

    if (!run) {
      return NextResponse.json(
        { error: 'No active dungeon rush to abandon' },
        { status: 404 },
      )
    }

    const state = run.state as unknown as {
      floorsCleared: number
      totalGoldEarned: number
      totalXpEarned: number
    }

    // Delete the run -- rewards already granted per-floor, so they are kept
    await prisma.dungeonRun.delete({ where: { id: run.id } })

    return NextResponse.json({
      abandoned: true,
      finalFloor: run.currentFloor,
      rewards: {
        totalGold: state.totalGoldEarned,
        totalXp: state.totalXpEarned,
        floorsCleared: state.floorsCleared,
      },
      message: 'Dungeon rush abandoned. Rewards earned so far have been kept.',
    })
  } catch (error) {
    console.error('abandon dungeon rush error:', error)
    return NextResponse.json(
      { error: 'Failed to abandon dungeon rush' },
      { status: 500 },
    )
  }
}
