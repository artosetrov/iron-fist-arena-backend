import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { runCombat } from '@/lib/game/combat'
import { loadCombatCharacter } from '@/lib/game/combat-loader'
import { getKFactor } from '@/lib/game/elo'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import {
  getStaminaConfig,
  getGoldRewardsConfig,
  getXpRewardsConfig,
  getFirstWinBonusConfig,
} from '@/lib/game/live-config'
import {
  chaGoldBonus,
} from '@/lib/game/balance'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { applyLevelUp } from '@/lib/game/progression'
import { rollAndPersistLoot, type LootResponseItem } from '@/lib/game/loot'
import { degradeEquipment } from '@/lib/game/durability'

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

  if (!(await rateLimit(`revenge:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const [STAMINA, GOLD_REWARDS, XP_REWARDS, FIRST_WIN_BONUS] = await Promise.all([
      getStaminaConfig(),
      getGoldRewardsConfig(),
      getXpRewardsConfig(),
      getFirstWinBonusConfig(),
    ])

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
        { error: 'Not enough stamina', current: currentStamina, required: STAMINA.PVP_COST },
        { status: 400 }
      )
    }

    const newStamina = currentStamina - STAMINA.PVP_COST

    // Load combat-ready characters with skills + passives
    const [attackerStats, defenderStats] = await Promise.all([
      loadCombatCharacter(attacker.id),
      loadCombatCharacter(defender.id),
    ])

    const combatResult = runCombat(attackerStats, defenderStats)
    const attackerWon = combatResult.winnerId === attacker.id
    const winnerId = combatResult.winnerId
    const loserId = combatResult.loserId

    // ELO calculation — independent K-factor per player
    const winnerRatingBefore = attackerWon ? attacker.pvpRating : defender.pvpRating
    const loserRatingBefore = attackerWon ? defender.pvpRating : attacker.pvpRating
    const kWinner = getKFactor(attackerWon ? attacker.pvpCalibrationGames : defender.pvpCalibrationGames)
    const kLoser = getKFactor(attackerWon ? defender.pvpCalibrationGames : attacker.pvpCalibrationGames)
    const expectedWinner = 1 / (1 + Math.pow(10, (loserRatingBefore - winnerRatingBefore) / 400))
    const expectedLoser = 1 - expectedWinner
    const newWinnerRating = Math.max(0, Math.round(winnerRatingBefore + kWinner * (1 - expectedWinner)))
    const newLoserRating = Math.max(0, Math.round(loserRatingBefore + kLoser * (0 - expectedLoser)))

    let goldReward = attackerWon
      ? Math.floor(GOLD_REWARDS.PVP_WIN_BASE * GOLD_REWARDS.REVENGE_MULTIPLIER)
      : GOLD_REWARDS.PVP_LOSS_BASE
    let xpReward = attackerWon ? XP_REWARDS.PVP_WIN_XP : XP_REWARDS.PVP_LOSS_XP

    // CHA gold bonus: +0.5% per CHA point
    goldReward = chaGoldBonus(goldReward, attacker.cha)

    const firstWin = attackerWon && isFirstWinOfDay(attacker.firstWinDate)

    if (firstWin) {
      goldReward = goldReward * FIRST_WIN_BONUS.GOLD_MULT
      xpReward = xpReward * FIRST_WIN_BONUS.XP_MULT
    }

    const now = new Date()

    const attackerNewRating = attackerWon ? newWinnerRating : newLoserRating
    const defenderNewRating = attackerWon ? newLoserRating : newWinnerRating

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
    await applyLevelUp(prisma, defender.id)

    // Update daily quest progress
    if (attackerWon) {
      await updateDailyQuestProgress(prisma, attacker.id, 'pvp_wins')
    }

    // Roll for loot drop and persist to inventory
    const loot: LootResponseItem[] = []
    if (attackerWon) {
      const lootItem = await rollAndPersistLoot(prisma, attacker.id, attacker.level, 'pvp', attacker.luk)
      if (lootItem) loot.push(lootItem)
    }

    // Degrade attacker's equipped items after combat
    const durabilityResult = await degradeEquipment(prisma, attacker.id)

    return NextResponse.json({
      loot,
      player: {
        id: attacker.id,
        character_name: attacker.characterName,
        class: attacker.class,
        origin: attacker.origin,
        level: attacker.level,
        max_hp: attacker.maxHp,
        avatar: attacker.avatar,
      },
      enemy: {
        id: defender.id,
        character_name: defender.characterName,
        class: defender.class,
        origin: defender.origin,
        level: defender.level,
        max_hp: defender.maxHp,
        avatar: defender.avatar,
      },
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
      durability_changes: durabilityResult.degraded,
    })
  } catch (error) {
    console.error('pvp revenge [id] error:', error)
    return NextResponse.json({ error: 'Failed to process revenge match' }, { status: 500 })
  }
}
