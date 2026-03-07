import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { runCombat, CharacterStats } from '@/lib/game/combat'
import { calculateElo, getKFactor } from '@/lib/game/elo'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { rollDropChance } from '@/lib/game/loot'
import {
  STAMINA,
  GOLD_REWARDS,
  XP_REWARDS,
  FIRST_WIN_BONUS,
} from '@/lib/game/balance'
import { applyLevelUp } from '@/lib/game/progression'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'

function isFirstWinOfDay(firstWinToday: boolean, firstWinDate: Date | null): boolean {
  if (!firstWinDate) return true
  const today = new Date()
  today.setUTCHours(0, 0, 0, 0)
  const winDate = new Date(firstWinDate)
  winDate.setUTCHours(0, 0, 0, 0)
  return winDate.getTime() < today.getTime()
}

/**
 * POST /api/pvp/fight
 * Body: { character_id, opponent_id }
 * Runs a PvP fight, updates ELO/stats/rewards, returns CombatData for client.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`pvp-fight:${user.id}`, 10, 60_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, opponent_id } = body

    if (!character_id || !opponent_id) {
      return NextResponse.json(
        { error: 'character_id and opponent_id are required' },
        { status: 400 }
      )
    }

    if (character_id === opponent_id) {
      return NextResponse.json(
        { error: 'Cannot fight yourself' },
        { status: 400 }
      )
    }

    // Load both characters
    const [attacker, defender] = await Promise.all([
      prisma.character.findUnique({ where: { id: character_id } }),
      prisma.character.findUnique({ where: { id: opponent_id } }),
    ])

    if (!attacker) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
    if (attacker.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }
    if (!defender) {
      return NextResponse.json({ error: 'Opponent not found' }, { status: 404 })
    }

    // Calculate current stamina with regen
    const staminaResult = calculateCurrentStamina(
      attacker.currentStamina,
      attacker.maxStamina,
      attacker.lastStaminaUpdate ?? new Date()
    )
    const currentStamina = staminaResult.stamina

    // Check free PvP or stamina
    const hasFreePvp = attacker.freePvpToday < STAMINA.FREE_PVP_PER_DAY
    const staminaCost = hasFreePvp ? 0 : STAMINA.PVP_COST

    if (!hasFreePvp && currentStamina < STAMINA.PVP_COST) {
      return NextResponse.json(
        { error: 'Not enough stamina', currentStamina, required: STAMINA.PVP_COST },
        { status: 400 }
      )
    }

    // Build character stats for combat engine
    const attackerStats: CharacterStats = {
      id: attacker.id,
      name: attacker.characterName,
      class: attacker.class,
      level: attacker.level,
      str: attacker.str,
      agi: attacker.agi,
      vit: attacker.vit,
      end: attacker.end,
      int: attacker.int,
      wis: attacker.wis,
      luk: attacker.luk,
      cha: attacker.cha,
      maxHp: attacker.maxHp,
      armor: attacker.armor,
      magicResist: attacker.magicResist,
      combatStance: attacker.combatStance as Record<string, unknown> | null,
    }

    const defenderStats: CharacterStats = {
      id: defender.id,
      name: defender.characterName,
      class: defender.class,
      level: defender.level,
      str: defender.str,
      agi: defender.agi,
      vit: defender.vit,
      end: defender.end,
      int: defender.int,
      wis: defender.wis,
      luk: defender.luk,
      cha: defender.cha,
      maxHp: defender.maxHp,
      armor: defender.armor,
      magicResist: defender.magicResist,
      combatStance: defender.combatStance as Record<string, unknown> | null,
    }

    // Run combat
    const combatResult = runCombat(attackerStats, defenderStats)
    const attackerWon = combatResult.winnerId === attacker.id
    const winnerId = combatResult.winnerId
    const loserId = combatResult.loserId

    // ELO calculation
    const winnerRatingBefore = attackerWon ? attacker.pvpRating : defender.pvpRating
    const loserRatingBefore = attackerWon ? defender.pvpRating : attacker.pvpRating
    const winnerCalibration = attackerWon
      ? attacker.pvpCalibrationGames
      : defender.pvpCalibrationGames
    const kFactor = getKFactor(winnerCalibration)
    const eloResult = calculateElo(winnerRatingBefore, loserRatingBefore, kFactor)

    // Calculate rewards
    let goldReward = attackerWon ? GOLD_REWARDS.PVP_WIN_BASE : GOLD_REWARDS.PVP_LOSS_BASE
    let xpReward = attackerWon ? XP_REWARDS.PVP_WIN_XP : XP_REWARDS.PVP_LOSS_XP

    // First win of the day bonus
    const firstWin =
      attackerWon && isFirstWinOfDay(attacker.firstWinToday, attacker.firstWinDate)

    if (firstWin) {
      goldReward = goldReward * FIRST_WIN_BONUS.GOLD_MULT
      xpReward = xpReward * FIRST_WIN_BONUS.XP_MULT
    }

    const newStamina = currentStamina - staminaCost
    const now = new Date()

    // Build attacker update
    const attackerNewRating = attackerWon ? eloResult.newWinner : eloResult.newLoser
    const attackerUpdate: Record<string, unknown> = {
      currentStamina: newStamina,
      lastStaminaUpdate: now,
      pvpRating: attackerNewRating,
      pvpCalibrationGames: { increment: 1 },
      gold: { increment: goldReward },
      currentXp: { increment: xpReward },
      lastPlayed: now,
    }

    if (hasFreePvp) {
      attackerUpdate.freePvpToday = { increment: 1 }
    }

    if (attackerWon) {
      attackerUpdate.pvpWins = { increment: 1 }
      attackerUpdate.pvpWinStreak = { increment: 1 }
      attackerUpdate.pvpLossStreak = 0
      if (attackerNewRating > attacker.highestPvpRank) {
        attackerUpdate.highestPvpRank = attackerNewRating
      }
      if (firstWin) {
        attackerUpdate.firstWinToday = true
        attackerUpdate.firstWinDate = now
      }
    } else {
      attackerUpdate.pvpLosses = { increment: 1 }
      attackerUpdate.pvpLossStreak = { increment: 1 }
      attackerUpdate.pvpWinStreak = 0
    }

    // Build defender update
    const defenderNewRating = attackerWon ? eloResult.newLoser : eloResult.newWinner
    const defenderUpdate: Record<string, unknown> = {
      pvpRating: defenderNewRating,
      pvpCalibrationGames: { increment: 1 },
    }

    if (!attackerWon) {
      defenderUpdate.pvpWins = { increment: 1 }
      defenderUpdate.pvpWinStreak = { increment: 1 }
      defenderUpdate.pvpLossStreak = 0
      if (defenderNewRating > defender.highestPvpRank) {
        defenderUpdate.highestPvpRank = defenderNewRating
      }
    } else {
      defenderUpdate.pvpLosses = { increment: 1 }
      defenderUpdate.pvpLossStreak = { increment: 1 }
      defenderUpdate.pvpWinStreak = 0
    }

    // Roll for loot drop
    const drop = attackerWon ? rollDropChance(attacker.level, 'pvp') : null

    // Execute all DB writes in a transaction
    const [updatedAttacker, , pvpMatch] = await prisma.$transaction([
      prisma.character.update({ where: { id: attacker.id }, data: attackerUpdate }),
      prisma.character.update({ where: { id: defender.id }, data: defenderUpdate }),
      prisma.pvpMatch.create({
        data: {
          player1Id: attacker.id,
          player2Id: defender.id,
          player1RatingBefore: attacker.pvpRating,
          player1RatingAfter: attackerNewRating,
          player2RatingBefore: defender.pvpRating,
          player2RatingAfter: defenderNewRating,
          winnerId,
          loserId,
          combatLog: JSON.parse(JSON.stringify(combatResult.turns)),
          turnsTaken: combatResult.totalTurns,
          goldReward,
          xpReward,
          matchType: 'ranked',
          isRevenge: false,
        },
      }),
    ])

    // Check for level-up after XP award
    const levelUpResult = await applyLevelUp(prisma, attacker.id)

    // Create revenge entry for the loser (so they can take revenge)
    if (attackerWon) {
      const expiresAt = new Date(now.getTime() + 24 * 60 * 60 * 1000) // 24 hours
      await prisma.revengeQueue.create({
        data: {
          victimId: defender.id,
          attackerId: attacker.id,
          matchId: pvpMatch.id,
          expiresAt,
        },
      })
    }

    // Update daily quest progress
    if (attackerWon) {
      await updateDailyQuestProgress(prisma, attacker.id, 'pvp_wins')
    }

    // Build loot response from drop roll
    const loot: Array<Record<string, unknown>> = []
    if (drop) {
      loot.push({
        item_type: drop.itemType,
        rarity: drop.rarity,
        item_level: drop.itemLevel,
        upgrade_level: 0,
      })
    }

    const ratingChange = attackerNewRating - attacker.pvpRating

    // Build combat_log in the format the iOS client expects
    const combat_log = combatResult.turns.map((t) => ({
      attacker_id: t.attackerId,
      action: 'attack',
      damage: t.damage,
      is_crit: t.isCrit,
      is_miss: false,
      is_dodge: false,
      target_zone: null,
      status_applied: null,
      heal: null,
    }))

    // Return CombatData format matching iOS CombatData.swift
    return NextResponse.json({
      player: {
        id: attacker.id,
        character_name: attacker.characterName,
        class: attacker.class,
        origin: attacker.origin,
        level: attacker.level,
        max_hp: attacker.maxHp,
      },
      enemy: {
        id: defender.id,
        character_name: defender.characterName,
        class: defender.class,
        origin: defender.origin,
        level: defender.level,
        max_hp: defender.maxHp,
      },
      combat_log,
      result: {
        is_win: attackerWon,
        winner_id: winnerId,
        gold_reward: goldReward,
        xp_reward: xpReward,
        turns_taken: combatResult.totalTurns,
        rating_change: ratingChange,
        first_win_bonus: firstWin,
        leveled_up: levelUpResult?.leveledUp ?? false,
        new_level: levelUpResult?.newLevel,
        stat_points_awarded: levelUpResult?.statPointsAwarded,
      },
      rewards: { gold: goldReward, xp: xpReward },
      loot,
      source: 'pvp',
      matchId: pvpMatch.id,
      stamina: {
        current: newStamina,
        max: updatedAttacker.maxStamina,
      },
    })
  } catch (error) {
    console.error('pvp fight error:', error)
    return NextResponse.json(
      { error: 'Failed to process PvP fight' },
      { status: 500 }
    )
  }
}
