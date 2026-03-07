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
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { applyLevelUp } from '@/lib/game/progression'

function isFirstWinOfDay(firstWinDate: Date | null): boolean {
  if (!firstWinDate) return true
  const today = new Date()
  today.setUTCHours(0, 0, 0, 0)
  const winDate = new Date(firstWinDate)
  winDate.setUTCHours(0, 0, 0, 0)
  return winDate.getTime() < today.getTime()
}

/**
 * POST /api/pvp/revenge/[id]
 * Conducts a revenge fight for revenge entry with the given id.
 * Body: { character_id }
 */
export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`revenge:${user.id}`, 10, 60_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id } = body
    const { id: revenge_id } = await params

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const revenge = await prisma.revengeQueue.findUnique({ where: { id: revenge_id } })

    if (!revenge) {
      return NextResponse.json({ error: 'Revenge entry not found' }, { status: 404 })
    }

    if (revenge.victimId !== character_id) {
      return NextResponse.json(
        { error: 'This revenge does not belong to your character' },
        { status: 403 }
      )
    }

    if (revenge.isUsed) {
      return NextResponse.json({ error: 'Revenge has already been used' }, { status: 400 })
    }

    if (new Date() > revenge.expiresAt) {
      return NextResponse.json({ error: 'Revenge has expired' }, { status: 400 })
    }

    const [attacker, defender] = await Promise.all([
      prisma.character.findUnique({ where: { id: revenge.victimId } }),
      prisma.character.findUnique({ where: { id: revenge.attackerId } }),
    ])

    if (!attacker || !defender) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (attacker.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

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

    const combatResult = runCombat(attackerStats, defenderStats)
    const attackerWon = combatResult.winnerId === attacker.id
    const winnerId = combatResult.winnerId
    const loserId = combatResult.loserId

    const winnerRatingBefore = attackerWon ? attacker.pvpRating : defender.pvpRating
    const loserRatingBefore = attackerWon ? defender.pvpRating : attacker.pvpRating
    const winnerCalibration = attackerWon ? attacker.pvpCalibrationGames : defender.pvpCalibrationGames
    const kFactor = getKFactor(winnerCalibration)
    const eloResult = calculateElo(winnerRatingBefore, loserRatingBefore, kFactor)

    let goldReward = attackerWon
      ? Math.floor(GOLD_REWARDS.PVP_WIN_BASE * GOLD_REWARDS.REVENGE_MULTIPLIER)
      : GOLD_REWARDS.PVP_LOSS_BASE
    let xpReward = attackerWon ? XP_REWARDS.PVP_WIN_XP : XP_REWARDS.PVP_LOSS_XP

    const firstWin = attackerWon && isFirstWinOfDay(attacker.firstWinDate)

    if (firstWin) {
      goldReward = goldReward * FIRST_WIN_BONUS.GOLD_MULT
      xpReward = xpReward * FIRST_WIN_BONUS.XP_MULT
    }

    const newStamina = currentStamina - STAMINA.PVP_COST
    const now = new Date()

    const attackerNewRating = attackerWon ? eloResult.newWinner : eloResult.newLoser
    const defenderNewRating = attackerWon ? eloResult.newLoser : eloResult.newWinner

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
          matchType: 'revenge',
          isRevenge: true,
        },
      }),
      prisma.revengeQueue.update({
        where: { id: revenge_id },
        data: { isUsed: true },
      }),
    ])

    // Check for level-up after XP award
    const levelUpResult = await applyLevelUp(prisma, attacker.id)

    // Update daily quest progress
    if (attackerWon) {
      await updateDailyQuestProgress(prisma, attacker.id, 'pvp_wins')
    }

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
        revengeMultiplier: GOLD_REWARDS.REVENGE_MULTIPLIER,
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
      isRevenge: true,
      stamina: {
        current: newStamina,
        max: updatedAttacker.maxStamina,
      },
    })
  } catch (error) {
    console.error('pvp revenge [id] error:', error)
    return NextResponse.json({ error: 'Failed to process revenge match' }, { status: 500 })
  }
}
