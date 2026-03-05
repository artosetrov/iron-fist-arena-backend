import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { runCombat, type CharacterStats } from '@/lib/game/combat'
import { generateDungeonFloor, type Enemy } from '@/lib/game/dungeon'

const BOSS_FLOOR_INTERVAL = 5

/** Gold reward per floor cleared, scaled by difficulty. */
function floorGoldReward(floor: number, difficulty: string): number {
  const base = 30 + floor * 10
  const mult = difficulty === 'hard' ? 1.5 : difficulty === 'easy' ? 0.7 : 1.0
  return Math.round(base * mult)
}

/** XP reward per floor cleared, scaled by difficulty. */
function floorXpReward(floor: number, difficulty: string): number {
  const base = 20 + floor * 8
  const mult = difficulty === 'hard' ? 1.5 : difficulty === 'easy' ? 0.7 : 1.0
  return Math.round(base * mult)
}

/** Convert a dungeon Enemy into CharacterStats for combat. */
function enemyToCharacterStats(enemy: Enemy): CharacterStats {
  return {
    id: enemy.id,
    name: enemy.name,
    class: 'warrior', // enemies default to warrior combat style
    level: enemy.level,
    str: enemy.str,
    agi: enemy.agi,
    vit: Math.round(enemy.maxHp / 8),
    end: Math.round(enemy.armor / 2),
    int: Math.round(enemy.magicResist),
    wis: 5,
    luk: 5,
    cha: 1,
    maxHp: enemy.maxHp,
    armor: enemy.armor,
    magicResist: enemy.magicResist,
  }
}

/** Convert a Prisma Character record into CharacterStats for combat. */
function characterToStats(c: {
  id: string
  characterName: string
  class: string
  level: number
  str: number
  agi: number
  vit: number
  end: number
  int: number
  wis: number
  luk: number
  cha: number
  maxHp: number
  armor: number
  magicResist: number
  combatStance: unknown
}): CharacterStats {
  return {
    id: c.id,
    name: c.characterName,
    class: c.class as CharacterStats['class'],
    level: c.level,
    str: c.str,
    agi: c.agi,
    vit: c.vit,
    end: c.end,
    int: c.int,
    wis: c.wis,
    luk: c.luk,
    cha: c.cha,
    maxHp: c.maxHp,
    armor: c.armor,
    magicResist: c.magicResist,
    combatStance: c.combatStance as Record<string, unknown> | null,
  }
}

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, run_id } = body

    if (!character_id || !run_id) {
      return NextResponse.json(
        { error: 'character_id and run_id are required' },
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

    // Load the active dungeon run
    const run = await prisma.dungeonRun.findFirst({
      where: {
        id: run_id,
        characterId: character_id,
        difficulty: { not: 'rush' },
      },
    })
    if (!run) {
      return NextResponse.json(
        { error: 'No active dungeon run found' },
        { status: 404 },
      )
    }

    const state = run.state as unknown as {
      enemies: Enemy[]
      isBoss: boolean
      floorsCleared: number
      totalGoldEarned: number
      totalXpEarned: number
    }

    const playerStats = characterToStats(character)
    const combatResults: Array<{
      enemyName: string
      won: boolean
      turns: number
    }> = []

    let playerWon = true

    // Fight each enemy sequentially
    for (const enemy of state.enemies) {
      const enemyStats = enemyToCharacterStats(enemy)
      const result = runCombat(playerStats, enemyStats)
      const won = result.winnerId === playerStats.id

      combatResults.push({
        enemyName: enemy.name,
        won,
        turns: result.totalTurns,
      })

      if (!won) {
        playerWon = false
        break
      }
    }

    if (!playerWon) {
      // Player lost -- dungeon run fails, delete it
      await prisma.dungeonRun.delete({ where: { id: run.id } })

      return NextResponse.json({
        victory: false,
        combatResults,
        message: 'You have been defeated. The dungeon run is over.',
        rewards: {
          gold: state.totalGoldEarned,
          xp: state.totalXpEarned,
          floorsCleared: state.floorsCleared,
        },
      })
    }

    // Player won the floor
    const currentFloor = run.currentFloor
    const goldReward = floorGoldReward(currentFloor, run.difficulty)
    const xpReward = floorXpReward(currentFloor, run.difficulty)
    const newTotalGold = state.totalGoldEarned + goldReward
    const newTotalXp = state.totalXpEarned + xpReward
    const newFloorsCleared = state.floorsCleared + 1

    // Grant gold and xp to the character
    await prisma.character.update({
      where: { id: character_id },
      data: {
        gold: character.gold + goldReward,
        currentXp: character.currentXp + xpReward,
      },
    })

    // Check if this was a boss floor
    const wasBossFloor = currentFloor % BOSS_FLOOR_INTERVAL === 0
    if (wasBossFloor) {
      const dungeonId = run.difficulty // use difficulty as dungeonId for simplicity
      const bossIndex = Math.floor(currentFloor / BOSS_FLOOR_INTERVAL)

      await prisma.dungeonProgress.upsert({
        where: {
          characterId_dungeonId: {
            characterId: character_id,
            dungeonId,
          },
        },
        create: {
          characterId: character_id,
          dungeonId,
          bossIndex,
          completed: true,
        },
        update: {
          bossIndex: Math.max(bossIndex),
          completed: true,
        },
      })
    }

    // Advance to next floor
    const nextFloor = currentFloor + 1
    const nextFloorData = generateDungeonFloor(nextFloor, run.difficulty)

    await prisma.dungeonRun.update({
      where: { id: run.id },
      data: {
        currentFloor: nextFloor,
        state: JSON.parse(JSON.stringify({
          enemies: nextFloorData.enemies,
          isBoss: nextFloorData.isBoss,
          floorsCleared: newFloorsCleared,
          totalGoldEarned: newTotalGold,
          totalXpEarned: newTotalXp,
        })),
      },
    })

    return NextResponse.json({
      victory: true,
      combatResults,
      floorCleared: currentFloor,
      wasBossFloor,
      rewards: {
        gold: goldReward,
        xp: xpReward,
        totalGold: newTotalGold,
        totalXp: newTotalXp,
        floorsCleared: newFloorsCleared,
      },
      nextFloor: {
        number: nextFloor,
        enemies: nextFloorData.enemies,
        isBoss: nextFloorData.isBoss,
      },
    })
  } catch (error) {
    console.error('dungeon fight error:', error)
    return NextResponse.json(
      { error: 'Failed to process dungeon fight' },
      { status: 500 },
    )
  }
}
