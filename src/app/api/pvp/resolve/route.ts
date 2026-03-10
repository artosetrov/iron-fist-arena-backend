import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { runCombat, initCombatConfig } from '@/lib/game/combat'
import { loadCombatCharacter } from '@/lib/game/combat-loader'
import { getKFactor } from '@/lib/game/elo'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { rollAndPersistLoot, type LootResponseItem } from '@/lib/game/loot'
import {
  STAMINA,
  GOLD_REWARDS,
  XP_REWARDS,
  FIRST_WIN_BONUS,
  BATTLE_PASS,
  chaGoldBonus,
  streakGoldMultiplier,
  levelScaledReward,
} from '@/lib/game/balance'
import { applyLevelUp } from '@/lib/game/progression'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { awardBattlePassXp } from '@/lib/game/battle-pass'
import { degradeEquipment } from '@/lib/game/durability'

function isNewUtcDay(date: Date | null): boolean {
  if (!date) return true
  const today = new Date()
  today.setUTCHours(0, 0, 0, 0)
  const d = new Date(date)
  d.setUTCHours(0, 0, 0, 0)
  return d.getTime() < today.getTime()
}

function isFirstWinOfDay(firstWinToday: boolean, firstWinDate: Date | null): boolean {
  return isNewUtcDay(firstWinDate)
}

