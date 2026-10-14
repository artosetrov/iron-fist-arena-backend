import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { runCombat, type CharacterStats } from '@/lib/game/combat'
import type { DiceState } from '@/lib/game/dice'
import { loadCombatCharacter, invalidateSkillCache, invalidatePassiveCache } from '@/lib/game/combat-loader'
import { rollAndPersistLoot, type LootResponseItem } from '@/lib/game/loot'
import { chaGoldBonus } from '@/lib/game/balance'
import { lockDungeonRunForUpdate } from '@/lib/game/dungeon-run-lock'
import {
  generateRushEnemy,
  getRoomRewards,
  applyRushBuffs,
  applyArtifactStatBoosts,
  applyArtifactGoldMult,
  applyArtifactXpMult,
  getHealOnKillPercent,
  generateArtifactChoices,
  effectiveHp,
  hpPercentAfterCombat,
  adjustHpPercent,
  isCombatRoom,
  TOTAL_RUSH_ROOMS,
  RUSH_ARTIFACTS,
  type RushState,
  type RushArtifact,
} from '@/lib/game/dungeon-rush'
import { incrementGuildChallenge } from '@/lib/game/guild-challenge'
import { goldBonusMultiplier, PREMIUM_ENTITLEMENT_USER_SELECT } from '@/lib/game/premium'
import { grantRewardEntries } from '@/lib/game/reward-grants'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`rush-fight:${user.id}`, 20, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  let activeRunId: string | null = null

  try {
    const body = await req.json()
    const { character_id, run_id, match_id } = body

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
        select: {
          id: true, characterName: true, class: true, origin: true, level: true,
          maxHp: true, avatar: true, cha: true, luk: true,
          // Premium entitlement (Forever or active subscription) for gold bonus
          user: { select: PREMIUM_ENTITLEMENT_USER_SELECT },
        },
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

    // Apply rush buffs + artifact stat boosts to combat-ready character
    let playerStats = applyRushBuffs(playerStatsRaw, state.buffs)
    const ownedArtifacts: RushArtifact[] = (state.artifacts ?? []).map(a => {
      const full = RUSH_ARTIFACTS.find(r => r.id === a.id)
      return full ?? a as RushArtifact
    })
    playerStats = applyArtifactStatBoosts(playerStats, ownedArtifacts)

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

    // Two ways to fight a rush room:
    //  • dice (current clients): the room was played on /pvp/dice/* as a
    //    `dungeon_rush` match; `match_id` settles it here with the dice result.
    //  • classic auto-combat (old clients): runCombat right here.
    let playerWon: boolean
    let winnerId: string
    let totalTurns: number
    let remainingHp: number
    let combat_log: Array<Record<string, unknown>>

    if (typeof match_id === 'string') {
      const match = await prisma.pvpMatch.findUnique({ where: { id: match_id } })
      const snap = match?.opponentSnapshot as unknown as { rush_room?: { index: number; seed: number; type: string } } | null
      const dice = (match?.interactiveActives as unknown as { dice?: DiceState } | null)?.dice
      if (
        !match || match.player1Id !== character_id || match.opponentType !== 'dungeon_rush' ||
        match.dungeonRunId !== run.id || !snap?.rush_room || !dice
      ) {
        return NextResponse.json({ error: 'Rush match not found' }, { status: 404 })
      }
      if (snap.rush_room.index !== currentRoom.index || snap.rush_room.seed !== currentRoom.seed) {
        return NextResponse.json({ error: 'This match belongs to another room' }, { status: 409 })
      }
      if (!dice.finished) {
        return NextResponse.json({ error: 'Match is still being fought' }, { status: 409 })
      }
      // Single settle: flip the match to completed before any reward moves.
      const closed = await prisma.pvpMatch.updateMany({
        where: { id: match.id, status: 'in_progress' },
        data: {
          status: 'completed',
          winnerId: dice.winner === 'p' ? character_id : null,
          loserId: dice.winner === 'p' ? null : character_id,
        },
      })
      if (closed.count !== 1) {
        return NextResponse.json({ error: 'Rush match already settled' }, { status: 409 })
      }
      playerWon = dice.winner === 'p'
      winnerId = playerWon ? playerStatsForCombat.id : enemy.id
      totalTurns = Math.min(dice.round, dice.cfg.MAX_ROUNDS)
      remainingHp = Math.max(0, dice.p.hp)
      type StoredStrike = { damage: number; isCrit: boolean; outcome?: string; targetZone?: string; defendZone?: string; healAmount?: number }
      const rounds = Array.isArray(match.interactiveChoices)
        ? (match.interactiveChoices as unknown as Array<{ player_strike: StoredStrike; opp_strike: StoredStrike | null }>)
        : []
      const row = (who: string, st: StoredStrike) => ({
        attacker_id: who,
        action: 'attack',
        damage: st.damage,
        is_crit: st.isCrit,
        is_miss: st.outcome === 'miss',
        is_dodge: false,
        is_blocked: st.outcome === 'blocked',
        target_zone: st.targetZone ?? null,
        defend_zone: st.defendZone ?? null,
        status_applied: null,
        heal: st.healAmount ?? null,
        skill_used: null,
        skill_key: null,
        damage_type: null,
      })
      combat_log = rounds.flatMap((r) => [
        row(playerStatsForCombat.id, r.player_strike),
        ...(r.opp_strike ? [row(enemy.id, r.opp_strike)] : []),
      ])
    } else {
      const combatResult = await runCombat(playerStatsForCombat, enemyStats)
      playerWon = combatResult.winnerId === playerStatsForCombat.id
      winnerId = combatResult.winnerId
      totalTurns = combatResult.totalTurns
      remainingHp = playerCurrentHp
      for (const turn of combatResult.turns) {
        if (turn.attackerId !== playerStatsForCombat.id) {
          remainingHp = Math.max(0, remainingHp - turn.damage)
        }
      }
      // Build combat_log for iOS client animation
      combat_log = combatResult.turns.map((t) => ({
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
    }

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

    // Get rewards for this room type, applying artifact multipliers
    const roomRewards = getRoomRewards(currentRoom.index, currentRoom.type)
    // W3.D5 — Premium Forever +10% gold applied LAST (after CHA + artifact mult)
    const goldReward = Math.floor(
      applyArtifactGoldMult(chaGoldBonus(roomRewards.gold, character.cha), ownedArtifacts)
        * goldBonusMultiplier(character.user),
    )
    const xpReward = applyArtifactXpMult(roomRewards.xp, ownedArtifacts)

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
          winner_id: winnerId,
          gold_reward: 0,
          xp_reward: 0,
          turns_taken: totalTurns,
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
    const playerPostCombatHp = remainingHp

    let newHpPercent = hpPercentAfterCombat(remainingHp, playerEffectiveMaxHp)

    // Apply heal-on-kill artifact
    const healOnKill = getHealOnKillPercent(ownedArtifacts)
    if (healOnKill > 0) {
      newHpPercent = adjustHpPercent(newHpPercent, healOnKill)
    }

    // Generate artifact choices after miniboss kills
    let artifactChoices: RushArtifact[] | null = null
    if (currentRoom.type === 'miniboss') {
      const ownedIds = (state.artifacts ?? []).map(a => a.id)
      const choices = generateArtifactChoices(currentRoom.seed, ownedIds)
      if (choices.length > 0) {
        artifactChoices = choices
      }
    }

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

      const rewardResult = await grantRewardEntries(tx, {
        userId: user.id,
        characterId: character_id,
        rewards: [
          ...(goldReward > 0 ? [{ type: 'gold' as const, quantity: goldReward }] : []),
          ...(xpReward > 0 ? [{ type: 'xp' as const, quantity: xpReward }] : []),
        ],
      })

      await tx.character.update({
        where: { id: character_id },
        data: {
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
          current_xp: rewardResult.xp,
          leveled_up: rewardResult.levelUpResult?.leveledUp ?? false,
          new_level: rewardResult.levelUpResult?.newLevel,
          stat_points_awarded: rewardResult.levelUpResult?.statPointsAwarded,
          passive_points_awarded: rewardResult.levelUpResult?.passivePointsAwarded,
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
        artifacts: lockedState.artifacts ?? [],
        pendingArtifactChoices: artifactChoices
          ? artifactChoices.map(a => ({ id: a.id, name: a.name, description: a.description, icon: a.icon, effect: a.effect }))
          : null,
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
        current_xp: rewardResult.xp,
        leveled_up: rewardResult.levelUpResult?.leveledUp ?? false,
        new_level: rewardResult.levelUpResult?.newLevel,
        stat_points_awarded: rewardResult.levelUpResult?.statPointsAwarded,
        passive_points_awarded: rewardResult.levelUpResult?.passivePointsAwarded,
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

    // Guild challenge increments (fire-and-forget)
    incrementGuildChallenge(prisma, 'dungeons_cleared', 1).catch(() => {})
    incrementGuildChallenge(prisma, 'gold_earned', goldReward).catch(() => {})
    if (currentRoom.type === 'miniboss') {
      incrementGuildChallenge(prisma, 'bosses_killed', 1).catch(() => {})
    }

    // W3.D5 — Weekly BP challenges: count miniboss kills as 'dungeons_complete'
    // (matches Dungeon Rush's "room cleared" cadence for the challenge UX).
    if (currentRoom.type === 'miniboss') {
      updateWeeklyChallengeProgress(prisma, character_id, 'dungeons_complete').catch(() => {})
    }

    // Invalidate caches if character leveled up
    if (updatedRushState.leveled_up) {
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
          turns_taken: totalTurns,
          leveled_up: updatedRushState.leveled_up,
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
        current_xp: updatedRushState.current_xp,
        leveled_up: updatedRushState.leveled_up,
        new_level: updatedRushState.new_level,
        stat_points_awarded: updatedRushState.stat_points_awarded,
        passive_points_awarded: updatedRushState.passive_points_awarded,
      })
    }

    return NextResponse.json({
      ...combatDataPayload,
      result: {
        is_win: true,
        winner_id: character.id,
        gold_reward: goldReward,
        xp_reward: xpReward,
        turns_taken: totalTurns,
        leveled_up: updatedRushState.leveled_up,
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
      current_xp: updatedRushState.current_xp,
      leveled_up: updatedRushState.leveled_up,
      new_level: updatedRushState.new_level,
      stat_points_awarded: updatedRushState.stat_points_awarded,
      passive_points_awarded: updatedRushState.passive_points_awarded,
      nextRoom: updatedRushState.nextRoom!,
      nextEnemy: updatedRushState.nextEnemy,
      buffs: state.buffs,
      artifacts: state.artifacts ?? [],
      artifactChoices: artifactChoices
        ? artifactChoices.map(a => ({ id: a.id, name: a.name, description: a.description, icon: a.icon }))
        : null,
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
