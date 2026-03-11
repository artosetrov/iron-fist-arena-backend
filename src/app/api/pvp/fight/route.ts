import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { runCombat } from '@/lib/game/combat'
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
import { cacheDeletePrefix } from '@/lib/cache'
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

    // Load both characters (select only the fields needed for PvP logic)
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
      avatar: true,
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

    // Check free PvP or stamina (reset counter if new UTC day)
    const freePvpUsed = isNewUtcDay(attacker.freePvpDate) ? 0 : attacker.freePvpToday
    const hasFreePvp = freePvpUsed < STAMINA.FREE_PVP_PER_DAY
    const staminaCost = hasFreePvp ? 0 : STAMINA.PVP_COST

    if (!hasFreePvp && currentStamina < STAMINA.PVP_COST) {
      return NextResponse.json(
        { error: 'Not enough stamina', currentStamina, required: STAMINA.PVP_COST },
        { status: 400 }
      )
    }

    // Load combat-ready characters with skills + passives
    const [attackerStats, defenderStats] = await Promise.all([
      loadCombatCharacter(attacker.id),
      loadCombatCharacter(defender.id),
    ])

    // Run combat
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

    // Calculate rewards with level scaling
    let goldReward: number = attackerWon
      ? levelScaledReward(GOLD_REWARDS.PVP_WIN_BASE, attacker.level)
      : levelScaledReward(GOLD_REWARDS.PVP_LOSS_BASE, attacker.level)
    let xpReward = attackerWon
      ? levelScaledReward(XP_REWARDS.PVP_WIN_XP, attacker.level)
      : levelScaledReward(XP_REWARDS.PVP_LOSS_XP, attacker.level)

    // CHA gold bonus: +1% per CHA point
    goldReward = chaGoldBonus(goldReward, attacker.cha)

    // Win streak gold bonus
    if (attackerWon) {
      const streakBonus = streakGoldMultiplier(attacker.pvpWinStreak)
      if (streakBonus > 0) {
        goldReward = Math.floor(goldReward * (1 + streakBonus))
      }
    }

    // First win of the day bonus
    const firstWin =
      attackerWon && isFirstWinOfDay(attacker.firstWinToday, attacker.firstWinDate)

    if (firstWin) {
      goldReward = goldReward * FIRST_WIN_BONUS.GOLD_MULT
      xpReward = xpReward * FIRST_WIN_BONUS.XP_MULT
    }

    const newStamina = currentStamina - staminaCost
    const now = new Date()

    // Build attacker update — persist post-combat HP
    const attackerNewRating = attackerWon ? newWinnerRating : newLoserRating
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

    // Invalidate leaderboard cache since ratings changed
    cacheDeletePrefix('leaderboard:')

    // Run all post-combat side effects in parallel for maximum speed
    const expiresAt = new Date(now.getTime() + 72 * 60 * 60 * 1000) // 72 hours

    const [levelUpResult, , , , lootItem, durabilityResult] = await Promise.all([
      // 1. Check for level-up (attacker)
      applyLevelUp(prisma, attacker.id),
      // 2. Check for level-up (defender)
      applyLevelUp(prisma, defender.id),
      // 3. Create revenge entry for the loser
      prisma.revengeQueue.create({
        data: {
          victimId: loserId,
          attackerId: winnerId,
          matchId: pvpMatch.id,
          expiresAt,
        },
      }),
      // 4. Update daily quest progress + award Battle Pass XP
      (async () => {
        await Promise.all([
          attackerWon ? updateDailyQuestProgress(prisma, attacker.id, 'pvp_wins') : Promise.resolve(),
          awardBattlePassXp(prisma, attacker.id, BATTLE_PASS.BP_XP_PER_PVP),
        ])
      })(),
      // 5. Roll for loot drop
      attackerWon
        ? rollAndPersistLoot(prisma, attacker.id, attacker.level, 'pvp', attacker.luk)
        : Promise.resolve(null),
      // 6. Degrade attacker's equipped items
      degradeEquipment(prisma, attacker.id),
    ])

    const loot: LootResponseItem[] = []
    if (lootItem) loot.push(lootItem)

    const ratingChange = attackerNewRating - attacker.pvpRating

    // Build combat_log in the format the iOS client expects
    const combat_log = combatResult.turns.map((t) => ({
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

    // Return CombatData format matching iOS CombatData.swift
    return NextResponse.json({
      player: {
        id: attacker.id,
        character_name: attacker.characterName,
        class: attacker.class,
        origin: attacker.origin,
        level: attacker.level,
        max_hp: attacker.maxHp,
        current_hp: attackerStats.currentHp ?? attacker.maxHp,
        avatar: attacker.avatar,
      },
      enemy: {
        id: defender.id,
        character_name: defender.characterName,
        class: defender.class,
        origin: defender.origin,
        level: defender.level,
        max_hp: defender.maxHp,
        current_hp: defenderStats.currentHp ?? defender.maxHp,
        avatar: defender.avatar,
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
      post_combat_hp: {
        player: attackerFinalHp,
        enemy: defenderFinalHp,
      },
      rewards: { gold: goldReward, xp: xpReward },
      loot,
      source: 'pvp',
      matchId: pvpMatch.id,
      stamina: {
        current: newStamina,
        max: updatedAttacker.maxStamina,
      },
      durability_changes: durabilityResult.degraded,
    })
  } catch (error) {
    console.error('pvp fight error:', error)
    return NextResponse.json(
      { error: 'Failed to process PvP fight' },
      { status: 500 }
    )
  }
}
