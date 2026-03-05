import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { runCombat, CharacterStats } from '@/lib/game/combat'
import { calculateElo, getKFactor } from '@/lib/game/elo'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import {
  STAMINA,
  GOLD_REWARDS,
  XP_REWARDS,
  FIRST_WIN_BONUS,
} from '@/lib/game/balance'

/**
 * Determine whether this is the character's first win of the current UTC day.
 * Returns true if the character hasn't won a PvP match today yet.
 */
function isFirstWinOfDay(firstWinToday: boolean, firstWinDate: Date | null): boolean {
  if (!firstWinDate) return true
  const today = new Date()
  today.setUTCHours(0, 0, 0, 0)
  const winDate = new Date(firstWinDate)
  winDate.setUTCHours(0, 0, 0, 0)
  return winDate.getTime() < today.getTime()
}

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`combat:${user.id}`, 10, 60_000)) {
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
      return NextResponse.json({ error: 'Attacker not found' }, { status: 404 })
    }
    if (!defender) {
      return NextResponse.json({ error: 'Opponent not found' }, { status: 404 })
    }
    if (attacker.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Calculate current stamina with regen
    const staminaResult = calculateCurrentStamina(
      attacker.currentStamina,
      attacker.maxStamina,
      attacker.lastStaminaUpdate ?? new Date()
    )
    const currentStamina = staminaResult.stamina

    if (currentStamina < STAMINA.PVP_COST) {
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

    // Determine who won
    const attackerWon = combatResult.winnerId === attacker.id
    const winnerId = combatResult.winnerId
    const loserId = combatResult.loserId

    // ELO calculation
    const winnerRatingBefore = attackerWon ? attacker.pvpRating : defender.pvpRating
    const loserRatingBefore = attackerWon ? defender.pvpRating : attacker.pvpRating
    const winnerCalibration = attackerWon ? attacker.pvpCalibrationGames : defender.pvpCalibrationGames
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

    // New stamina after deduction
    const newStamina = currentStamina - STAMINA.PVP_COST
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

    // Build defender update (rating and stats only, no stamina/gold changes)
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

    // Execute all DB writes in an interactive transaction
    const { updatedAttacker, pvpMatch } = await prisma.$transaction(async (tx) => {
      const txAttacker = await tx.character.update({
        where: { id: attacker.id },
        data: attackerUpdate,
      })

      await tx.character.update({
        where: { id: defender.id },
        data: defenderUpdate,
      })

      const txMatch = await tx.pvpMatch.create({
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
      })

      // Create revenge queue entry for the loser
      await tx.revengeQueue.create({
        data: {
          victimId: loserId,
          attackerId: winnerId,
          matchId: txMatch.id,
          expiresAt: new Date(now.getTime() + 24 * 60 * 60 * 1000),
        },
      })

      return { updatedAttacker: txAttacker, pvpMatch: txMatch }
    })

    return NextResponse.json({
      combat: {
        winnerId: combatResult.winnerId,
        loserId: combatResult.loserId,
        totalTurns: combatResult.totalTurns,
        turns: combatResult.turns,
      },
      rewards: {
        gold: goldReward,
        xp: xpReward,
        firstWinBonus: firstWin,
      },
      ratings: {
        attacker: {
          before: attacker.pvpRating,
          after: attackerNewRating,
          change: attackerNewRating - attacker.pvpRating,
        },
        defender: {
          before: defender.pvpRating,
          after: defenderNewRating,
          change: defenderNewRating - defender.pvpRating,
        },
      },
      matchId: pvpMatch.id,
      attackerWon,
      stamina: {
        current: newStamina,
        max: updatedAttacker.maxStamina,
      },
    })
  } catch (error) {
    console.error('combat simulate error:', error)
    return NextResponse.json(
      { error: 'Failed to simulate combat' },
      { status: 500 }
    )
  }
}
