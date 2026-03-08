import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { runCombat, type CharacterStats } from '@/lib/game/combat'
import { applyLevelUp } from '@/lib/game/progression'
import { rollAndPersistLoot, type LootResponseItem } from '@/lib/game/loot'
import { chaGoldBonus } from '@/lib/game/balance'
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

    const state = run.state as unknown as RushState
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

    // Prepare player stats with buffs applied
    let playerStats = characterToStats(character)
    playerStats = applyRushBuffs(playerStats, state.buffs)

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

    const combatResult = runCombat(playerStatsForCombat, enemyStats)
    const playerWon = combatResult.winnerId === playerStatsForCombat.id

    // Build combat_log for iOS client animation
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
        max_hp: playerCurrentHp,
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
      // Player lost — rush ends, delete run. Rewards earned so far are kept.
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

    // Player won — grant rewards
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

    // Calculate new HP% after combat
    // Find player's remaining HP from combat turns
    let remainingHp = playerCurrentHp
    for (const turn of combatResult.turns) {
      if (turn.attackerId !== playerStatsForCombat.id) {
        // Enemy attacked player
        remainingHp = Math.max(0, remainingHp - turn.damage)
      }
    }
    // But player won, so remainingHp > 0. Convert to % of actual maxHp.
    const newHpPercent = hpPercentAfterCombat(remainingHp, playerEffectiveMaxHp)

    // Roll for loot
    const loot: LootResponseItem[] = []
    const lootItem = await rollAndPersistLoot(prisma, character_id, character.level, roomRewards.lootDifficulty, character.luk)
    if (lootItem) loot.push(lootItem)

    // Mark room as resolved and advance
    const updatedRooms = [...state.rooms]
    updatedRooms[state.currentRoomIndex] = { ...currentRoom, resolved: true }
    const nextRoomIndex = state.currentRoomIndex + 1
    const isRushComplete = nextRoomIndex >= TOTAL_RUSH_ROOMS

    if (isRushComplete) {
      // Rush complete — delete run
      await prisma.dungeonRun.delete({ where: { id: run.id } })

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
          totalGold: newTotalGold,
          totalXp: newTotalXp,
          floorsCleared: newFloorsCleared,
        },
        loot,
        leveled_up: levelUpResult?.leveledUp ?? false,
        new_level: levelUpResult?.newLevel,
        stat_points_awarded: levelUpResult?.statPointsAwarded,
      })
    }

    // Update state for next room
    const newState: RushState = {
      ...state,
      rooms: updatedRooms,
      currentRoomIndex: nextRoomIndex,
      currentHpPercent: newHpPercent,
      floorsCleared: newFloorsCleared,
      totalGoldEarned: newTotalGold,
      totalXpEarned: newTotalXp,
    }

    await prisma.dungeonRun.update({
      where: { id: run.id },
      data: {
        currentFloor: nextRoomIndex + 1,
        state: JSON.parse(JSON.stringify(newState)),
      },
    })

    // Build next room info
    const nextRoom = newState.rooms[nextRoomIndex]
    const nextEnemy = isCombatRoom(nextRoom.type)
      ? generateRushEnemy(nextRoom.index, nextRoom.type, nextRoom.seed)
      : undefined

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
        totalGold: newTotalGold,
        totalXp: newTotalXp,
        floorsCleared: newFloorsCleared,
      },
      loot,
      leveled_up: levelUpResult?.leveledUp ?? false,
      new_level: levelUpResult?.newLevel,
      stat_points_awarded: levelUpResult?.statPointsAwarded,
      nextRoom: {
        index: nextRoom.index,
        type: nextRoom.type,
        seed: nextRoom.seed,
      },
      nextEnemy: nextEnemy
        ? { name: nextEnemy.name, level: nextEnemy.level }
        : undefined,
      buffs: newState.buffs,
    })
  } catch (error) {
    console.error('dungeon rush fight error:', error)
    return NextResponse.json(
      { error: 'Failed to process dungeon rush fight' },
      { status: 500 },
    )
  }
}
