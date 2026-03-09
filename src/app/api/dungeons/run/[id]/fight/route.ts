import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { runCombat, type CharacterStats } from '@/lib/game/combat'
import { loadCombatCharacter, invalidateSkillCache, invalidatePassiveCache } from '@/lib/game/combat-loader'
import { generateDungeonFloor, getDungeonBossCount, type Enemy } from '@/lib/game/dungeon'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { applyLevelUp } from '@/lib/game/progression'
import { rollAndPersistLoot, type LootResponseItem } from '@/lib/game/loot'
import { awardBattlePassXp } from '@/lib/game/battle-pass'
import { BATTLE_PASS, chaGoldBonus } from '@/lib/game/balance'
import { degradeEquipment } from '@/lib/game/durability'
import { rateLimit } from '@/lib/rate-limit'

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

  if (!rateLimit(`dungeon-run-fight:${user.id}`, 20, 60_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id } = body
    const { id: run_id } = await params

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    // Parallel: verify character + load run + load combat stats
    const [character, run, playerStats] = await Promise.all([
      prisma.character.findFirst({
        where: { id: character_id, userId: user.id },
        select: {
          id: true, userId: true, characterName: true, class: true, origin: true,
          level: true, maxHp: true, cha: true, luk: true,
        },
      }),
      prisma.dungeonRun.findFirst({
        where: { id: run_id, characterId: character_id, difficulty: { not: 'rush' } },
      }),
      loadCombatCharacter(character_id),
    ])

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
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

    // Run combat
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
      // Delete run + degrade equipment in parallel
      const [, durabilityResult] = await Promise.all([
        prisma.dungeonRun.delete({ where: { id: run.id } }),
        degradeEquipment(prisma, character_id),
      ])

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
    const goldReward = chaGoldBonus(floorGoldReward(currentFloor, run.difficulty), character.cha)
    const xpReward = floorXpReward(currentFloor, run.difficulty)
    const newTotalGold = state.totalGoldEarned + goldReward
    const newTotalXp = state.totalXpEarned + xpReward
    const newFloorsCleared = state.floorsCleared + 1

    const dungeonId = run.dungeonId
    const bossIndex = currentFloor
    const totalBosses = getDungeonBossCount(dungeonId)
    const isDungeonComplete = bossIndex >= totalBosses
    const isFinalBoss = isDungeonComplete

    const nextFloorData = isDungeonComplete
      ? { enemies: [], isBoss: false }
      : generateDungeonFloor(currentFloor + 1, run.difficulty, dungeonId)

    // Core DB writes in parallel
    await Promise.all([
      prisma.character.update({
        where: { id: character_id },
        data: {
          gold: { increment: goldReward },
          currentXp: { increment: xpReward },
        },
      }),
      prisma.dungeonProgress.upsert({
        where: { characterId_dungeonId: { characterId: character_id, dungeonId } },
        create: { characterId: character_id, dungeonId, bossIndex, completed: isDungeonComplete },
        update: { bossIndex: { set: bossIndex }, completed: isDungeonComplete },
      }),
      isDungeonComplete
        ? prisma.dungeonRun.delete({ where: { id: run.id } })
        : prisma.dungeonRun.update({
            where: { id: run.id },
            data: {
              currentFloor: currentFloor + 1,
              state: JSON.parse(JSON.stringify({
                enemies: nextFloorData.enemies,
                isBoss: nextFloorData.isBoss,
                floorsCleared: newFloorsCleared,
                totalGoldEarned: newTotalGold,
                totalXpEarned: newTotalXp,
              })),
            },
          }),
    ])

    // Non-critical post-combat work in parallel
    const lootDifficulty = isFinalBoss ? 'boss' : `dungeon_${run.difficulty}`
    const [levelUpResult, , , lootItem, durabilityResult] = await Promise.all([
      applyLevelUp(prisma, character_id),
      updateDailyQuestProgress(prisma, character_id, 'dungeons_complete'),
      awardBattlePassXp(prisma, character_id, BATTLE_PASS.BP_XP_PER_DUNGEON_FLOOR),
      rollAndPersistLoot(prisma, character_id, character.level, lootDifficulty, character.luk),
      degradeEquipment(prisma, character_id),
    ])

    const loot: LootResponseItem[] = []
    if (lootItem) loot.push(lootItem)

    // Invalidate combat caches if level changed
    if (levelUpResult?.leveledUp) {
      invalidateSkillCache(character_id)
      invalidatePassiveCache(character_id)
    }

    return NextResponse.json({
      victory: true,
      combatResults,
      floorCleared: currentFloor,
      wasBossFloor: isFinalBoss,
      rewards: {
        gold: goldReward,
        xp: xpReward,
        totalGold: newTotalGold,
        totalXp: newTotalXp,
        floorsCleared: newFloorsCleared,
      },
      loot,
      nextFloor: {
        number: currentFloor + 1,
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
