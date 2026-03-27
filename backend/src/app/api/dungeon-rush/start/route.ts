import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
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

  if (!(await rateLimit(`rush-start:${user.id}`, 10, 60_000))) {
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

    // Check for active rush run BEFORE the transaction (read-only, no TOCTOU concern)
    const activeRun = await prisma.dungeonRun.findFirst({
      where: {
        characterId: character_id,
        difficulty: 'rush',
      },
    })
    if (activeRun) {
      const state = activeRun.state as unknown as RushState

      // Legacy run without new room system — delete and start fresh
      if (!state.rooms || !Array.isArray(state.rooms)) {
        await prisma.dungeonRun.delete({ where: { id: activeRun.id } })
        // Fall through to create a new rush below
      } else {
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
          buffs: state.buffs ?? [],
          artifacts: (state.artifacts ?? []).map((a: { id: string; name: string; description: string; icon: string }) => ({ id: a.id, name: a.name, description: a.description, icon: a.icon })),
          pendingArtifactChoices: state.pendingArtifactChoices
            ? state.pendingArtifactChoices.map((a: { id: string; name: string; description: string; icon: string }) => ({ id: a.id, name: a.name, description: a.description, icon: a.icon }))
            : null,
          currentHpPercent: state.currentHpPercent ?? 100,
          totalRooms: TOTAL_RUSH_ROOMS,
          rewards: {
            totalGold: state.totalGoldEarned ?? 0,
            totalXp: state.totalXpEarned ?? 0,
            floorsCleared: state.floorsCleared ?? 0,
          },
        })
      }
    }

    // TOCTOU-safe: character lookup + stamina check + deduction in a single transaction with FOR UPDATE
    const result = await prisma.$transaction(async (tx) => {
      const [character] = await tx.$queryRawUnsafe<Array<{id: string; user_id: string; current_stamina: number; max_stamina: number; last_stamina_update: Date | null}>>(
        `SELECT id, user_id, current_stamina, max_stamina, last_stamina_update FROM characters WHERE id = $1 FOR UPDATE`,
        character_id
      )
      if (!character) throw new Error('NOT_FOUND')
      if (character.user_id !== user.id) throw new Error('FORBIDDEN')

      // Check stamina (account for time-based regeneration)
      const staminaResult = await calculateCurrentStamina(
        character.current_stamina,
        character.max_stamina,
        character.last_stamina_update ?? new Date()
      )
      const currentStamina = staminaResult.stamina
      if (currentStamina < RUSH_STAMINA_COST) {
        throw new Error(`STAMINA:Not enough stamina. Need ${RUSH_STAMINA_COST}, have ${currentStamina}`)
      }

      // Deduct stamina
      await tx.character.update({
        where: { id: character_id },
        data: {
          currentStamina: currentStamina - RUSH_STAMINA_COST,
          lastStaminaUpdate: new Date(),
        },
      })

      return { currentStamina }
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
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND' || error.message === 'FORBIDDEN') {
        return NextResponse.json(
          { error: 'Character not found' },
          { status: 404 },
        )
      }
      if (error.message.startsWith('STAMINA:')) {
        return NextResponse.json(
          { error: error.message.slice(8) },
          { status: 400 },
        )
      }
    }
    console.error('start dungeon rush error:', error)
    return NextResponse.json(
      { error: 'Failed to start dungeon rush' },
      { status: 500 },
    )
  }
}
