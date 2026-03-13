import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import {
  generateRushEnemy,
  isCombatRoom,
  TOTAL_RUSH_ROOMS,
  type RushState,
} from '@/lib/game/dungeon-rush'

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`rush-status:${user.id}`, 30, 60_000))) {
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

    // Parallel: verify character (select only id) + find active rush run
    const [character, run] = await Promise.all([
      prisma.character.findFirst({
        where: { id: characterId, userId: user.id },
        select: { id: true },
      }),
      prisma.dungeonRun.findFirst({
        where: {
          characterId,
          difficulty: 'rush',
        },
        orderBy: { createdAt: 'desc' },
      }),
    ])

    if (!character) {
      return NextResponse.json(
        { error: 'Character not found' },
        { status: 404 },
      )
    }

    if (!run) {
      return NextResponse.json({
        active: false,
        message: 'No active dungeon rush found',
      })
    }

    const state = run.state as unknown as RushState

    // Legacy run without new room system
    if (!state.rooms || !Array.isArray(state.rooms)) {
      // Delete legacy run and report no active rush
      await prisma.dungeonRun.delete({ where: { id: run.id } })
      return NextResponse.json({
        active: false,
        message: 'Legacy rush run cleaned up. Start a new rush.',
      })
    }

    const currentRoom = state.rooms[state.currentRoomIndex]
    const currentEnemy = currentRoom && isCombatRoom(currentRoom.type)
      ? generateRushEnemy(currentRoom.index, currentRoom.type, currentRoom.seed)
      : undefined

    return NextResponse.json({
      active: true,
      run_id: run.id,
      rooms: state.rooms,
      currentRoomIndex: state.currentRoomIndex,
      buffs: state.buffs ?? [],
      currentHpPercent: state.currentHpPercent ?? 100,
      totalRooms: TOTAL_RUSH_ROOMS,
      currentEnemy: currentEnemy
        ? { name: currentEnemy.name, level: currentEnemy.level }
        : undefined,
      rewards: {
        totalGold: state.totalGoldEarned ?? 0,
        totalXp: state.totalXpEarned ?? 0,
        floorsCleared: state.floorsCleared ?? 0,
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
