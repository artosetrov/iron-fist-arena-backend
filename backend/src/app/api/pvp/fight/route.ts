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
  getStaminaConfig,
  getGoldRewardsConfig,
  getXpRewardsConfig,
  getFirstWinBonusConfig,
  getBattlePassConfig,
} from '@/lib/game/live-config'
import {
  chaGoldBonus,
  streakGoldMultiplier,
  levelScaledReward,
} from '@/lib/game/balance'
import { cacheDeletePrefix } from '@/lib/cache'
import { applyLevelUp } from '@/lib/game/progression'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { awardBattlePassXp } from '@/lib/game/battle-pass'
import { degradeEquipment } from '@/lib/game/durability'
import { updateMultipleAchievements } from '@/lib/game/achievements'
import { getActiveEventMultipliers, applyEventGoldMultiplier, applyEventXpMultiplier } from '@/lib/game/events'
import { incrementGuildChallenge } from '@/lib/game/guild-challenge'

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

  if (!(await rateLimit(`pvp-fight:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const [STAMINA, GOLD_REWARDS, XP_REWARDS, FIRST_WIN_BONUS, BATTLE_PASS] = await Promise.all([
      getStaminaConfig(),
      getGoldRewardsConfig(),
      getXpRewardsConfig(),
      getFirstWinBonusConfig(),
      getBattlePassConfig(),
    ])

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
      currentHp: true,
      lastHpUpdate: true,
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

    // Calculate current stamina with regen (optimistic pre-check — full validation happens inside transaction)
    const staminaResultPre = await calculateCurrentStamina(
      attacker.currentStamina,
      attacker.maxStamina,
      attacker.lastStaminaUpdate ?? new Date()
    )
    const freePvpUsedPre = isNewUtcDay(attacker.freePvpDate) ? 0 : attacker.freePvpToday
    const hasFreePvpPre = freePvpUsedPre < STAMINA.FREE_PVP_PER_DAY

    if (!hasFreePvpPre && staminaResultPre.stamina < STAMINA.PVP_COST) {
      return NextResponse.json(
        { error: 'Not enough stamina', currentStamina: staminaResultPre.stamina, required: STAMINA.PVP_COST },
        { status: 400 }
      )
    }

    // Check minimum HP threshold (10% of maxHp) — block fights when near death
    // Use calculateCurrentHp to account for HP regen (same as /pvp/prepare)
    const { calculateCurrentHp } = await import('@/lib/game/hp-regen')
    const hpResult = await calculateCurrentHp(
      attacker.currentHp,
      attacker.maxHp,
      attacker.lastHpUpdate ?? new Date()
    )
    const currentHp = hpResult.hp
    if (hpResult.updated) {
      await prisma.character.update({
        where: { id: character_id },
        data: { currentHp, lastHpUpdate: new Date() },
      })
    }

    const minHpRequired = Math.ceil(attacker.maxHp * 0.1)
    if (currentHp < minHpRequired) {
      return NextResponse.json(
        {
          error: 'Not enough health to fight. Use a health potion first!',
          currentHp,
          minHealthRequired: minHpRequired,
          maxHp: attacker.maxHp,
        },
        { status: 400 }
      )
    }

    // Initialize combat config (class damage formulas from DB)
    await initCombatConfig()

    // Load combat-ready characters with skills + passives
    const [attackerStats, defenderStats] = await Promise.all([
      loadCombatCharacter(attacker.id),
      loadCombatCharacter(defender.id),
    ])

    // Run combat
    const combatResult = await runCombat(attackerStats, defenderStats)
    const attackerWon = combatResult.winnerId === attacker.id
    const winnerId = combatResult.winnerId
    const loserId = combatResult.loserId

    // ELO calculation — independent K-factor per player
    const winnerRatingBefore = attackerWon ? attacker.pvpRating : defender.pvpRating
    const loserRatingBefore = attackerWon ? defender.pvpRating : attacker.pvpRating
    const kWinner = await getKFactor(attackerWon ? attacker.pvpCalibrationGames : defender.pvpCalibrationGames)
    const kLoser = await getKFactor(attackerWon ? defender.pvpCalibrationGames : attacker.pvpCalibrationGames)
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

    // Win streak gold bonus (use current win count: pre-fight streak + 1)
    if (attackerWon) {
      const streakBonus = streakGoldMultiplier(attacker.pvpWinStreak + 1)
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

    // Apply live event multipliers (Double Gold Weekend, Boss Rush, etc.)
    const eventMultipliers = await getActiveEventMultipliers()
    goldReward = applyEventGoldMultiplier(goldReward, eventMultipliers)
    xpReward = applyEventXpMultiplier(xpReward, eventMultipliers)

    const now = new Date()

    // Build attacker and defender updates (stamina fields filled inside transaction)
    const attackerNewRating = attackerWon ? newWinnerRating : newLoserRating
    const attackerFinalHp = Math.max(combatResult.finalHp[attacker.id] ?? 0, 0)
    const defenderFinalHp = Math.max(combatResult.finalHp[defender.id] ?? 0, 0)

    const baseAttackerUpdate: Record<string, unknown> = {
      currentHp: attackerFinalHp,
      lastHpUpdate: now,
      pvpRating: attackerNewRating,
      pvpCalibrationGames: { increment: 1 },
      gold: { increment: goldReward },
      currentXp: { increment: xpReward },
      lastPlayed: now,
    }

    if (attackerWon) {
      baseAttackerUpdate.pvpWins = { increment: 1 }
      baseAttackerUpdate.pvpWinStreak = { increment: 1 }
      baseAttackerUpdate.pvpLossStreak = 0
      if (attacker.highestPvpRank === null || attackerNewRating > attacker.highestPvpRank) {
        baseAttackerUpdate.highestPvpRank = attackerNewRating
      }
      if (firstWin) {
        baseAttackerUpdate.firstWinToday = true
        baseAttackerUpdate.firstWinDate = now
      }
    } else {
      baseAttackerUpdate.pvpLosses = { increment: 1 }
      baseAttackerUpdate.pvpLossStreak = { increment: 1 }
      baseAttackerUpdate.pvpWinStreak = 0
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
      if (defender.highestPvpRank === null || defenderNewRating > defender.highestPvpRank) {
        defenderUpdate.highestPvpRank = defenderNewRating
      }
    } else {
      defenderUpdate.pvpLosses = { increment: 1 }
      defenderUpdate.pvpLossStreak = { increment: 1 }
      defenderUpdate.pvpWinStreak = 0
    }

    // Execute all DB writes in a transaction with a FOR UPDATE row lock on the
    // attacker to atomically validate + deduct stamina (prevents TOCTOU race).
    let newStamina: number
    const { updatedAttacker, pvpMatch } = await prisma.$transaction(async (tx) => {
      // Lock the attacker row so concurrent requests cannot race on stamina
      const [lockedRow] = await tx.$queryRawUnsafe<Array<{
        id: string
        current_stamina: number
        max_stamina: number
        last_stamina_update: Date
        free_pvp_today: number
        free_pvp_date: Date | null
      }>>(
        `SELECT id, current_stamina, max_stamina, last_stamina_update, free_pvp_today, free_pvp_date
         FROM characters WHERE id = $1 FOR UPDATE`,
        attacker.id
      )

      if (!lockedRow) throw new Error('ATTACKER_NOT_FOUND')

      // Re-calculate stamina with regen from the authoritative locked values
      const lockedStaminaResult = await calculateCurrentStamina(
        lockedRow.current_stamina,
        lockedRow.max_stamina,
        lockedRow.last_stamina_update ?? new Date()
      )
      const lockedCurrentStamina = lockedStaminaResult.stamina
      const lockedFreePvpUsed = isNewUtcDay(lockedRow.free_pvp_date) ? 0 : lockedRow.free_pvp_today
      const lockedHasFreePvp = lockedFreePvpUsed < STAMINA.FREE_PVP_PER_DAY
      const lockedStaminaCost = lockedHasFreePvp ? 0 : STAMINA.PVP_COST

      if (!lockedHasFreePvp && lockedCurrentStamina < STAMINA.PVP_COST) {
        throw new Error('NOT_ENOUGH_STAMINA')
      }

      newStamina = lockedCurrentStamina - lockedStaminaCost

      // Merge stamina fields into the attacker update
      const attackerUpdate: Record<string, unknown> = {
        ...baseAttackerUpdate,
        currentStamina: newStamina,
        lastStaminaUpdate: now,
      }
      if (lockedHasFreePvp) {
        attackerUpdate.freePvpToday = lockedFreePvpUsed + 1
        attackerUpdate.freePvpDate = now
      }

      const updatedAttacker = await tx.character.update({ where: { id: attacker.id }, data: attackerUpdate })
      await tx.character.update({ where: { id: defender.id }, data: defenderUpdate })

      const pvpMatch = await tx.pvpMatch.create({
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

      return { updatedAttacker, pvpMatch }
    })

    // Invalidate leaderboard cache since ratings changed
    await cacheDeletePrefix('leaderboard:')

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
        return await Promise.all([
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
      // 7. Track PvP + ranking achievements (fire-and-forget, non-blocking)
      (async () => {
        try {
          const achievementUpdates: { key: string; increment: number; absolute?: boolean }[] = []
          if (attackerWon) {
            const newStreak = attacker.pvpWinStreak + 1
            achievementUpdates.push(
              { key: 'pvp_first_blood', increment: 1 },
              { key: 'pvp_wins_10', increment: 1 },
              { key: 'pvp_wins_50', increment: 1 },
              { key: 'pvp_wins_100', increment: 1 },
              { key: 'pvp_wins_500', increment: 1 },
              { key: 'pvp_streak_5', increment: newStreak, absolute: true },
              { key: 'pvp_streak_10', increment: newStreak, absolute: true },
            )
          }
          // Ranking achievements — set absolute rating value
          achievementUpdates.push(
            { key: 'rank_silver', increment: attackerNewRating, absolute: true },
            { key: 'rank_gold', increment: attackerNewRating, absolute: true },
            { key: 'rank_diamond', increment: attackerNewRating, absolute: true },
            { key: 'rank_grandmaster', increment: attackerNewRating, absolute: true },
          )
          await updateMultipleAchievements(prisma, attacker.id, achievementUpdates)
        } catch (e) {
          console.error('Achievement tracking error (pvp/fight):', e)
        }
      })(),
    ])

    // 8. Increment guild challenge (fire-and-forget)
    if (attackerWon) {
      incrementGuildChallenge(prisma, 'pvp_wins', 1).catch(() => {})
    }
    incrementGuildChallenge(prisma, 'gold_earned', goldReward).catch(() => {})

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
      activeEvents: eventMultipliers.activeEvents,
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
    if (error instanceof Error) {
      if (error.message === 'NOT_ENOUGH_STAMINA') {
        return NextResponse.json(
          { error: 'Not enough stamina', required: 0 },
          { status: 400 }
        )
      }
    }
    console.error('pvp fight error:', error)
    return NextResponse.json(
      { error: 'Failed to process PvP fight' },
      { status: 500 }
    )
  }
}
