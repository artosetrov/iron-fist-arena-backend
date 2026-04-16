import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import {
  createInitialRushState,
  generateRushEnemy,
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

    const result = await prisma.$transaction(async (tx) => {
      const [character] = await tx.$queryRawUnsafe<Array<{id: string; user_id: string; current_stamina: number; max_stamina: number; last_stamina_update: Date | null}>>(
        `SELECT id, user_id, current_stamina, max_stamina, last_stamina_update FROM characters WHERE id = $1 FOR UPDATE`,
        character_id
      )
      if (!character) throw new Error('NOT_FOUND')
      if (character.user_id !== user.id) throw new Error('FORBIDDEN')

      const activeRun = await tx.dungeonRun.findFirst({
        where: {
          characterId: character_id,
          difficulty: 'rush',
        },
      })

      if (activeRun) {
        const state = activeRun.state as RushState | null
        if (!state?.rooms || !Array.isArray(state.rooms)) {
          await tx.dungeonRun.delete({ where: { id: activeRun.id } })
        } else {
          const currentRoom = state.rooms[state.currentRoomIndex]
          const enemy = currentRoom && ['combat', 'elite', 'miniboss'].includes(currentRoom.type)
            ? generateRushEnemy(currentRoom.index, currentRoom.type, currentRoom.seed)
            : undefined

          return {
            resumed: true as const,
            runId: activeRun.id,
            currentFloor: activeRun.currentFloor,
            currentEnemy: enemy
              ? { name: enemy.name, level: enemy.level }
              : undefined,
            state,
          }
        }
      }

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

      const rushState = createInitialRushState()
      const firstRoom = rushState.rooms[0]
      const firstEnemy = generateRushEnemy(firstRoom.index, firstRoom.type, firstRoom.seed)

      const run = await tx.dungeonRun.create({
        data: {
          characterId: character_id,
          difficulty: 'rush',
          currentFloor: 1,
          seed: Math.floor(Math.random() * 2147483647),
          state: JSON.parse(JSON.stringify(rushState)),
        },
      })

      return {
        resumed: false as const,
        runId: run.id,
        currentFloor: 1,
        currentEnemy: { name: firstEnemy.name, level: firstEnemy.level },
        state: rushState,
      }
    })

    if (result.resumed) {
      return NextResponse.json({
        run_id: result.runId,
        current_floor: result.currentFloor,
        current_enemy: result.currentEnemy,
        resumed: true,
        rooms: result.state.rooms,
        currentRoomIndex: result.state.currentRoomIndex,
        buffs: result.state.buffs ?? [],
        artifacts: (result.state.artifacts ?? []).map((artifact) => ({
          id: artifact.id,
          name: artifact.name,
          description: artifact.description,
          icon: artifact.icon,
        })),
        pendingArtifactChoices: result.state.pendingArtifactChoices
          ? result.state.pendingArtifactChoices.map((artifact) => ({
              id: artifact.id,
              name: artifact.name,
              description: artifact.description,
              icon: artifact.icon,
            }))
          : null,
        currentHpPercent: result.state.currentHpPercent ?? 100,
        totalRooms: TOTAL_RUSH_ROOMS,
        rewards: {
          totalGold: result.state.totalGoldEarned ?? 0,
          totalXp: result.state.totalXpEarned ?? 0,
          floorsCleared: result.state.floorsCleared ?? 0,
        },
      })
    }

    return NextResponse.json({
      run_id: result.runId,
      current_floor: 1,
      current_enemy: result.currentEnemy,
      rooms: result.state.rooms,
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
