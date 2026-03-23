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
import { applyLevelUp } from '@/lib/game/progression'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { awardBattlePassXp } from '@/lib/game/battle-pass'
import { degradeEquipment } from '@/lib/game/durability'
import { cacheDeletePrefix } from '@/lib/cache'
import { updateMultipleAchievements } from '@/lib/game/achievements'

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

  if (!(await rateLimit(`pvp-resolve:${user.id}`, 10, 60_000))) {
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
    const { character_id, opponent_id, battle_seed, battle_ticket_id, client_winner_id, revenge_id } = body
    const isRevenge = !!revenge_id

    if (!character_id || !opponent_id || battle_seed == null || !battle_ticket_id) {
      return NextResponse.json(
        { error: 'character_id, opponent_id, battle_seed, and battle_ticket_id are required' },
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
    const staminaResult = await calculateCurrentStamina(
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

    const combatResult = await runCombat(attackerStats, defenderStats, battle_seed)
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
    const kWinner = await getKFactor(attackerWon ? attacker.pvpCalibrationGames : defender.pvpCalibrationGames)
    const kLoser = await getKFactor(attackerWon ? defender.pvpCalibrationGames : attacker.pvpCalibrationGames)
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

    // Win streak gold bonus (use current win count: pre-fight streak + 1)
    if (attackerWon) {
      const streakBonus = streakGoldMultiplier(attacker.pvpWinStreak + 1)
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

    if (hasFreePvp && !isRevenge) {
      attackerUpdate.freePvpToday = freePvpUsed + 1
      attackerUpdate.freePvpDate = now
    }

    if (attackerWon) {
      attackerUpdate.pvpWins = { increment: 1 }
      attackerUpdate.pvpWinStreak = { increment: 1 }
      attackerUpdate.pvpLossStreak = 0
      if (attacker.highestPvpRank === null || attackerNewRating > attacker.highestPvpRank) {
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
      if (defender.highestPvpRank === null || defenderNewRating > defender.highestPvpRank) {
        defenderUpdate.highestPvpRank = defenderNewRating
      }
    } else {
      defenderUpdate.pvpLosses = { increment: 1 }
      defenderUpdate.pvpLossStreak = { increment: 1 }
      defenderUpdate.pvpWinStreak = 0
    }

    // Execute all DB writes in a transaction and atomically consume the battle ticket.
    const { updatedAttacker, pvpMatch } = await prisma.$transaction(async (tx) => {
      const [ticketRow] = await tx.$queryRawUnsafe<Array<{
        id: string
        character_id: string
        opponent_id: string
        revenge_id: string | null
        battle_seed: number
        expires_at: Date
        consumed_at: Date | null
      }>>(
        `SELECT id, character_id, opponent_id, revenge_id, battle_seed, expires_at, consumed_at
         FROM pvp_battle_tickets
         WHERE id = $1
         FOR UPDATE`,
        battle_ticket_id
      )

      if (!ticketRow) throw new Error('BATTLE_TICKET_NOT_FOUND')
      if (ticketRow.consumed_at) throw new Error('BATTLE_TICKET_CONSUMED')
      if (new Date() > ticketRow.expires_at) throw new Error('BATTLE_TICKET_EXPIRED')
      if (
        ticketRow.character_id !== attacker.id ||
        ticketRow.opponent_id !== defender.id ||
        ticketRow.battle_seed !== battle_seed ||
        (ticketRow.revenge_id ?? null) !== (revenge_id ?? null)
      ) {
        throw new Error('BATTLE_TICKET_MISMATCH')
      }

      const updatedAttacker = await tx.character.update({
        where: { id: attacker.id },
        data: attackerUpdate,
      })

      await tx.character.update({
        where: { id: defender.id },
        data: defenderUpdate,
      })

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
          matchType: isRevenge ? 'revenge' : 'ranked',
          isRevenge,
        },
      })

      if (revenge_id) {
        await tx.revengeQueue.update({
          where: { id: revenge_id },
          data: { isUsed: true },
        })
      }

      await tx.pvpBattleTicket.update({
        where: { id: battle_ticket_id },
        data: { consumedAt: now },
      })

      return { updatedAttacker, pvpMatch }
    })

    // Invalidate leaderboard cache since ratings changed
    await cacheDeletePrefix('leaderboard:')

    // Post-transaction side effects — run in parallel for speed
    const expiresAt = new Date(now.getTime() + 72 * 60 * 60 * 1000)

    const [levelUpResult, , , , lootItem, durabilityResult] = await Promise.all([
      // 1. Level-up check (attacker)
      applyLevelUp(prisma, attacker.id),
      // 2. Level-up check (defender)
      applyLevelUp(prisma, defender.id),
      // 3. Create revenge entry for loser (non-revenge matches only)
      !isRevenge
        ? prisma.revengeQueue.create({
            data: {
              victimId: loserId,
              attackerId: winnerId,
              matchId: pvpMatch.id,
              expiresAt,
            },
          })
        : Promise.resolve(null),
      // 4. Quest + Battle Pass progress
      (async () => {
        return await Promise.all([
          attackerWon ? updateDailyQuestProgress(prisma, attacker.id, 'pvp_wins') : Promise.resolve(),
          awardBattlePassXp(prisma, attacker.id, BATTLE_PASS.BP_XP_PER_PVP),
        ])
      })(),
      // 5. Loot roll
      attackerWon
        ? rollAndPersistLoot(prisma, attacker.id, attacker.level, 'pvp', attacker.luk)
        : Promise.resolve(null),
      // 6. Equipment degradation
      degradeEquipment(prisma, attacker.id),
      // 7. Track PvP + revenge + ranking achievements
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
            // Revenge-specific achievements
            if (isRevenge) {
              achievementUpdates.push(
                { key: 'revenge_first', increment: 1 },
                { key: 'revenge_wins_10', increment: 1 },
              )
            }
          }
          // Ranking achievements — absolute rating
          achievementUpdates.push(
            { key: 'rank_silver', increment: attackerNewRating, absolute: true },
            { key: 'rank_gold', increment: attackerNewRating, absolute: true },
            { key: 'rank_diamond', increment: attackerNewRating, absolute: true },
            { key: 'rank_grandmaster', increment: attackerNewRating, absolute: true },
          )
          await updateMultipleAchievements(prisma, attacker.id, achievementUpdates)
        } catch (e) {
          console.error('Achievement tracking error (pvp/resolve):', e)
        }
      })(),
    ])

    const loot: LootResponseItem[] = []
    if (lootItem) loot.push(lootItem)

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
    if (error instanceof Error) {
      if (error.message === 'BATTLE_TICKET_NOT_FOUND') {
        return NextResponse.json({ error: 'Battle ticket not found. Prepare the fight again.' }, { status: 404 })
      }
      if (error.message === 'BATTLE_TICKET_CONSUMED') {
        return NextResponse.json({ error: 'This battle was already resolved.' }, { status: 409 })
      }
      if (error.message === 'BATTLE_TICKET_EXPIRED') {
        return NextResponse.json({ error: 'Battle preparation expired. Start a new fight.' }, { status: 400 })
      }
      if (error.message === 'BATTLE_TICKET_MISMATCH') {
        return NextResponse.json({ error: 'Battle preparation does not match this resolve request.' }, { status: 400 })
      }
    }
    console.error('pvp resolve error:', error)
    return NextResponse.json(
      { error: 'Failed to resolve PvP fight' },
      { status: 500 }
    )
  }
}
