import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { getKFactor } from '@/lib/game/elo'
import { rollAndPersistLoot, type LootResponseItem } from '@/lib/game/loot'
import {
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
import { goldBonusMultiplier, PREMIUM_ENTITLEMENT_USER_SELECT } from '@/lib/game/premium'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'

/**
 * POST /api/pvp/match/complete — Interactive Combat v1 (FEATURE-FLAGGED)
 *
 * Finalizes an in_progress pvp_matches row: reads interactive_choices, computes
 * ELO, awards gold/xp/loot/achievements — identical side effects to /pvp/fight.
 *
 * Idempotent: second call returns 409 (status !== 'in_progress').
 *
 * Body: { match_id }
 * Returns: same shape as /pvp/fight — CombatData-compatible.
 */

interface StoredRound {
  idx: number
  player_atk: string; player_def: string
  opp_atk: string;    opp_def: string
  player_strike: {
    attackerId: string; defenderId: string; damage: number; isCrit: boolean
    isDodge?: boolean; skillUsed?: string; skillKey?: string
    targetZone?: string; defendZone?: string; healAmount?: number; damageType?: string
  }
  opp_strike: StoredRound['player_strike'] | null
  attacker_hp_after: number
  defender_hp_after: number
}

function isNewUtcDay(date: Date | null): boolean {
  if (!date) return true
  const today = new Date()
  today.setUTCHours(0, 0, 0, 0)
  const d = new Date(date)
  d.setUTCHours(0, 0, 0, 0)
  return d.getTime() < today.getTime()
}

export async function POST(req: NextRequest) {
  if (process.env.INTERACTIVE_COMBAT_V1 === 'false') {
    return NextResponse.json({ error: 'Not Found' }, { status: 404 })
  }

  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`pvp-match-complete:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const [GOLD_REWARDS, XP_REWARDS, FIRST_WIN_BONUS, BATTLE_PASS] = await Promise.all([
      getGoldRewardsConfig(), getXpRewardsConfig(),
      getFirstWinBonusConfig(), getBattlePassConfig(),
    ])

    const body = await req.json()
    const { match_id } = body ?? {}
    if (typeof match_id !== 'string') {
      return NextResponse.json({ error: 'match_id required' }, { status: 400 })
    }

    // Stale Prisma client tolerance (memory: feedback_stale_prisma_client_triage):
    // the 4 Interactive Combat v1 columns exist in schema.prisma + migration file,
    // but the locally generated client may not yet know about them.
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const match: any = await (prisma.pvpMatch.findUnique as any)({ where: { id: match_id } })
    if (!match) return NextResponse.json({ error: 'Match not found' }, { status: 404 })
    if (match.status !== 'in_progress') {
      return NextResponse.json({ error: 'Match is not in progress' }, { status: 409 })
    }

    const select = {
      id: true, userId: true, characterName: true, class: true, origin: true,
      avatar: true, level: true, maxHp: true, currentHp: true, lastHpUpdate: true,
      luk: true, cha: true, pvpRating: true, pvpCalibrationGames: true,
      pvpWins: true, pvpLosses: true, pvpWinStreak: true, pvpLossStreak: true,
      freePvpToday: true, freePvpDate: true, firstWinToday: true, firstWinDate: true,
      highestPvpRank: true,
      user: { select: PREMIUM_ENTITLEMENT_USER_SELECT },
    } as const
    const [attacker, defender] = await Promise.all([
      prisma.character.findUnique({ where: { id: match.player1Id }, select }),
      prisma.character.findUnique({ where: { id: match.player2Id }, select }),
    ])
    if (!attacker || !defender) return NextResponse.json({ error: 'Characters missing' }, { status: 404 })
    if (attacker.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    const choices = Array.isArray(match.interactiveChoices)
      ? (match.interactiveChoices as unknown as StoredRound[])
      : []
    if (choices.length === 0) {
      return NextResponse.json({ error: 'No rounds played' }, { status: 400 })
    }

    const last = choices[choices.length - 1]
    const attackerFinalHp = Math.max(0, last.attacker_hp_after)
    const defenderFinalHp = Math.max(0, last.defender_hp_after)

    // Winner already decided during /strike when match_finished went true
    let attackerWon: boolean
    if (defenderFinalHp === 0 && attackerFinalHp > 0) attackerWon = true
    else if (attackerFinalHp === 0 && defenderFinalHp > 0) attackerWon = false
    else {
      // Max rounds: higher HP% wins
      const aPct = attackerFinalHp / attacker.maxHp
      const dPct = defenderFinalHp / defender.maxHp
      attackerWon = aPct >= dPct
    }
    const winnerId = attackerWon ? attacker.id : defender.id
    const loserId  = attackerWon ? defender.id : attacker.id

    // ELO
    const winnerRatingBefore = attackerWon ? attacker.pvpRating : defender.pvpRating
    const loserRatingBefore  = attackerWon ? defender.pvpRating : attacker.pvpRating
    const kWinner = await getKFactor(attackerWon ? attacker.pvpCalibrationGames : defender.pvpCalibrationGames)
    const kLoser  = await getKFactor(attackerWon ? defender.pvpCalibrationGames : attacker.pvpCalibrationGames)
    const expectedWinner = 1 / (1 + Math.pow(10, (loserRatingBefore - winnerRatingBefore) / 400))
    const expectedLoser  = 1 - expectedWinner
    const newWinnerRating = Math.max(0, Math.round(winnerRatingBefore + kWinner * (1 - expectedWinner)))
    const newLoserRating  = Math.max(0, Math.round(loserRatingBefore  + kLoser  * (0 - expectedLoser)))

    // Rewards — same formulas as /pvp/fight
    let goldReward = attackerWon
      ? levelScaledReward(GOLD_REWARDS.PVP_WIN_BASE, attacker.level)
      : levelScaledReward(GOLD_REWARDS.PVP_LOSS_BASE, attacker.level)
    let xpReward = attackerWon
      ? levelScaledReward(XP_REWARDS.PVP_WIN_XP, attacker.level)
      : levelScaledReward(XP_REWARDS.PVP_LOSS_XP, attacker.level)

    goldReward = chaGoldBonus(goldReward, attacker.cha)
    if (attackerWon) {
      const streakBonus = streakGoldMultiplier(attacker.pvpWinStreak + 1)
      if (streakBonus > 0) goldReward = Math.floor(goldReward * (1 + streakBonus))
    }
    const firstWin = attackerWon && isNewUtcDay(attacker.firstWinDate)
    if (firstWin) {
      goldReward = goldReward * FIRST_WIN_BONUS.GOLD_MULT
      xpReward   = xpReward   * FIRST_WIN_BONUS.XP_MULT
    }
    const eventMultipliers = await getActiveEventMultipliers()
    goldReward = applyEventGoldMultiplier(goldReward, eventMultipliers)
    xpReward   = applyEventXpMultiplier(xpReward, eventMultipliers)
    goldReward = Math.floor(goldReward * goldBonusMultiplier(attacker.user))

    const now = new Date()
    const attackerNewRating = attackerWon ? newWinnerRating : newLoserRating
    const defenderNewRating = attackerWon ? newLoserRating : newWinnerRating

    const baseAttackerUpdate: Record<string, unknown> = {
      currentHp: attackerFinalHp,
      lastHpUpdate: now,
      pvpRating: attackerNewRating,
      pvpCalibrationGames: { increment: 1 },
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

    const defenderGoldReward = attackerWon ? GOLD_REWARDS.PVP_LOSS_BASE : GOLD_REWARDS.PVP_WIN_BASE
    const defenderXpReward   = attackerWon ? XP_REWARDS.PVP_LOSS_XP    : XP_REWARDS.PVP_WIN_XP
    const defenderUpdate: Record<string, unknown> = {
      currentHp: defenderFinalHp,
      lastHpUpdate: now,
      pvpRating: defenderNewRating,
      pvpCalibrationGames: { increment: 1 },
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

    // Reconstruct turns in iOS CombatData-compatible shape
    const combat_log: Array<Record<string, unknown>> = []
    for (const r of choices) {
      const p = r.player_strike
      combat_log.push({
        attacker_id: p.attackerId,
        action: p.isDodge ? 'dodge' : (p.skillUsed ? 'skill' : 'attack'),
        damage: p.damage, is_crit: p.isCrit, is_miss: false,
        is_dodge: !!p.isDodge, target_zone: p.targetZone ?? null,
        defend_zone: p.defendZone ?? null, status_applied: null,
        heal: p.healAmount ?? null, skill_used: p.skillUsed ?? null,
        skill_key: p.skillKey ?? null, damage_type: p.damageType ?? null,
      })
      if (r.opp_strike) {
        const o = r.opp_strike
        combat_log.push({
          attacker_id: o.attackerId,
          action: o.isDodge ? 'dodge' : (o.skillUsed ? 'skill' : 'attack'),
          damage: o.damage, is_crit: o.isCrit, is_miss: false,
          is_dodge: !!o.isDodge, target_zone: o.targetZone ?? null,
          defend_zone: o.defendZone ?? null, status_applied: null,
          heal: o.healAmount ?? null, skill_used: o.skillUsed ?? null,
          skill_key: o.skillKey ?? null, damage_type: o.damageType ?? null,
        })
      }
    }

    // Transactional finalize: idempotent via updateMany(status='in_progress')
    const finalizeResult = await prisma.$transaction(async (tx) => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const res = await (tx.pvpMatch.updateMany as any)({
        where: { id: match_id, status: 'in_progress' },
        data: {
          player1RatingAfter: attackerNewRating,
          player2RatingAfter: defenderNewRating,
          winnerId, loserId,
          combatLog: JSON.parse(JSON.stringify(combat_log)),
          turnsTaken: combat_log.length,
          goldReward, xpReward,
          status: 'completed',
        },
      })
      if (res.count === 0) return null  // raced to completion

      await tx.character.update({ where: { id: attacker.id }, data: baseAttackerUpdate })
      await tx.character.update({ where: { id: defender.id }, data: defenderUpdate })
      await tx.user.update({ where: { id: attacker.userId }, data: { gold: { increment: goldReward } } })
      await tx.user.update({ where: { id: defender.userId }, data: { gold: { increment: defenderGoldReward } } })

      const expiresAt = new Date(now.getTime() + 72 * 60 * 60 * 1000)
      await tx.revengeQueue.create({
        data: { victimId: loserId, attackerId: winnerId, matchId: match.id, expiresAt },
      })
      return true
    })

    if (finalizeResult === null) {
      return NextResponse.json({ error: 'Match already completed' }, { status: 409 })
    }

    await cacheDeletePrefix('leaderboard:')

    // Side effects (parallel)
    const [levelUpResult, , , lootItem, durabilityResult] = await Promise.all([
      applyLevelUp(prisma, attacker.id),
      applyLevelUp(prisma, defender.id),
      (async () => {
        await Promise.all([
          attackerWon ? updateDailyQuestProgress(prisma, attacker.id, 'pvp_wins') : Promise.resolve(),
          attackerWon ? updateWeeklyChallengeProgress(prisma, attacker.id, 'pvp_wins') : Promise.resolve(),
          awardBattlePassXp(prisma, attacker.id, BATTLE_PASS.BP_XP_PER_PVP),
        ])
      })(),
      attackerWon
        ? rollAndPersistLoot(prisma, attacker.id, attacker.level, 'pvp', attacker.luk)
        : Promise.resolve(null),
      degradeEquipment(prisma, attacker.id),
      (async () => {
        try {
          const updates: { key: string; increment: number; absolute?: boolean }[] = []
          if (attackerWon) {
            const newStreak = attacker.pvpWinStreak + 1
            updates.push(
              { key: 'pvp_first_blood', increment: 1 },
              { key: 'pvp_wins_10', increment: 1 },
              { key: 'pvp_wins_50', increment: 1 },
              { key: 'pvp_wins_100', increment: 1 },
              { key: 'pvp_wins_500', increment: 1 },
              { key: 'pvp_streak_5', increment: newStreak, absolute: true },
              { key: 'pvp_streak_10', increment: newStreak, absolute: true },
            )
          }
          updates.push(
            { key: 'rank_silver', increment: attackerNewRating, absolute: true },
            { key: 'rank_gold', increment: attackerNewRating, absolute: true },
            { key: 'rank_diamond', increment: attackerNewRating, absolute: true },
            { key: 'rank_grandmaster', increment: attackerNewRating, absolute: true },
          )
          await updateMultipleAchievements(prisma, attacker.id, updates)
        } catch (e) {
          console.error('Achievement tracking (match/complete):', e)
        }
      })(),
    ])

    if (attackerWon) incrementGuildChallenge(prisma, 'pvp_wins', 1).catch(() => {})
    incrementGuildChallenge(prisma, 'gold_earned', goldReward).catch(() => {})

    const loot: LootResponseItem[] = []
    if (lootItem) loot.push(lootItem)

    const ratingChange = attackerNewRating - attacker.pvpRating

    return NextResponse.json({
      player: {
        id: attacker.id, character_name: attacker.characterName,
        class: attacker.class, origin: attacker.origin, level: attacker.level,
        max_hp: attacker.maxHp, current_hp: attackerFinalHp, avatar: attacker.avatar,
      },
      enemy: {
        id: defender.id, character_name: defender.characterName,
        class: defender.class, origin: defender.origin, level: defender.level,
        max_hp: defender.maxHp, current_hp: defenderFinalHp, avatar: defender.avatar,
      },
      combat_log,
      result: {
        is_win: attackerWon, winner_id: winnerId,
        gold_reward: goldReward, xp_reward: xpReward,
        turns_taken: combat_log.length, rating_change: ratingChange,
        first_win_bonus: firstWin,
        leveled_up: levelUpResult?.leveledUp ?? false,
        new_level: levelUpResult?.newLevel,
        stat_points_awarded: levelUpResult?.statPointsAwarded,
      },
      post_combat_hp: { player: attackerFinalHp, enemy: defenderFinalHp },
      rewards: { gold: goldReward, xp: xpReward },
      activeEvents: eventMultipliers.activeEvents,
      loot,
      source: 'pvp',
      matchId: match.id,
      durability_changes: durabilityResult.degraded,
    })
  } catch (error) {
    console.error('pvp match/complete error:', error)
    return NextResponse.json({ error: 'Failed to complete match' }, { status: 500 })
  }
}
