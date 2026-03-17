import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { runCombat, type CharacterStats } from '@/lib/game/combat'
import { loadCombatCharacter, invalidateSkillCache, invalidatePassiveCache } from '@/lib/game/combat-loader'
import { applyLevelUp } from '@/lib/game/progression'
import { rollAndPersistLoot, type LootResponseItem } from '@/lib/game/loot'
import { chaGoldBonus } from '@/lib/game/balance'
import { lockDungeonRunForUpdate } from '@/lib/game/dungeon-run-lock'
import { getBattlePassConfig } from '@/lib/game/live-config'
import {
  generateRushEnemy,
  getRoomRewards,
  applyRushBuffs,
  effectiveHp,
  hpPercentAfterCombat,
  isCombatRoom,
  TOTAL_RUSH_ROOMS,
  type RushState,
} from '@/lib/game/dungeon-rush'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`rush-fight:${user.id}`, 20, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  let activeRunId: string | null = null

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

    // Parallel: verify character (select only needed fields) + load run + load combat character
    const [character, run, playerStatsRaw] = await Promise.all([
      prisma.character.findFirst({
        where: { id: character_id, userId: user.id },
        select: { id: true, characterName: true, class: true, origin: true, level: true, maxHp: true, avatar: true, cha: true, luk: true },
      }),
      prisma.dungeonRun.findFirst({
        where: {
          id: run_id,
          characterId: character_id,
          difficulty: 'rush',
        },
      }),
      loadCombatCharacter(character_id),
    ])

    if (!character) {
      return NextResponse.json(
        { error: 'Character not found' },
        { status: 404 },
      )
    }

    if (!run) {
      return NextResponse.json(
        { error: 'No active dungeon rush found' },
        { status: 404 },
      )
    }
    activeRunId = run.id

    const state = run.state as unknown as RushState

    // Legacy run without new room system
    if (!state.rooms || !Array.isArray(state.rooms)) {
      await prisma.dungeonRun.delete({ where: { id: run.id } })
      return NextResponse.json(
        { error: 'Legacy rush run cleaned up. Please start a new rush.' },
        { status: 400 },
      )
    }

    const currentRoom = state.rooms[state.currentRoomIndex]

    if (!currentRoom) {
      return NextResponse.json(
        { error: 'No more rooms in dungeon rush' },
        { status: 400 },
      )
    }

    if (!isCombatRoom(currentRoom.type)) {
      return NextResponse.json(
        { error: `Current room is ${currentRoom.type}, not a combat room. Use /resolve endpoint.` },
        { status: 400 },
      )
    }

    if (currentRoom.resolved) {
      return NextResponse.json(
        { error: 'This room is already resolved' },
        { status: 400 },
      )
    }

    // Generate the enemy for this room
    const enemy = generateRushEnemy(currentRoom.index, currentRoom.type, currentRoom.seed)

    // Apply rush buffs to combat-ready character
    let playerStats = applyRushBuffs(playerStatsRaw, state.buffs)

    // Apply HP persistence: use current HP% instead of full HP
    const playerEffectiveMaxHp = playerStats.maxHp
    const playerCurrentHp = effectiveHp(playerEffectiveMaxHp, state.currentHpPercent)
    // We temporarily set maxHp to currentHp so combat starts with reduced HP
    // But keep actual maxHp for percentage calculation after combat
    const playerStatsForCombat = { ...playerStats, maxHp: playerCurrentHp }

    // Enemy stats for combat (same conversion as before)
    const enemyStats: CharacterStats = {
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

    const combatResult = await runCombat(playerStatsForCombat, enemyStats)
    const playerWon = combatResult.winnerId === playerStatsForCombat.id

    // Build combat_log for iOS client animation
    const combat_log = combatResult.turns.map((t) => ({
      attacker_id: t.attackerId,
      action: t.isDodge ? 'dodge' : (t.skillUsed ? 'skill' : 'attack'),
      damage: t.damage,
      is_crit: t.isCrit,
      is_miss: false,
      is_dodge: t.isDodge,
      is_blocked: false,
      target_zone: t.targetZone ?? null,
      defend_zone: t.defendZone ?? null,
      status_applied: null,
      heal: t.healAmount ?? null,
      skill_used: t.skillUsed ?? null,
      skill_key: t.skillKey ?? null,
      damage_type: t.damageType ?? null,
    }))

    // Build CombatData payload for the client animation
    const combatDataPayload = {
      player: {
        id: character.id,
        character_name: character.characterName,
        class: character.class,
        origin: character.origin,
        level: character.level,
        max_hp: playerCurrentHp,
        avatar: character.avatar,
      },
      enemy: {
        id: enemy.id,
        character_name: enemy.name,
        class: 'warrior' as const,
        origin: 'demon',
        level: enemy.level,
        max_hp: enemy.maxHp,
      },
      combat_log,
      source: 'dungeon_rush',
    }

    // Get rewards for this room type
    const roomRewards = getRoomRewards(currentRoom.index, currentRoom.type)
    const goldReward = chaGoldBonus(roomRewards.gold, character.cha)
    const xpReward = roomRewards.xp

    if (!playerWon) {
      await prisma.$transaction(async (tx) => {
        const lockedRun = await lockDungeonRunForUpdate(tx, run.id)

        if (!lockedRun) throw new Error('RUSH_RUN_NOT_ACTIVE')
        if (lockedRun.characterId !== character_id || lockedRun.difficulty !== 'rush') {
          throw new Error('RUSH_RUN_MISMATCH')
        }

        const lockedState = lockedRun.state as RushState | null
        if (!lockedState || !Array.isArray(lockedState.rooms)) {
          throw new Error('RUSH_RUN_LEGACY')
        }
        if (lockedState.currentRoomIndex !== state.currentRoomIndex) {
          throw new Error('RUSH_ROOM_STALE')
        }

        const lockedRoom = lockedState.rooms[lockedState.currentRoomIndex]
        if (
          !lockedRoom ||
          lockedRoom.index !== currentRoom.index ||
          lockedRoom.seed !== currentRoom.seed ||
          lockedRoom.type !== currentRoom.type
        ) {
          throw new Error('RUSH_ROOM_STALE')
        }
        if (lockedRoom.resolved) throw new Error('RUSH_ROOM_RESOLVED')
        if (!isCombatRoom(lockedRoom.type)) throw new Error('RUSH_ROOM_NON_COMBAT')

        await tx.dungeonRun.delete({ where: { id: run.id } })
      })

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
        roomIndex: currentRoom.index,
        roomType: currentRoom.type,
        rewards: {
          gold: 0,
          xp: 0,
          totalGold: state.totalGoldEarned,
          totalXp: state.totalXpEarned,
          floorsCleared: state.floorsCleared,
        },
      })
    }

    // Grant gold and xp, save post-combat HP to the character (atomic increment)
    const playerPostCombatHp = Math.max(combatResult.finalHp[playerStatsForCombat.id] ?? 0, 0)

    // Convert remaining combat HP back into persisted rush HP%.
    let remainingHp = playerCurrentHp
    for (const turn of combatResult.turns) {
      if (turn.attackerId !== playerStatsForCombat.id) {
        remainingHp = Math.max(0, remainingHp - turn.damage)
      }
    }
    const newHpPercent = hpPercentAfterCombat(remainingHp, playerEffectiveMaxHp)

    const updatedRushState = await prisma.$transaction(async (tx) => {
      const lockedRun = await lockDungeonRunForUpdate(tx, run.id)

      if (!lockedRun) throw new Error('RUSH_RUN_NOT_ACTIVE')
      if (lockedRun.characterId !== character_id || lockedRun.difficulty !== 'rush') {
        throw new Error('RUSH_RUN_MISMATCH')
      }

      const lockedState = lockedRun.state as RushState | null
      if (!lockedState || !Array.isArray(lockedState.rooms)) {
        throw new Error('RUSH_RUN_LEGACY')
      }
      if (lockedState.currentRoomIndex !== state.currentRoomIndex) {
        throw new Error('RUSH_ROOM_STALE')
      }

      const lockedRoom = lockedState.rooms[lockedState.currentRoomIndex]
      if (
        !lockedRoom ||
        lockedRoom.index !== currentRoom.index ||
        lockedRoom.seed !== currentRoom.seed ||
        lockedRoom.type !== currentRoom.type
      ) {
        throw new Error('RUSH_ROOM_STALE')
      }
      if (lockedRoom.resolved) throw new Error('RUSH_ROOM_RESOLVED')
      if (!isCombatRoom(lockedRoom.type)) throw new Error('RUSH_ROOM_NON_COMBAT')

      await tx.character.update({
        where: { id: character_id },
        data: {
          gold: { increment: goldReward },
          currentXp: { increment: xpReward },
          currentHp: playerPostCombatHp,
          lastHpUpdate: new Date(),
        },
      })

      const updatedRooms = [...lockedState.rooms]
      updatedRooms[lockedState.currentRoomIndex] = { ...lockedRoom, resolved: true }
      const nextRoomIndex = lockedState.currentRoomIndex + 1
      const isRushComplete = nextRoomIndex >= TOTAL_RUSH_ROOMS
      const totalGold = lockedState.totalGoldEarned + goldReward
      const totalXp = lockedState.totalXpEarned + xpReward
      const floorsCleared = lockedState.floorsCleared + 1

      if (isRushComplete) {
        await tx.dungeonRun.delete({ where: { id: run.id } })

        return {
          rushComplete: true,
          totalGold,
          totalXp,
          floorsCleared,
          nextRoom: null,
          nextEnemy: undefined,
        }
      }

      const newState: RushState = {
        ...lockedState,
        rooms: updatedRooms,
        currentRoomIndex: nextRoomIndex,
        currentHpPercent: newHpPercent,
        floorsCleared,
        totalGoldEarned: totalGold,
        totalXpEarned: totalXp,
      }

      await tx.dungeonRun.update({
        where: { id: run.id },
        data: {
          currentFloor: nextRoomIndex + 1,
          state: JSON.parse(JSON.stringify(newState)),
        },
      })

      const nextRoom = newState.rooms[nextRoomIndex]
      const nextEnemy = isCombatRoom(nextRoom.type)
        ? generateRushEnemy(nextRoom.index, nextRoom.type, nextRoom.seed)
        : undefined

      return {
        rushComplete: false,
        totalGold,
        totalXp,
        floorsCleared,
        nextRoom: {
          index: nextRoom.index,
          type: nextRoom.type,
          seed: nextRoom.seed,
        },
        nextEnemy: nextEnemy
          ? { name: nextEnemy.name, level: nextEnemy.level }
          : undefined,
      }
    })

    // Check for level-up after XP award
    const levelUpResult = await applyLevelUp(prisma, character_id)

    // Invalidate caches if character leveled up
    if (levelUpResult?.leveledUp) {
      await invalidateSkillCache(character_id)
      await invalidatePassiveCache(character_id)
    }

    // Roll for loot
    const loot: LootResponseItem[] = []
    const lootItem = await rollAndPersistLoot(prisma, character_id, character.level, roomRewards.lootDifficulty, character.luk)
    if (lootItem) loot.push(lootItem)

    if (updatedRushState.rushComplete) {
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
        rushComplete: true,
        roomIndex: currentRoom.index,
        roomType: currentRoom.type,
        currentHpPercent: newHpPercent,
        rewards: {
          gold: goldReward,
          xp: xpReward,
          totalGold: updatedRushState.totalGold,
          totalXp: updatedRushState.totalXp,
          floorsCleared: updatedRushState.floorsCleared,
        },
        loot,
        leveled_up: levelUpResult?.leveledUp ?? false,
        new_level: levelUpResult?.newLevel,
        stat_points_awarded: levelUpResult?.statPointsAwarded,
      })
    }

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
      rushComplete: false,
      roomIndex: currentRoom.index,
      roomType: currentRoom.type,
      currentHpPercent: newHpPercent,
      rewards: {
        gold: goldReward,
        xp: xpReward,
        totalGold: updatedRushState.totalGold,
        totalXp: updatedRushState.totalXp,
        floorsCleared: updatedRushState.floorsCleared,
      },
      loot,
      leveled_up: levelUpResult?.leveledUp ?? false,
      new_level: levelUpResult?.newLevel,
      stat_points_awarded: levelUpResult?.statPointsAwarded,
      nextRoom: updatedRushState.nextRoom!,
      nextEnemy: updatedRushState.nextEnemy,
      buffs: state.buffs,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'RUSH_RUN_NOT_ACTIVE') {
        return NextResponse.json(
          { error: 'Dungeon rush is no longer active. Refresh and try again.' },
          { status: 409 },
        )
      }
      if (error.message === 'RUSH_ROOM_STALE' || error.message === 'RUSH_ROOM_RESOLVED') {
        return NextResponse.json(
          { error: 'This dungeon rush room was already resolved. Refresh and continue.' },
          { status: 409 },
        )
      }
      if (error.message === 'RUSH_RUN_MISMATCH') {
        return NextResponse.json(
          { error: 'Dungeon rush does not match this request.' },
          { status: 400 },
        )
      }
      if (error.message === 'RUSH_ROOM_NON_COMBAT') {
        return NextResponse.json(
          { error: 'Current room is not a combat room. Use /resolve endpoint.' },
          { status: 400 },
        )
      }
      if (error.message === 'RUSH_RUN_LEGACY') {
        if (activeRunId) {
          await prisma.dungeonRun.delete({ where: { id: activeRunId } }).catch(() => null)
        }
        return NextResponse.json(
          { error: 'Legacy rush run cleaned up. Please start a new rush.' },
          { status: 400 },
        )
      }
    }
    console.error('dungeon rush fight error:', error)
    return NextResponse.json(
      { error: 'Failed to process dungeon rush fight' },
      { status: 500 },
    )
  }
}
