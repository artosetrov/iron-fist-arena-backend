import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { runCombat, type CharacterStats } from '@/lib/game/combat'
import { loadCombatCharacter, invalidateSkillCache, invalidatePassiveCache } from '@/lib/game/combat-loader'
import { generateDungeonFloor, getDungeonBossCount, generateDungeonFloorFromDB, getDungeonBossCountFromDB, type Enemy } from '@/lib/game/dungeon'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { applyLevelUp } from '@/lib/game/progression'
import { rollAndPersistLoot, type LootResponseItem } from '@/lib/game/loot'
import { awardBattlePassXp } from '@/lib/game/battle-pass'
import { chaGoldBonus } from '@/lib/game/balance'
import { getBattlePassConfig } from '@/lib/game/live-config'
import { degradeEquipment } from '@/lib/game/durability'
import { lockDungeonRunForUpdate } from '@/lib/game/dungeon-run-lock'
import { rateLimit } from '@/lib/rate-limit'

interface DungeonFightState {
  enemies: Enemy[]
  isBoss: boolean
  floorsCleared: number
  totalGoldEarned: number
  totalXpEarned: number
}

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

  if (!(await rateLimit(`dungeon-fight:${user.id}`, 20, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const BATTLE_PASS = await getBattlePassConfig()
    const body = await req.json()
    const { character_id, run_id } = body

    if (!character_id || !run_id) {
      return NextResponse.json(
        { error: 'character_id and run_id are required' },
        { status: 400 },
      )
    }

    // Parallel: verify character + load run + load combat stats
    const [character, run, playerStats] = await Promise.all([
      prisma.character.findFirst({
        where: { id: character_id, userId: user.id },
        select: {
          id: true, userId: true, characterName: true, class: true, origin: true,
          level: true, maxHp: true, cha: true, luk: true, avatar: true,
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

    const dungeonId = run.dungeonId
    const currentFloor = run.currentFloor
    const state = run.state as unknown as DungeonFightState

    // Run combat
    const combatResults: Array<{ enemyName: string; won: boolean; turns: number }> = []
    let playerWon = true
    let primaryCombatResult: Awaited<ReturnType<typeof runCombat>> | null = null
    const primaryEnemy = state.enemies[0]

    for (const enemy of state.enemies) {
      const enemyStats = enemyToCharacterStats(enemy)
      const result = await runCombat(playerStats, enemyStats)
      const won = result.winnerId === playerStats.id

      if (!primaryCombatResult) primaryCombatResult = result

      combatResults.push({ enemyName: enemy.name, won, turns: result.totalTurns })

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
      target_zone: t.targetZone ?? null,
      defend_zone: t.defendZone ?? null,
      status_applied: null,
      heal: t.healAmount ?? null,
      skill_used: t.skillUsed ?? null,
      skill_key: t.skillKey ?? null,
      damage_type: t.damageType ?? null,
    }))

    const playerStartHp = playerStats.currentHp ?? character.maxHp

    const combatDataPayload = {
      player: {
        id: character.id,
        character_name: character.characterName,
        class: character.class,
        origin: character.origin,
        level: character.level,
        max_hp: character.maxHp,
        current_hp: playerStartHp,
        avatar: character.avatar,
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
      await prisma.$transaction(async (tx) => {
        const lockedRun = await lockDungeonRunForUpdate(tx, run.id)

        if (!lockedRun) throw new Error('DUNGEON_RUN_NOT_ACTIVE')
        if (
          lockedRun.characterId !== character_id ||
          lockedRun.dungeonId !== dungeonId ||
          lockedRun.difficulty === 'rush'
        ) {
          throw new Error('DUNGEON_RUN_MISMATCH')
        }
        if (lockedRun.currentFloor !== currentFloor) throw new Error('DUNGEON_RUN_STALE')

        await tx.dungeonRun.delete({ where: { id: run.id } })
      })

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
    const goldReward = chaGoldBonus(bossGoldReward(currentFloor, run.difficulty), character.cha)
    const xpReward = bossXpReward(currentFloor, run.difficulty)
    const newTotalGold = state.totalGoldEarned + goldReward
    const newTotalXp = state.totalXpEarned + xpReward
    const newFloorsCleared = state.floorsCleared + 1

    const bossIndex = currentFloor
    // Parallelize boss count + next floor generation to avoid sequential DB round-trips
    const [totalBosses, nextFloorDataPregen] = await Promise.all([
      getDungeonBossCountFromDB(dungeonId),
      generateDungeonFloorFromDB(currentFloor + 1, run.difficulty, dungeonId),
    ])
    const isDungeonComplete = bossIndex >= totalBosses
    const nextFloorData = isDungeonComplete ? null : nextFloorDataPregen

    await prisma.$transaction(async (tx) => {
      const lockedRun = await lockDungeonRunForUpdate(tx, run.id)

      if (!lockedRun) throw new Error('DUNGEON_RUN_NOT_ACTIVE')
      if (
        lockedRun.characterId !== character_id ||
        lockedRun.dungeonId !== dungeonId ||
        lockedRun.difficulty !== run.difficulty
      ) {
        throw new Error('DUNGEON_RUN_MISMATCH')
      }
      if (lockedRun.currentFloor !== currentFloor) throw new Error('DUNGEON_RUN_STALE')

      await tx.character.update({
        where: { id: character_id },
        data: {
          gold: { increment: goldReward },
          currentXp: { increment: xpReward },
        },
      })

      await tx.dungeonProgress.upsert({
        where: { characterId_dungeonId: { characterId: character_id, dungeonId } },
        create: { characterId: character_id, dungeonId, bossIndex, completed: isDungeonComplete },
        update: { bossIndex: { set: bossIndex }, completed: isDungeonComplete },
      })

      if (isDungeonComplete) {
        await tx.dungeonRun.delete({ where: { id: run.id } })
        return
      }

      await tx.dungeonRun.update({
        where: { id: run.id },
        data: {
          currentFloor: currentFloor + 1,
          state: JSON.parse(JSON.stringify({
            enemies: nextFloorData!.enemies,
            isBoss: nextFloorData!.isBoss,
            floorsCleared: newFloorsCleared,
            totalGoldEarned: newTotalGold,
            totalXpEarned: newTotalXp,
          })),
        },
      })
    })

    // Non-critical post-combat work in parallel (level-up, quests, BP, loot, durability)
    const [levelUpResult, , , lootItem, winDurabilityResult] = await Promise.all([
      applyLevelUp(prisma, character_id),
      updateDailyQuestProgress(prisma, character_id, 'dungeons_complete'),
      awardBattlePassXp(prisma, character_id, BATTLE_PASS.BP_XP_PER_DUNGEON_FLOOR),
      rollAndPersistLoot(prisma, character_id, character.level, 'boss', character.luk),
      degradeEquipment(prisma, character_id),
    ])

    const loot: LootResponseItem[] = []
    if (lootItem) loot.push(lootItem)

    // Invalidate combat caches if level changed
    if (levelUpResult?.leveledUp) {
      await invalidateSkillCache(character_id)
      await invalidatePassiveCache(character_id)
    }

    const baseResult = {
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
      dungeonComplete: isDungeonComplete,
      rewards: {
        gold: goldReward,
        xp: xpReward,
        totalGold: newTotalGold,
        totalXp: newTotalXp,
        floorsCleared: newFloorsCleared,
      },
      loot,
      durability_changes: winDurabilityResult.degraded,
    }

    if (!isDungeonComplete && nextFloorData) {
      return NextResponse.json({
        ...baseResult,
        nextFloor: {
          number: currentFloor + 1,
          enemies: nextFloorData.enemies,
          isBoss: nextFloorData.isBoss,
        },
      })
    }

    return NextResponse.json(baseResult)
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'DUNGEON_RUN_NOT_ACTIVE') {
        return NextResponse.json(
          { error: 'Dungeon run is no longer active. Refresh and try again.' },
          { status: 409 },
        )
      }
      if (error.message === 'DUNGEON_RUN_STALE') {
        return NextResponse.json(
          { error: 'This dungeon floor was already resolved. Refresh and continue.' },
          { status: 409 },
        )
      }
      if (error.message === 'DUNGEON_RUN_MISMATCH') {
        return NextResponse.json(
          { error: 'Dungeon run does not match this request.' },
          { status: 400 },
        )
      }
    }
    console.error('dungeon fight error:', error)
    return NextResponse.json(
      { error: 'Failed to process dungeon fight' },
      { status: 500 },
    )
  }
}
