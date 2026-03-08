import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { runCombat, type CharacterStats } from '@/lib/game/combat'
import { generateDungeonFloor, type Enemy } from '@/lib/game/dungeon'
import { applyLevelUp } from '@/lib/game/progression'
import { rollAndPersistLoot, type LootResponseItem } from '@/lib/game/loot'
import { chaGoldBonus } from '@/lib/game/balance'

/** Rush mode gold reward -- higher than normal, scales with floor. */
function rushGoldReward(floor: number): number {
  return Math.round(50 + floor * 15)
}

/** Rush mode XP reward -- higher than normal, scales with floor. */
function rushXpReward(floor: number): number {
  return Math.round(35 + floor * 12)
}

/** Convert a dungeon Enemy into CharacterStats for combat. */
function enemyToCharacterStats(enemy: Enemy): CharacterStats {
  return {
    id: enemy.id,
    name: enemy.name,
    class: 'warrior',
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

/**
 * Rush mode uses a scaled effective floor for generation.
 * The effective floor is higher than the actual floor so difficulty ramps quickly.
 */
function rushEffectiveFloor(floor: number): number {
  return Math.round(floor * 1.5)
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

    // Load the active rush run
    const run = await prisma.dungeonRun.findFirst({
      where: {
        id: run_id,
        characterId: character_id,
        difficulty: 'rush',
      },
    })
    if (!run) {
      return NextResponse.json(
        { error: 'No active dungeon rush found' },
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
    const primaryEnemy = state.enemies[0]
    const enemyStats = enemyToCharacterStats(primaryEnemy)
    const combatResult = runCombat(playerStats, enemyStats)
    const playerWon = combatResult.winnerId === playerStats.id

    // Build combat_log for the iOS client animation (same format as standard dungeon)
    const combat_log = combatResult.turns.map((t) => ({
      attacker_id: t.attackerId,
      action: 'attack',
      damage: t.damage,
      is_crit: t.isCrit,
      is_miss: false,
      is_dodge: t.isDodge,
      is_blocked: false,
      target_zone: null,
      defend_zone: null,
      status_applied: null,
      heal: null,
    }))

    // Build CombatData payload for the client animation
    const combatDataPayload = {
      player: {
        id: character.id,
        character_name: character.characterName,
        class: character.class,
        origin: character.origin,
        level: character.level,
        max_hp: character.maxHp,
      },
      enemy: {
        id: primaryEnemy.id,
        character_name: primaryEnemy.name,
        class: 'warrior' as const,
        origin: 'demon',
        level: primaryEnemy.level,
        max_hp: primaryEnemy.maxHp,
      },
      combat_log,
      source: 'dungeon_rush',
    }

    const currentFloor = run.currentFloor
    const goldReward = chaGoldBonus(rushGoldReward(currentFloor), character.cha)
    const xpReward = rushXpReward(currentFloor)

    if (!playerWon) {
      // Player lost -- rush ends. Keep rewards earned so far.
      await prisma.dungeonRun.delete({ where: { id: run.id } })

      return NextResponse.json({
        ...combatDataPayload,
        result: {
          is_win: false,
          winner_id: combatResult.winnerId,
          gold_reward: 0,
          xp_reward: 0,
          turns_taken: combatResult.totalTurns,
        },
        victory: false,
        message: 'You have been defeated. The dungeon rush is over.',
        finalFloor: currentFloor,
        rewards: {
          gold: 0,
          xp: 0,
          totalGold: state.totalGoldEarned,
          totalXp: state.totalXpEarned,
          floorsCleared: state.floorsCleared,
        },
      })
    }

    // Player won the floor
    const newTotalGold = state.totalGoldEarned + goldReward
    const newTotalXp = state.totalXpEarned + xpReward
    const newFloorsCleared = state.floorsCleared + 1

    // Grant gold and xp to the character (atomic increment)
    await prisma.character.update({
      where: { id: character_id },
      data: {
        gold: { increment: goldReward },
        currentXp: { increment: xpReward },
      },
    })

    // Check for level-up after XP award
    const levelUpResult = await applyLevelUp(prisma, character_id)

    // Generate next floor -- rush floors scale faster
    const nextFloor = currentFloor + 1
    const effectiveFloor = rushEffectiveFloor(nextFloor)
    const nextFloorData = generateDungeonFloor(effectiveFloor, 'normal')

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

    // Roll for loot drop — boss floors get 75% chance, regular get dungeon_normal rate
    const lootDifficulty = state.isBoss ? 'boss' : 'dungeon_normal'
    const loot: LootResponseItem[] = []
    const lootItem = await rollAndPersistLoot(prisma, character_id, character.level, lootDifficulty, character.luk)
    if (lootItem) loot.push(lootItem)

    return NextResponse.json({
      ...combatDataPayload,
      result: {
        is_win: true,
        winner_id: character.id,
        gold_reward: goldReward,
        xp_reward: xpReward,
        turns_taken: combatResult.totalTurns,
        leveled_up: levelUpResult?.leveledUp ?? false,
      },
      victory: true,
      floorCleared: currentFloor,
      rewards: {
        gold: goldReward,
        xp: xpReward,
        totalGold: newTotalGold,
        totalXp: newTotalXp,
        floorsCleared: newFloorsCleared,
      },
      loot,
      nextFloor: {
        number: nextFloor,
        enemies: nextFloorData.enemies,
        isBoss: nextFloorData.isBoss,
      },
      leveled_up: levelUpResult?.leveledUp ?? false,
      new_level: levelUpResult?.newLevel,
      stat_points_awarded: levelUpResult?.statPointsAwarded,
    })
  } catch (error) {
    console.error('dungeon rush fight error:', error)
    return NextResponse.json(
      { error: 'Failed to process dungeon rush fight' },
      { status: 500 },
    )
  }
}
