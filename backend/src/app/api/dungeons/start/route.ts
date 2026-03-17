import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { getStaminaConfig } from '@/lib/game/live-config'
import { generateDungeonFloor, getDungeonBossCount } from '@/lib/game/dungeon'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { rateLimit } from '@/lib/rate-limit'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`dungeon-start:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const STAMINA = await getStaminaConfig()
    const STAMINA_COST: Record<string, number> = {
      easy: STAMINA.DUNGEON_EASY,
      normal: STAMINA.DUNGEON_NORMAL,
      hard: STAMINA.DUNGEON_HARD,
    }

    const body = await req.json()
    const { character_id, difficulty, dungeon_id } = body

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

    const dungeonId = dungeon_id || 'training_camp'
    const cost = STAMINA_COST[difficulty]

    // Use transaction with row-level lock to prevent TOCTOU stamina exploit
    const result = await prisma.$transaction(async (tx) => {
      // Lock character row + check active run in parallel
      const [[character], activeRun, progress] = await Promise.all([
        tx.$queryRawUnsafe<Array<{
          id: string; user_id: string;
          current_stamina: number; max_stamina: number; last_stamina_update: Date | null
        }>>(
          `SELECT id, user_id, current_stamina, max_stamina, last_stamina_update FROM characters WHERE id = $1 FOR UPDATE`,
          character_id
        ),
        tx.dungeonRun.findFirst({
          where: { characterId: character_id, difficulty: { not: 'rush' } },
          select: { id: true },
        }),
        tx.dungeonProgress.findUnique({
          where: { characterId_dungeonId: { characterId: character_id, dungeonId } },
          select: { bossIndex: true },
        }),
      ])

      if (!character) throw new Error('NOT_FOUND')
      if (character.user_id !== user.id) throw new Error('FORBIDDEN')
      if (activeRun) throw new Error('ACTIVE_RUN_EXISTS')

      // Check stamina with time-based regen
      const staminaResult = await calculateCurrentStamina(
        character.current_stamina,
        character.max_stamina,
        character.last_stamina_update ?? new Date()
      )
      if (staminaResult.stamina < cost) throw new Error('NOT_ENOUGH_STAMINA')

      const startFloor = progress ? Math.min(progress.bossIndex + 1, getDungeonBossCount(dungeonId)) : 1

      // Deduct stamina
      await tx.character.update({
        where: { id: character_id },
        data: {
          currentStamina: staminaResult.stamina - cost,
          lastStaminaUpdate: new Date(),
        },
      })

      // Generate first floor
      const seed = Math.floor(Math.random() * 2147483647)
      const floor = generateDungeonFloor(startFloor, difficulty, dungeonId)

      // Create the dungeon run
      const run = await tx.dungeonRun.create({
        data: {
          characterId: character_id,
          dungeonId,
          difficulty,
          currentFloor: startFloor,
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

      return { run, startFloor, floor }
    })

    return NextResponse.json({
      run_id: result.run.id,
      dungeon_id: dungeonId,
      current_floor: result.startFloor,
      floor: {
        number: result.startFloor,
        enemies: result.floor.enemies,
        isBoss: result.floor.isBoss,
      },
    }, { status: 201 })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'ACTIVE_RUN_EXISTS') return NextResponse.json({ error: 'An active dungeon run already exists. Finish or abandon it first.' }, { status: 409 })
      if (error.message === 'NOT_ENOUGH_STAMINA') return NextResponse.json({ error: 'Not enough stamina' }, { status: 400 })
    }
    console.error('start dungeon error:', error)
    return NextResponse.json(
      { error: 'Failed to start dungeon run' },
      { status: 500 },
    )
  }
}
