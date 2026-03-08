import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { generateDungeonFloor, type Enemy } from '@/lib/game/dungeon'
import { calculateCurrentStamina } from '@/lib/game/stamina'

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
      const state = activeRun.state as unknown as {
        enemies: Enemy[]
        isBoss: boolean
        floorsCleared: number
        totalGoldEarned: number
        totalXpEarned: number
      }
      const firstEnemy = state.enemies?.[0]

      return NextResponse.json({
        run_id: activeRun.id,
        current_floor: activeRun.currentFloor,
        current_enemy: firstEnemy
          ? { name: firstEnemy.name, level: firstEnemy.level }
          : undefined,
        floor: {
          number: activeRun.currentFloor,
          enemies: state.enemies,
          isBoss: state.isBoss,
        },
        resumed: true,
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

    // Rush mode uses a scaling difficulty: floors get progressively harder
    // We pass 'normal' as the base difficulty but scale the floor number up faster
    const seed = Math.floor(Math.random() * 2147483647)
    const floor = generateDungeonFloor(1, 'normal')
    const firstEnemy = floor.enemies[0]

    const run = await prisma.dungeonRun.create({
      data: {
        characterId: character_id,
        difficulty: 'rush',
        currentFloor: 1,
        seed,
        state: JSON.parse(JSON.stringify({
          enemies: floor.enemies,
          isBoss: floor.isBoss,
          floorsCleared: 0,
          totalGoldEarned: 0,
          totalXpEarned: 0,
        })),
      },
    })

    return NextResponse.json({
      run_id: run.id,
      current_floor: 1,
      current_enemy: firstEnemy
        ? { name: firstEnemy.name, level: firstEnemy.level }
        : undefined,
      floor: {
        number: 1,
        enemies: floor.enemies,
        isBoss: floor.isBoss,
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
