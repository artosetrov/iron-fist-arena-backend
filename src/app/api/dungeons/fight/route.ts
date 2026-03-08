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

/** Gold reward per boss defeated, scaled by difficulty. */
function bossGoldReward(floor: number, difficulty: string): number {
  const base = 30 + floor * 15
  const mult = difficulty === 'hard' ? 1.5 : difficulty === 'easy' ? 0.7 : 1.0
  return Math.round(base * mult)
}

/** XP reward per boss defeated, scaled by difficulty. */
function bossXpReward(floor: number, difficulty: string): number {
  const base = 20 + floor * 10
  const mult = difficulty === 'hard' ? 1.5 : difficulty === 'easy' ? 0.7 : 1.0
  return Math.round(base * mult)
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

    const dungeonId = run.dungeonId
    const state = run.state as unknown as {
      enemies: Enemy[]
      isBoss: boolean
      floorsCleared: number
      totalGoldEarned: number
      totalXpEarned: number
    }

    // Load combat-ready character with skills + passives
    const playerStats = await loadCombatCharacter(character_id)
    const combatResults: Array<{
      enemyName: string
      won: boolean
      turns: number
    }> = []

    let playerWon = true
    let primaryCombatResult: ReturnType<typeof runCombat> | null = null
    const primaryEnemy = state.enemies[0]

    // Fight each enemy (should be a single boss)
    for (const enemy of state.enemies) {
      const enemyStats = enemyToCharacterStats(enemy)
      const result = runCombat(playerStats, enemyStats)
      const won = result.winnerId === playerStats.id

      if (!primaryCombatResult) {
        primaryCombatResult = result
      }

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

    // Build combat_log for the iOS client animation
    const combat_log = (primaryCombatResult?.turns ?? []).map((t) => ({
      attacker_id: t.attackerId,
      action: t.isDodge ? 'dodge' : (t.skillUsed ? 'skill' : 'attack'),
      damage: t.damage,
      is_crit: t.isCrit,
      is_miss: false,
      is_dodge: t.isDodge,
      target_zone: null,
      status_applied: null,
      heal: t.healAmount ?? null,
      skill_used: t.skillUsed ?? null,
      skill_key: t.skillKey ?? null,
      damage_type: t.damageType ?? null,
    }))

    // Build CombatData for the client animation
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
        id: primaryEnemy?.id ?? 'enemy',
        character_name: primaryEnemy?.name ?? 'Enemy',
        class: 'warrior' as const,
        origin: 'demon',
        level: primaryEnemy?.level ?? 1,
        max_hp: primaryEnemy?.maxHp ?? 100,
      },
      combat_log,
      source: 'dungeon',
    }

    if (!playerWon) {
      // Player lost — dungeon run fails, delete it
      await prisma.dungeonRun.delete({ where: { id: run.id } })

      // Degrade player's equipped items even on defeat (combat still happened)
      const durabilityResult = await degradeEquipment(prisma, character_id)

      return NextResponse.json({
        ...combatDataPayload,
        result: {
          is_win: false,
          winner_id: primaryCombatResult?.winnerId ?? '',
          gold_reward: state.totalGoldEarned,
          xp_reward: state.totalXpEarned,
          turns_taken: primaryCombatResult?.totalTurns ?? 0,
        },
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

    // Player won the boss
    const currentFloor = run.currentFloor
    // CHA gold bonus: +0.5% per CHA point
    const goldReward = chaGoldBonus(bossGoldReward(currentFloor, run.difficulty), character.cha)
    const xpReward = bossXpReward(currentFloor, run.difficulty)
    const newTotalGold = state.totalGoldEarned + goldReward
    const newTotalXp = state.totalXpEarned + xpReward
    const newFloorsCleared = state.floorsCleared + 1

    // Grant gold and xp to the character
    await prisma.character.update({
      where: { id: character_id },
      data: {
        gold: { increment: goldReward },
        currentXp: { increment: xpReward },
      },
    })

    // Check for level-up
    const levelUpResult = await applyLevelUp(prisma, character_id)

    // Update dungeon progress — each floor = one boss defeated
    const bossIndex = currentFloor // floor 1 beaten = bossIndex 1
    const totalBosses = getDungeonBossCount(dungeonId)
    const isDungeonComplete = bossIndex >= totalBosses

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
        completed: isDungeonComplete,
      },
      update: {
        bossIndex: { set: bossIndex },
        completed: isDungeonComplete,
      },
    })

    // Update daily quest progress
    await updateDailyQuestProgress(prisma, character_id, 'dungeons_complete')

    // Award Battle Pass XP
    await awardBattlePassXp(prisma, character_id, BATTLE_PASS.BP_XP_PER_DUNGEON_FLOOR)

    // Roll for loot — every boss has 75% chance
    const loot: LootResponseItem[] = []
    const lootItem = await rollAndPersistLoot(prisma, character_id, character.level, 'boss', character.luk)
    if (lootItem) loot.push(lootItem)

    // Degrade player's equipped items after combat
    const winDurabilityResult = await degradeEquipment(prisma, character_id)

    if (isDungeonComplete) {
      // Dungeon complete — delete the run
      await prisma.dungeonRun.delete({ where: { id: run.id } })

      return NextResponse.json({
        ...combatDataPayload,
        result: {
          is_win: true,
          winner_id: character.id,
          gold_reward: goldReward,
          xp_reward: xpReward,
          turns_taken: primaryCombatResult?.totalTurns ?? 0,
          leveled_up: levelUpResult?.leveledUp ?? false,
          new_level: levelUpResult?.newLevel,
          stat_points_awarded: levelUpResult?.statPointsAwarded,
        },
        victory: true,
        combatResults,
        floorCleared: currentFloor,
        dungeonComplete: true,
        rewards: {
          gold: goldReward,
          xp: xpReward,
          totalGold: newTotalGold,
          totalXp: newTotalXp,
          floorsCleared: newFloorsCleared,
        },
        loot,
        durability_changes: winDurabilityResult.degraded,
      })
    }

    // Not complete — advance to next boss
    const nextFloor = currentFloor + 1
    const nextFloorData = generateDungeonFloor(nextFloor, run.difficulty, dungeonId)

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
      ...combatDataPayload,
      result: {
        is_win: true,
        winner_id: character.id,
        gold_reward: goldReward,
        xp_reward: xpReward,
        turns_taken: primaryCombatResult?.totalTurns ?? 0,
        leveled_up: levelUpResult?.leveledUp ?? false,
        new_level: levelUpResult?.newLevel,
        stat_points_awarded: levelUpResult?.statPointsAwarded,
      },
      victory: true,
      combatResults,
      floorCleared: currentFloor,
      dungeonComplete: false,
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
      durability_changes: winDurabilityResult.degraded,
    })
  } catch (error) {
    console.error('dungeon fight error:', error)
    return NextResponse.json(
      { error: 'Failed to process dungeon fight' },
      { status: 500 },
    )
  }
}