/**
 * POST /api/pvp/resolve
 * Body: { character_id, opponent_id, battle_seed, client_winner_id, revenge_id? }
 *
 * Server re-runs the combat with the same seed to verify the client's result,
 * then applies all rewards/penalties. The client has already shown the battle
 * animation and rewards optimistically — this call finalizes state.
 *
 * When revenge_id is provided, applies revenge-specific rewards (x1.5 gold)
 * and marks the revenge entry as used.
 *
 * Returns: confirmed rewards, rating changes, loot, level-up info.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`pvp-resolve:${user.id}`, 10, 60_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, opponent_id, battle_seed, client_winner_id, revenge_id } = body
    const isRevenge = !!revenge_id

    if (!character_id || !opponent_id || battle_seed == null) {
      return NextResponse.json(
        { error: 'character_id, opponent_id, and battle_seed are required' },
        { status: 400 }
      )
    }

    // Validate revenge entry if provided
    if (revenge_id) {
      const revenge = await prisma.revengeQueue.findUnique({ where: { id: revenge_id } })
      if (!revenge) return NextResponse.json({ error: 'Revenge entry not found' }, { status: 404 })
      if (revenge.victimId !== character_id) return NextResponse.json({ error: 'This revenge does not belong to your character' }, { status: 403 })
      if (revenge.isUsed) return NextResponse.json({ error: 'Revenge has already been used' }, { status: 400 })
      if (new Date() > revenge.expiresAt) return NextResponse.json({ error: 'Revenge has expired' }, { status: 400 })
    }

    // Load characters
    const pvpCharacterSelect = {
      id: true,
      userId: true,
      currentStamina: true,
      maxStamina: true,
      lastStaminaUpdate: true,
      pvpRating: true,
      pvpCalibrationGames: true,
      freePvpToday: true,
      freePvpDate: true,
      firstWinToday: true,
      firstWinDate: true,
      highestPvpRank: true,
      cha: true,
      level: true,
      luk: true,
      characterName: true,
      class: true,
      origin: true,
      gold: true,
      maxHp: true,
      pvpWins: true,
      pvpLosses: true,
      pvpWinStreak: true,
      pvpLossStreak: true,
    } as const

    const [attacker, defender] = await Promise.all([
      prisma.character.findUnique({ where: { id: character_id }, select: pvpCharacterSelect }),
      prisma.character.findUnique({ where: { id: opponent_id }, select: pvpCharacterSelect }),
    ])

    if (!attacker) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (attacker.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    if (!defender) return NextResponse.json({ error: 'Opponent not found' }, { status: 404 })

    // Stamina check — revenge fights are FREE (no stamina cost)
    const staminaResult = calculateCurrentStamina(
      attacker.currentStamina,
      attacker.maxStamina,
      attacker.lastStaminaUpdate ?? new Date()
    )
    const currentStamina = staminaResult.stamina
    const freePvpUsed = isNewUtcDay(attacker.freePvpDate) ? 0 : attacker.freePvpToday
    const hasFreePvp = isRevenge ? true : freePvpUsed < STAMINA.FREE_PVP_PER_DAY
    const staminaCost = isRevenge ? 0 : (hasFreePvp ? 0 : STAMINA.PVP_COST)

    if (!isRevenge && !hasFreePvp && currentStamina < STAMINA.PVP_COST) {
      return NextResponse.json(
        { error: 'Not enough stamina', currentStamina, required: STAMINA.PVP_COST },
        { status: 400 }
      )
    }

    // Server re-runs combat with the SAME seed for verification
    await initCombatConfig()
    const [attackerStats, defenderStats] = await Promise.all([
      loadCombatCharacter(attacker.id),
      loadCombatCharacter(defender.id),
    ])

    const combatResult = runCombat(attackerStats, defenderStats, battle_seed)
    const attackerWon = combatResult.winnerId === attacker.id
    const winnerId = combatResult.winnerId
    const loserId = combatResult.loserId

    // Verify client result matches server (anti-cheat)
    const clientMatchesServer = client_winner_id === winnerId
    if (!clientMatchesServer) {
      console.warn(`PvP resolve mismatch: client said ${client_winner_id}, server says ${winnerId}. Using server result.`)
    }

    // ELO calculation
    const winnerRatingBefore = attackerWon ? attacker.pvpRating : defender.pvpRating
    const loserRatingBefore = attackerWon ? defender.pvpRating : attacker.pvpRating
    const kWinner = getKFactor(attackerWon ? attacker.pvpCalibrationGames : defender.pvpCalibrationGames)
    const kLoser = getKFactor(attackerWon ? defender.pvpCalibrationGames : attacker.pvpCalibrationGames)
    const expectedWinner = 1 / (1 + Math.pow(10, (loserRatingBefore - winnerRatingBefore) / 400))
    const expectedLoser = 1 - expectedWinner
    const newWinnerRating = Math.max(0, Math.round(winnerRatingBefore + kWinner * (1 - expectedWinner)))
    const newLoserRating = Math.max(0, Math.round(loserRatingBefore + kLoser * (0 - expectedLoser)))

    // Calculate rewards with level scaling and revenge multiplier
    let goldReward: number = attackerWon
      ? Math.floor(levelScaledReward(GOLD_REWARDS.PVP_WIN_BASE, attacker.level) * (isRevenge ? GOLD_REWARDS.REVENGE_MULTIPLIER : 1))
      : levelScaledReward(GOLD_REWARDS.PVP_LOSS_BASE, attacker.level)
    let xpReward = attackerWon
      ? levelScaledReward(XP_REWARDS.PVP_WIN_XP, attacker.level)
      : levelScaledReward(XP_REWARDS.PVP_LOSS_XP, attacker.level)
    goldReward = chaGoldBonus(goldReward, attacker.cha)

    // Win streak gold bonus
    if (attackerWon) {
      const streakBonus = streakGoldMultiplier(attacker.pvpWinStreak)
      if (streakBonus > 0) {
        goldReward = Math.floor(goldReward * (1 + streakBonus))
      }
    }

    const firstWin = attackerWon && isFirstWinOfDay(attacker.firstWinToday, attacker.firstWinDate)
    if (firstWin) {
      goldReward = goldReward * FIRST_WIN_BONUS.GOLD_MULT
      xpReward = xpReward * FIRST_WIN_BONUS.XP_MULT
    }

    const newStamina = currentStamina - staminaCost
    const now = new Date()
    const attackerNewRating = attackerWon ? newWinnerRating : newLoserRating

    // Build attacker update — persist post-combat HP
    const attackerFinalHp = Math.max(combatResult.finalHp[attacker.id] ?? 0, 0)
    const defenderFinalHp = Math.max(combatResult.finalHp[defender.id] ?? 0, 0)
    const attackerUpdate: Record<string, unknown> = {
      currentStamina: newStamina,
      lastStaminaUpdate: now,
      currentHp: attackerFinalHp,
      lastHpUpdate: now,
      pvpRating: attackerNewRating,
      pvpCalibrationGames: { increment: 1 },
      gold: { increment: goldReward },
      currentXp: { increment: xpReward },
      lastPlayed: now,
    }

    if (hasFreePvp) {
      attackerUpdate.freePvpToday = freePvpUsed + 1
      attackerUpdate.freePvpDate = now
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
    const defenderNewRating = attackerWon ? newLoserRating : newWinnerRating
    const defenderGoldReward = attackerWon ? GOLD_REWARDS.PVP_LOSS_BASE : GOLD_REWARDS.PVP_WIN_BASE
    const defenderXpReward = attackerWon ? XP_REWARDS.PVP_LOSS_XP : XP_REWARDS.PVP_WIN_XP
    const defenderUpdate: Record<string, unknown> = {
      currentHp: defenderFinalHp,
      lastHpUpdate: now,
      pvpRating: defenderNewRating,
      pvpCalibrationGames: { increment: 1 },
      gold: { increment: defenderGoldReward },
      currentXp: { increment: defenderXpReward },
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

    // Execute all DB writes in a transaction
    const txOps: any[] = [
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
          matchType: isRevenge ? 'revenge' : 'ranked',
          isRevenge,
        },
      }),
    ]

    // Mark revenge as used (inside transaction for atomicity)
    if (revenge_id) {
      txOps.push(
        prisma.revengeQueue.update({
          where: { id: revenge_id },
          data: { isUsed: true },
        })
      )
    }

    const txResults = await prisma.$transaction(txOps)
    const updatedAttacker = txResults[0]
    const pvpMatch = txResults[2]

    // Post-transaction side effects (non-blocking for the response)
    const levelUpResult = await applyLevelUp(prisma, attacker.id)
    await applyLevelUp(prisma, defender.id)

    // Create revenge entry for the loser (only for non-revenge matches)
    if (!isRevenge) {
      const expiresAt = new Date(now.getTime() + 72 * 60 * 60 * 1000)
      await prisma.revengeQueue.create({
        data: {
          victimId: loserId,
          attackerId: winnerId,
          matchId: pvpMatch.id,
          expiresAt,
        },
      })
    }

    // Quest + BP progress
    if (attackerWon) {
      await updateDailyQuestProgress(prisma, attacker.id, 'pvp_wins')
    }
    await awardBattlePassXp(prisma, attacker.id, BATTLE_PASS.BP_XP_PER_PVP)

    // Loot
    const loot: LootResponseItem[] = []
    if (attackerWon) {
      const lootItem = await rollAndPersistLoot(prisma, attacker.id, attacker.level, 'pvp', attacker.luk)
      if (lootItem) loot.push(lootItem)
    }

    // Equipment degradation
    const durabilityResult = await degradeEquipment(prisma, attacker.id)

    const ratingChange = attackerNewRating - attacker.pvpRating

    return NextResponse.json({
      verified: true,
      server_winner_id: winnerId,
      client_matches: clientMatchesServer,
      post_combat_hp: {
        player: attackerFinalHp,
        enemy: defenderFinalHp,
      },
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
      loot,
      stamina: {
        current: newStamina,
        max: updatedAttacker.maxStamina,
      },
      durability_changes: durabilityResult.degraded,
      matchId: pvpMatch.id,
    })
  } catch (error) {
    console.error('pvp resolve error:', error)
    return NextResponse.json(
      { error: 'Failed to resolve PvP fight' },
      { status: 500 }
    )
  }
}
