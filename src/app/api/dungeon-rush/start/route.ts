import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import {
  createInitialRushState,
  generateRushEnemy,
  generateShopItems,
  TOTAL_RUSH_ROOMS,
  type RushState,
} from '@/lib/game/dungeon-rush'

const RUSH_STAMINA_COST = 30

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json(
        { error: 'character_id is required' },
        { status: 400 },
      )
    }

    // Verify character belongs to user
    const character = await prisma.character.findFirst({
      where: { id: character_id, userId: user.id },
    })
    if (!character) {
      return NextResponse.json(
        { error: 'Character not found' },
        { status: 404 },
      )
    }

    // Check for active rush run — resume it instead of 409
    const activeRun = await prisma.dungeonRun.findFirst({
      where: {
        characterId: character_id,
        difficulty: 'rush',
      },
    })
    if (activeRun) {
      const state = activeRun.state as unknown as RushState
      const currentRoom = state.rooms[state.currentRoomIndex]
      const enemy = (currentRoom && (currentRoom.type === 'combat' || currentRoom.type === 'elite' || currentRoom.type === 'miniboss'))
        ? generateRushEnemy(currentRoom.index, currentRoom.type, currentRoom.seed)
        : undefined

      return NextResponse.json({
        run_id: activeRun.id,
        current_floor: activeRun.currentFloor,
        current_enemy: enemy
          ? { name: enemy.name, level: enemy.level }
          : undefined,
        resumed: true,
        // New room system data
        rooms: state.rooms,
        currentRoomIndex: state.currentRoomIndex,
        buffs: state.buffs,
        currentHpPercent: state.currentHpPercent,
        totalRooms: TOTAL_RUSH_ROOMS,
        rewards: {
          totalGold: state.totalGoldEarned,
          totalXp: state.totalXpEarned,
          floorsCleared: state.floorsCleared,
        },
      })
    }

    // Check stamina (account for time-based regeneration)
    const staminaResult = calculateCurrentStamina(
      character.currentStamina,
      character.maxStamina,
      character.lastStaminaUpdate ?? new Date()
    )
    const currentStamina = staminaResult.stamina
    if (currentStamina < RUSH_STAMINA_COST) {
      return NextResponse.json(
        { error: `Not enough stamina. Need ${RUSH_STAMINA_COST}, have ${currentStamina}` },
        { status: 400 },
      )
    }

    // Deduct stamina
    await prisma.character.update({
      where: { id: character_id },
      data: {
        currentStamina: currentStamina - RUSH_STAMINA_COST,
        lastStaminaUpdate: new Date(),
      },
    })

    // Create fresh rush state with 12 rooms
    const rushState = createInitialRushState()
    const firstRoom = rushState.rooms[0]
    const firstEnemy = generateRushEnemy(firstRoom.index, firstRoom.type, firstRoom.seed)

    const run = await prisma.dungeonRun.create({
      data: {
        characterId: character_id,
        difficulty: 'rush',
        currentFloor: 1,
        seed: Math.floor(Math.random() * 2147483647),
        state: JSON.parse(JSON.stringify(rushState)),
      },
    })

    return NextResponse.json({
      run_id: run.id,
      current_floor: 1,
      current_enemy: { name: firstEnemy.name, level: firstEnemy.level },
      // New room system data
      rooms: rushState.rooms,
      currentRoomIndex: 0,
      buffs: [],
      currentHpPercent: 100,
      totalRooms: TOTAL_RUSH_ROOMS,
      rewards: {
        totalGold: 0,
        totalXp: 0,
        floorsCleared: 0,
      },
    }, { status: 201 })
  } catch (error) {
    console.error('start dungeon rush error:', error)
    return NextResponse.json(
      { error: 'Failed to start dungeon rush' },
      { status: 500 },
    )
  }
}
