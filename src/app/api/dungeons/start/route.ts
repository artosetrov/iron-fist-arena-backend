import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { STAMINA } from '@/lib/game/balance'
import { generateDungeonFloor } from '@/lib/game/dungeon'

const STAMINA_COST: Record<string, number> = {
  easy: STAMINA.DUNGEON_EASY,
  normal: STAMINA.DUNGEON_NORMAL,
  hard: STAMINA.DUNGEON_HARD,
}

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, difficulty } = body

    if (!character_id || !difficulty) {
      return NextResponse.json(
        { error: 'character_id and difficulty are required' },
        { status: 400 },
      )
    }

    if (!['easy', 'normal', 'hard'].includes(difficulty)) {
      return NextResponse.json(
        { error: 'difficulty must be easy, normal, or hard' },
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

    // Check no active run exists (non-rush)
    const activeRun = await prisma.dungeonRun.findFirst({
      where: {
        characterId: character_id,
        difficulty: { not: 'rush' },
      },
    })
    if (activeRun) {
      return NextResponse.json(
        { error: 'An active dungeon run already exists. Finish or abandon it first.' },
        { status: 409 },
      )
    }

    // Check stamina
    const cost = STAMINA_COST[difficulty]
    if (character.currentStamina < cost) {
      return NextResponse.json(
        { error: `Not enough stamina. Need ${cost}, have ${character.currentStamina}` },
        { status: 400 },
      )
    }

    // Deduct stamina
    await prisma.character.update({
      where: { id: character_id },
      data: {
        currentStamina: character.currentStamina - cost,
        lastStaminaUpdate: new Date(),
      },
    })

    // Generate first floor
    const seed = Math.floor(Math.random() * 2147483647)
    const floor = generateDungeonFloor(1, difficulty)

    // Create the dungeon run
    const run = await prisma.dungeonRun.create({
      data: {
        characterId: character_id,
        difficulty,
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
      run,
      floor: {
        number: 1,
        enemies: floor.enemies,
        isBoss: floor.isBoss,
      },
    }, { status: 201 })
  } catch (error) {
    console.error('start dungeon error:', error)
    return NextResponse.json(
      { error: 'Failed to start dungeon run' },
      { status: 500 },
    )
  }
}
