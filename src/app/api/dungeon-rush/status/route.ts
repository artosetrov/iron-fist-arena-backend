import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { type Enemy } from '@/lib/game/dungeon'

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

    // Find active rush run
    const run = await prisma.dungeonRun.findFirst({
      where: {
        characterId,
        difficulty: 'rush',
      },
      orderBy: { createdAt: 'desc' },
    })

    if (!run) {
      return NextResponse.json({
        active: false,
        message: 'No active dungeon rush found',
      })
    }

    const state = run.state as unknown as {
      enemies: Enemy[]
      isBoss: boolean
      floorsCleared: number
      totalGoldEarned: number
      totalXpEarned: number
    }

    return NextResponse.json({
      active: true,
      run: {
        id: run.id,
        currentFloor: run.currentFloor,
        createdAt: run.createdAt,
      },
      floor: {
        number: run.currentFloor,
        enemyCount: state.enemies.length,
        enemies: state.enemies,
        isBoss: state.isBoss,
      },
      progress: {
        floorsCleared: state.floorsCleared,
        totalGoldEarned: state.totalGoldEarned,
        totalXpEarned: state.totalXpEarned,
      },
    })
  } catch (error) {
    console.error('dungeon rush status error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch dungeon rush status' },
      { status: 500 },
    )
  }
}
