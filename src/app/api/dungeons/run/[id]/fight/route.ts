import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { runCombat, type CharacterStats } from '@/lib/game/combat'
import { loadCombatCharacter } from '@/lib/game/combat-loader'
import { generateDungeonFloor, getDungeonBossCount, type Enemy } from '@/lib/game/dungeon'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { applyLevelUp } from '@/lib/game/progression'
import { rollAndPersistLoot, type LootResponseItem } from '@/lib/game/loot'
import { awardBattlePassXp } from '@/lib/game/battle-pass'
import { BATTLE_PASS, chaGoldBonus } from '@/lib/game/balance'
import { degradeEquipment } from '@/lib/game/durability'

function floorGoldReward(floor: number, difficulty: string): number {
  const base = 30 + floor * 10
  const mult = difficulty === 'hard' ? 1.5 : difficulty === 'easy' ? 0.7 : 1.0
  return Math.round(base * mult)
}

function floorXpReward(floor: number, difficulty: string): number {
  const base = 20 + floor * 8
  const mult = difficulty === 'hard' ? 1.5 : difficulty === 'easy' ? 0.7 : 1.0
  return Math.round(base * mult)
}

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

/**
 * POST /api/dungeons/run/[id]/fight
 * URL param: id = dungeon run ID
 * Body: { character_id }
 */
export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id } = body
    const { id: run_id } = await params

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findFirst({
      where: { id: character_id, userId: user.id },
    })
    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    const run = await prisma.dungeonRun.findFirst({
      where: { id: run_id, characterId: character_id, difficulty: { not: 'rush' } },
    })
    if (!run) {
      return NextResponse.json({ error: 'No active dungeon run found' }, { status: 404 })
    }

    const state = run.state as unknown as {
      enemies: Enemy[]
      isBoss: boolean
      floorsCleared: number
      totalGoldEarned: number
      totalXpEarned: number
    }

    // Load combat-ready character with skills + passives
    const playerStats = await loadCombatCharacter(character_id)
    const combatResults: Array<{ enemyName: string; won: boolean; turns: number }> = []

    let playerWon = true

    for (const enemy of state.enemies) {
      const enemyStats = enemyToCharacterStats(enemy)
      const result = runCombat(playerStats, enemyStats)
      const won = result.winnerId === playerStats.id

      combatResults.push({ enemyName: enemy.name, won, turns: result.totalTurns })

      if (!won) {
        playerWon = false
        break
      }
    }

    if (!playerWon) {
      await prisma.dungeonRun.delete({ where: { id: run.id } })

      // Degrade player's equipped items even on defeat (combat still happened)
      const durabilityResult = await degradeEquipment(prisma, character_id)

      return NextResponse.json({
        victory: false,
        combatResults,
        message: 'You have been defeated. The dungeon run is over.',
        rewards: {
          gold: state.totalGoldEarned,
          xp: state.totalXpEarned,
          floorsCleared: state.floorsCleared,
        },
        durability_changes: durabilityResult.degraded,
      })
    }

    const currentFloor = run.currentFloor
    // CHA gold bonus: +0.5% per CHA point
    const goldReward = chaGoldBonus(floorGoldReward(currentFloor, run.difficulty), character.cha)
    const xpReward = floorXpReward(currentFloor, run.difficulty)
    const newTotalGold = state.totalGoldEarned + goldReward
    const newTotalXp = state.totalXpEarned + xpReward
    const newFloorsCleared = state.floorsCleared + 1

    await prisma.character.update({
      where: { id: character_id },
      data: {
        gold: { increment: goldReward },
        currentXp: { increment: xpReward },
      },
    })

    // Check for level-up after XP award
    const levelUpResult = await applyLevelUp(prisma, character_id)

    // Update dungeon progress — each floor = one boss defeated
    const dungeonId = run.dungeonId
    const bossIndex = currentFloor
    const totalBosses = getDungeonBossCount(dungeonId)
    const isDungeonComplete = bossIndex >= totalBosses

    await prisma.dungeonProgress.upsert({
      where: {
        characterId_dungeonId: { characterId: character_id, dungeonId },
      },
      create: { characterId: character_id, dungeonId, bossIndex, completed: isDungeonComplete },
      update: { bossIndex: { set: bossIndex }, completed: isDungeonComplete },
    })

    const isFinalBoss = isDungeonComplete
    const wasBossFloor = isFinalBoss

    if (isDungeonComplete) {
      await prisma.dungeonRun.delete({ where: { id: run.id } })
    }

    const nextFloor = currentFloor + 1
    const nextFloorData = isDungeonComplete
      ? { enemies: [], isBoss: false }
      : generateDungeonFloor(nextFloor, run.difficulty, dungeonId)

    if (!isDungeonComplete) {
      await prisma.dungeonRun.update({
        where: { id: run.id },
        data: {
          currentFloor: nextFloor,
          state: JSON.parse(
            JSON.stringify({
              enemies: nextFloorData.enemies,
              isBoss: nextFloorData.isBoss,
              floorsCleared: newFloorsCleared,
              totalGoldEarned: newTotalGold,
              totalXpEarned: newTotalXp,
            })
          ),
        },
      })
    }

    // Update daily quest progress
    await updateDailyQuestProgress(prisma, character_id, 'dungeons_complete')

    // Award Battle Pass XP per dungeon floor
    await awardBattlePassXp(prisma, character_id, BATTLE_PASS.BP_XP_PER_DUNGEON_FLOOR)

    // Roll for loot drop — final boss has 75% chance, regular floors scale with difficulty
    const lootDifficulty = isFinalBoss ? 'boss' : `dungeon_${run.difficulty}`
    const loot: LootResponseItem[] = []
    const lootItem = await rollAndPersistLoot(prisma, character_id, character.level, lootDifficulty, character.luk)
    if (lootItem) loot.push(lootItem)

    // Degrade player's equipped items after combat
    const durabilityResult = await degradeEquipment(prisma, character_id)

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
      loot,
      nextFloor: {
        number: nextFloor,
        enemies: nextFloorData.enemies,
        isBoss: nextFloorData.isBoss,
      },
      leveled_up: levelUpResult?.leveledUp ?? false,
      new_level: levelUpResult?.newLevel,
      stat_points_awarded: levelUpResult?.statPointsAwarded,
      durability_changes: durabilityResult.degraded,
    })
  } catch (error) {
    console.error('dungeon run fight error:', error)
    return NextResponse.json({ error: 'Failed to process dungeon fight' }, { status: 500 })
  }
}
