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
  trainingXpMultiplier,
} from '@/lib/game/balance'
import { cacheDeletePrefix } from '@/lib/cache'
import { applyLevelUp } from '@/lib/game/progression'
import { track as trackAnalytics } from '@/lib/analytics'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { awardBattlePassXp } from '@/lib/game/battle-pass'
import { degradeEquipment } from '@/lib/game/durability'
import { updateMultipleAchievements } from '@/lib/game/achievements'
import { getActiveEventMultipliers, applyEventGoldMultiplier, applyEventXpMultiplier } from '@/lib/game/events'
import { incrementGuildChallenge } from '@/lib/game/guild-challenge'
import { goldBonusMultiplier, PREMIUM_ENTITLEMENT_USER_SELECT } from '@/lib/game/premium'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'
import { generateDungeonFloor, getDungeonBossCount, type Enemy } from '@/lib/game/dungeon'
import { currentDailyValue } from '@/lib/game/daily-counter'
import { lockDungeonRunForUpdate } from '@/lib/game/dungeon-run-lock'
import { Prisma } from '@prisma/client'

interface DungeonRunFightState {
  enemies: Enemy[]
  isBoss: boolean
  floorsCleared: number
  totalGoldEarned: number
  totalXpEarned: number
}

// Mirrors floorGoldReward / floorXpReward in /api/dungeons/run/[id]/fight.
function dungeonFloorGoldReward(floor: number, difficulty: string): number {
  const base = 30 + floor * 10
  const mult = difficulty === 'hard' ? 1.5 : difficulty === 'easy' ? 0.7 : 1.0
  return Math.round(base * mult)
}
function dungeonFloorXpReward(floor: number, difficulty: string): number {
  const base = 20 + floor * 8
  const mult = difficulty === 'hard' ? 1.5 : difficulty === 'easy' ? 0.7 : 1.0
  return Math.round(base * mult)
}

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

    const match = await prisma.pvpMatch.findUnique({ where: { id: match_id } })
    if (!match) return NextResponse.json({ error: 'Match not found' }, { status: 404 })
    if (match.status !== 'in_progress') {
      return NextResponse.json({ error: 'Match is not in progress' }, { status: 409 })
    }

    const opponentType = match.opponentType ?? 'pvp'
    const isBot = opponentType === 'bot'
    const isDungeonBoss = opponentType === 'dungeon_boss'
    const isPvp = opponentType === 'pvp'

    if (isPvp && !match.player2Id) {
      return NextResponse.json(
        { error: 'Player-vs-player opponent missing' },
        { status: 409 },
      )
    }

    // Bot opponents travel via opponentSnapshot (no DB row). PvP opponents
    // are loaded from the characters table and receive side-effects (gold,
    // ELO, loss streak, revenge queue entry).
    interface BotSnapshot {
      kind: 'bot' | 'dungeon_boss'
      id: string
      character_name: string
      class: string
      level: number
      avatar: string | null
      max_hp: number
    }
    const botSnapshot = isBot || isDungeonBoss
      ? (match.opponentSnapshot as unknown as BotSnapshot | null)
      : null
    if ((isBot || isDungeonBoss) && !botSnapshot) {
      return NextResponse.json(
        { error: 'Opponent snapshot missing on non-PvP match' },
        { status: 500 },
      )
    }

    const select = {
      id: true, userId: true, characterName: true, class: true, origin: true,
      avatar: true, level: true, maxHp: true, currentHp: true, lastHpUpdate: true,
      luk: true, cha: true, pvpRating: true, pvpCalibrationGames: true,
      pvpWins: true, pvpLosses: true, pvpWinStreak: true, pvpLossStreak: true,
      freePvpToday: true, freePvpDate: true, firstWinToday: true, firstWinDate: true,
      highestPvpRank: true,
      dungeonClearsToday: true, dungeonClearsDate: true,
      user: { select: PREMIUM_ENTITLEMENT_USER_SELECT },
    } as const
    const attacker = await prisma.character.findUnique({ where: { id: match.player1Id }, select })
    if (!attacker) return NextResponse.json({ error: 'Characters missing' }, { status: 404 })
    if (attacker.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    const defender = isPvp && match.player2Id
      ? await prisma.character.findUnique({ where: { id: match.player2Id }, select })
      : null
    if (isPvp && !defender) {
      return NextResponse.json({ error: 'Characters missing' }, { status: 404 })
    }

    // Proxy object for bot opponents — just enough for shared code below that
    // reads defender.maxHp / defender.id / etc. Never written to the DB.
    type DefenderProxy = {
      id: string
      characterName: string
      class: string
      origin: string | null
      avatar: string | null
      level: number
      maxHp: number
      pvpRating: number
      pvpCalibrationGames: number
      highestPvpRank: number | null
    }
    const defenderProxy: DefenderProxy = defender
      ? {
          id: defender.id,
          characterName: defender.characterName,
          class: defender.class,
          origin: defender.origin,
          avatar: defender.avatar,
          level: defender.level,
          maxHp: defender.maxHp,
          pvpRating: defender.pvpRating,
          pvpCalibrationGames: defender.pvpCalibrationGames,
          highestPvpRank: defender.highestPvpRank,
        }
      : {
          id: botSnapshot!.id,
          characterName: botSnapshot!.character_name,
          class: botSnapshot!.class,
          origin: null,
          avatar: botSnapshot!.avatar,
          level: botSnapshot!.level,
          maxHp: botSnapshot!.max_hp,
          pvpRating: attacker.pvpRating, // bots share rating scale with player
          pvpCalibrationGames: attacker.pvpCalibrationGames,
          highestPvpRank: null,
        }

    const choices = Array.isArray(match.interactiveChoices)
      ? (match.interactiveChoices as unknown as StoredRound[])
      : []
    if (choices.length === 0) {
      return NextResponse.json({ error: 'No rounds played' }, { status: 400 })
    }

    const isAttackerFirstMatch = (attacker.pvpWins + attacker.pvpLosses) === 0

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
      const dPct = defenderFinalHp / defenderProxy.maxHp
      attackerWon = aPct >= dPct
    }
    // `winnerId` / `loserId` are used for two purposes:
    //   1. iOS response (`result.winner_id`) — anything goes, iOS compares by id
    //   2. DB persistence on `pvp_matches` — must be a real `characters.id`
    //      because `winner_id_fkey` / `loser_id_fkey` are FK-constrained.
    //
    // Bot and dungeon_boss opponents are synthetic (id lives in
    // `opponentSnapshot` JSON, no row in `characters`), so we keep the
    // synthetic id for the response but split out *CharacterId vars that
    // NULL-out the non-PvP side for the DB write. See FK violation incident
    // 2026-04-20 ("Failed to complete match" on bot fights).
    const winnerId = attackerWon ? attacker.id : defenderProxy.id
    const loserId  = attackerWon ? defenderProxy.id : attacker.id
    const winnerCharacterId =
      attackerWon ? attacker.id : (isPvp && defender ? defender.id : null)
    const loserCharacterId =
      attackerWon ? (isPvp && defender ? defender.id : null) : attacker.id

    // ELO: for PvP, full K-factor symmetric calc. For bots, use a scaled-down
    // asymmetric change so grinding bots doesn't pump rating (matches the
    // original /pvp/resolve bot path: +30%k on win, -10%k on loss).
    let newWinnerRating: number
    let newLoserRating: number
    if (isBot) {
      const kFactor = await getKFactor(attacker.pvpCalibrationGames)
      const delta = attackerWon
        ? Math.round(kFactor * 0.3)
        : -Math.round(kFactor * 0.1)
      const attackerAfter = Math.max(0, attacker.pvpRating + delta)
      newWinnerRating = attackerWon ? attackerAfter : defenderProxy.pvpRating
      newLoserRating  = attackerWon ? defenderProxy.pvpRating : attackerAfter
    } else {
      const winnerRatingBefore = attackerWon ? attacker.pvpRating : defenderProxy.pvpRating
      const loserRatingBefore  = attackerWon ? defenderProxy.pvpRating : attacker.pvpRating
      const kWinner = await getKFactor(attackerWon ? attacker.pvpCalibrationGames : defenderProxy.pvpCalibrationGames)
      const kLoser  = await getKFactor(attackerWon ? defenderProxy.pvpCalibrationGames : attacker.pvpCalibrationGames)
      const expectedWinner = 1 / (1 + Math.pow(10, (loserRatingBefore - winnerRatingBefore) / 400))
      const expectedLoser  = 1 - expectedWinner
      newWinnerRating = Math.max(0, Math.round(winnerRatingBefore + kWinner * (1 - expectedWinner)))
      newLoserRating  = Math.max(0, Math.round(loserRatingBefore  + kLoser  * (0 - expectedLoser)))
    }

    // Rewards — formula diverges by mode.
    //   PvP/bot  — `/pvp/fight`-compatible formula (PVP_WIN/LOSS_BASE).
    //   dungeon_boss — `/dungeons/run/:id/fight`-compatible (floor * difficulty).
    let goldReward: number
    let xpReward: number
    let rawXpReward = 0          // unscaled XP (dungeon only, for DR reporting)
    let dungeonXpMultiplier = 1.0
    let dungeonClearsAfter = 0    // for training DR response

    const dungeonRun =
      isDungeonBoss && match.dungeonRunId
        ? await prisma.dungeonRun.findFirst({ where: { id: match.dungeonRunId } })
        : null
    if (isDungeonBoss && !dungeonRun) {
      return NextResponse.json(
        { error: 'Dungeon run disappeared mid-match.' },
        { status: 409 },
      )
    }

    if (isDungeonBoss && dungeonRun) {
      const currentFloor = dungeonRun.currentFloor
      // Training-XP DR is per-character-per-UTC-day. Mirrors the logic in
      // /dungeons/run/:id/fight verbatim so rewards stay identical across
      // both code paths until the old endpoint is retired.
      const clearsUsedToday = currentDailyValue(
        attacker.dungeonClearsToday ?? 0,
        attacker.dungeonClearsDate ?? null,
        new Date(),
      )
      dungeonClearsAfter = clearsUsedToday + 1
      dungeonXpMultiplier = trainingXpMultiplier(clearsUsedToday)

      const baseGold = dungeonFloorGoldReward(currentFloor, dungeonRun.difficulty)
      rawXpReward = dungeonFloorXpReward(currentFloor, dungeonRun.difficulty)

      if (attackerWon) {
        goldReward = Math.floor(
          chaGoldBonus(baseGold, attacker.cha) * goldBonusMultiplier(attacker.user),
        )
        xpReward = Math.round(rawXpReward * dungeonXpMultiplier)
      } else {
        // Loss forfeits current-floor rewards — matches dungeon-run semantics
        // where defeat ends the run and the player keeps earlier floors only.
        goldReward = 0
        xpReward = 0
      }
    } else {
      goldReward = attackerWon
        ? levelScaledReward(GOLD_REWARDS.PVP_WIN_BASE, attacker.level)
        : levelScaledReward(GOLD_REWARDS.PVP_LOSS_BASE, attacker.level)
      xpReward = attackerWon
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
    }

    // firstWin logic applies to the PvP/bot path only; dungeons don't
    // participate in the per-day PvP win bonus. eventMultipliers is loaded
    // here (once) for the response payload and loot/achievement side-effects.
    const firstWin = !isDungeonBoss && attackerWon && isNewUtcDay(attacker.firstWinDate)
    const eventMultipliers = await getActiveEventMultipliers()

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

    // Defender side-effects only apply for real PvP opponents. Bots have no DB row.
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
      if (defenderProxy.highestPvpRank === null || defenderNewRating > defenderProxy.highestPvpRank) {
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

    // For dungeon_boss, pre-compute the next floor + advance conditions so we
    // can bundle the DungeonRun update into the same transaction.
    let dungeonNextFloorData: ReturnType<typeof generateDungeonFloor> | null = null
    let dungeonIsComplete = false
    let dungeonFloorJustCleared = 0
    if (isDungeonBoss && dungeonRun && attackerWon) {
      dungeonFloorJustCleared = dungeonRun.currentFloor
      const bossIndex = dungeonRun.currentFloor
      const totalBosses = getDungeonBossCount(dungeonRun.dungeonId)
      dungeonIsComplete = bossIndex >= totalBosses
      dungeonNextFloorData = dungeonIsComplete
        ? { enemies: [], isBoss: false }
        : generateDungeonFloor(dungeonRun.currentFloor + 1, dungeonRun.difficulty, dungeonRun.dungeonId)
    }

    // Transactional finalize: idempotent via updateMany(status='in_progress')
    const finalizeResult = await prisma.$transaction(async (tx) => {
      const res = await tx.pvpMatch.updateMany({
        where: { id: match_id, status: 'in_progress' },
        data: {
          player1RatingAfter: attackerNewRating,
          player2RatingAfter: defenderNewRating,
          winnerId: winnerCharacterId,
          loserId: loserCharacterId,
          combatLog: JSON.parse(JSON.stringify(combat_log)) as Prisma.InputJsonValue,
          turnsTaken: combat_log.length,
          goldReward, xpReward,
          status: 'completed',
        },
      })
      if (res.count === 0) return null  // raced to completion

      await tx.character.update({ where: { id: attacker.id }, data: baseAttackerUpdate })
      if (goldReward > 0) {
        await tx.user.update({ where: { id: attacker.userId }, data: { gold: { increment: goldReward } } })
      }

      // PvP-only side-effects on the defender + revenge queue. Bots + dungeon bosses have no DB row.
      if (isPvp && defender) {
        await tx.character.update({ where: { id: defender.id }, data: defenderUpdate })
        await tx.user.update({ where: { id: defender.userId }, data: { gold: { increment: defenderGoldReward } } })
        const expiresAt = new Date(now.getTime() + 72 * 60 * 60 * 1000)
        await tx.revengeQueue.create({
          data: { victimId: loserId, attackerId: winnerId, matchId: match.id, expiresAt },
        })
      }

      // Dungeon-specific: advance the run's floor counter or delete on
      // completion / defeat. Mirrors /api/dungeons/run/[id]/fight semantics.
      if (isDungeonBoss && dungeonRun) {
        const lockedRun = await lockDungeonRunForUpdate(tx, dungeonRun.id)
        if (!lockedRun) throw new Error('DUNGEON_RUN_NOT_ACTIVE')
        if (
          lockedRun.characterId !== attacker.id ||
          lockedRun.dungeonId !== dungeonRun.dungeonId ||
          lockedRun.difficulty !== dungeonRun.difficulty
        ) {
          throw new Error('DUNGEON_RUN_MISMATCH')
        }
        if (lockedRun.currentFloor !== dungeonRun.currentFloor) {
          throw new Error('DUNGEON_RUN_STALE')
        }

        if (!attackerWon) {
          await tx.dungeonRun.delete({ where: { id: dungeonRun.id } })
        } else {
          const state = (dungeonRun.state as unknown as DungeonRunFightState | null) ?? {
            enemies: [], isBoss: false, floorsCleared: 0, totalGoldEarned: 0, totalXpEarned: 0,
          }
          // Track daily-clear counter on character for training XP DR.
          await tx.character.update({
            where: { id: attacker.id },
            data: {
              dungeonClearsToday: dungeonClearsAfter,
              dungeonClearsDate: now,
            },
          })
          // DungeonProgress upsert for the dungeon completion tracker.
          await tx.dungeonProgress.upsert({
            where: {
              characterId_dungeonId: {
                characterId: attacker.id,
                dungeonId: dungeonRun.dungeonId,
              },
            },
            create: {
              characterId: attacker.id,
              dungeonId: dungeonRun.dungeonId,
              bossIndex: dungeonRun.currentFloor,
              completed: dungeonIsComplete,
            },
            update: {
              bossIndex: { set: dungeonRun.currentFloor },
              completed: dungeonIsComplete,
            },
          })
          if (dungeonIsComplete) {
            await tx.dungeonRun.delete({ where: { id: dungeonRun.id } })
          } else if (dungeonNextFloorData) {
            await tx.dungeonRun.update({
              where: { id: dungeonRun.id },
              data: {
                currentFloor: dungeonRun.currentFloor + 1,
                state: JSON.parse(JSON.stringify({
                  enemies: dungeonNextFloorData.enemies,
                  isBoss: dungeonNextFloorData.isBoss,
                  floorsCleared: state.floorsCleared + 1,
                  totalGoldEarned: state.totalGoldEarned + goldReward,
                  totalXpEarned: state.totalXpEarned + xpReward,
                })) as Prisma.InputJsonValue,
              },
            })
          }
        }
      }
      return true
    })

    if (finalizeResult === null) {
      return NextResponse.json({ error: 'Match already completed' }, { status: 409 })
    }

    await cacheDeletePrefix('leaderboard:')

    // Side effects (parallel). Fork by opponentType:
    //   - PvP : applyLevelUp(defender), pvp_wins quest, pvp loot, pvp achievements
    //   - bot : same as PvP minus defender level-up (no DB row)
    //   - dungeon_boss : dungeons_complete quest, dungeon_<diff> loot, skip pvp achievements
    const isFinalDungeonBoss = isDungeonBoss && dungeonIsComplete
    const lootKey: string | null = !attackerWon
      ? null
      : isDungeonBoss
        ? (isFinalDungeonBoss ? 'boss' : `dungeon_${dungeonRun?.difficulty ?? 'normal'}`)
        : 'pvp'
    const questKey = isDungeonBoss ? 'dungeons_complete' : 'pvp_wins'
    const bpXpGrant = isDungeonBoss
      ? BATTLE_PASS.BP_XP_PER_DUNGEON_FLOOR
      : BATTLE_PASS.BP_XP_PER_PVP

    const [levelUpResult, , , lootItem, durabilityResult] = await Promise.all([
      applyLevelUp(prisma, attacker.id),
      isPvp && defender ? applyLevelUp(prisma, defender.id) : Promise.resolve(null),
      (async () => {
        await Promise.all([
          attackerWon ? updateDailyQuestProgress(prisma, attacker.id, questKey) : Promise.resolve(),
          attackerWon && !isDungeonBoss ? updateWeeklyChallengeProgress(prisma, attacker.id, 'pvp_wins') : Promise.resolve(),
          attackerWon && isDungeonBoss ? updateWeeklyChallengeProgress(prisma, attacker.id, 'dungeons_complete') : Promise.resolve(),
          awardBattlePassXp(prisma, attacker.id, bpXpGrant),
        ])
      })(),
      lootKey
        ? rollAndPersistLoot(prisma, attacker.id, attacker.level, lootKey, attacker.luk)
        : Promise.resolve(null),
      degradeEquipment(prisma, attacker.id),
      (async () => {
        try {
          // PvP / bot achievements track pvp_wins + rank tiers. Dungeons have
          // their own achievement set which lives in /api/dungeons/*; skip
          // pvp_* here to avoid mis-attributing floor clears as PvP wins.
          if (isDungeonBoss) return
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

    // Guild challenges: pvp_wins only credits actual player-vs-player wins.
    // Bot/dungeon fights still count toward gold_earned.
    if (attackerWon && isPvp) incrementGuildChallenge(prisma, 'pvp_wins', 1).catch(() => {})
    if (goldReward > 0) incrementGuildChallenge(prisma, 'gold_earned', goldReward).catch(() => {})

    const loot: LootResponseItem[] = []
    if (lootItem) loot.push(lootItem)

    const ratingChange = attackerNewRating - attacker.pvpRating

    if (isAttackerFirstMatch) {
      trackAnalytics({
        name: 'first_pvp',
        userId: attacker.userId,
        characterId: attacker.id,
        won: attackerWon,
        totalTurns: combat_log.length,
        ratingAfter: attackerNewRating,
      })
    }

    return NextResponse.json({
      player: {
        id: attacker.id, character_name: attacker.characterName,
        class: attacker.class, origin: attacker.origin, level: attacker.level,
        max_hp: attacker.maxHp, current_hp: attackerFinalHp, avatar: attacker.avatar,
      },
      enemy: {
        id: defenderProxy.id, character_name: defenderProxy.characterName,
        class: defenderProxy.class, origin: defenderProxy.origin, level: defenderProxy.level,
        max_hp: defenderProxy.maxHp, current_hp: defenderFinalHp, avatar: defenderProxy.avatar,
      },
      combat_log,
      result: {
        is_win: attackerWon, winner_id: winnerId,
        gold_reward: goldReward, xp_reward: xpReward,
        turns_taken: combat_log.length, rating_change: ratingChange,
        // Combat V2 D-1 (2026-04-29): expose absolute rating bounds so the
        // RewardsBlock can render delta + new total ("+24 / 1248") instead
        // of delta-only. Always-present pair — bots also surface them so
        // the iOS view doesn't need to branch on opponent type.
        rating_before: attacker.pvpRating,
        rating_after: attackerNewRating,
        first_win_bonus: firstWin,
        leveled_up: levelUpResult?.leveledUp ?? false,
        new_level: levelUpResult?.newLevel,
        stat_points_awarded: levelUpResult?.statPointsAwarded,
        passive_points_awarded: levelUpResult?.passivePointsAwarded,
      },
      post_combat_hp: { player: attackerFinalHp, enemy: defenderFinalHp },
      rewards: { gold: goldReward, xp: xpReward },
      activeEvents: eventMultipliers.activeEvents,
      loot,
      source: isBot ? 'bot' : isDungeonBoss ? 'dungeon' : 'pvp',
      opponent_type: opponentType,
      // Dungeon-only block — mirrors /api/dungeons/run/[id]/fight response
      // shape so the same iOS screen can render both paths.
      dungeon: isDungeonBoss && dungeonRun
        ? {
            run_id: dungeonRun.id,
            dungeon_id: dungeonRun.dungeonId,
            difficulty: dungeonRun.difficulty,
            floor_cleared: dungeonFloorJustCleared,
            is_final_boss: isFinalDungeonBoss,
            next_floor:
              dungeonNextFloorData && !dungeonIsComplete
                ? {
                    number: dungeonRun.currentFloor + 1,
                    enemies: dungeonNextFloorData.enemies,
                    is_boss: dungeonNextFloorData.isBoss,
                  }
                : null,
            dungeon_complete: dungeonIsComplete,
            training_dr: {
              clears_today: dungeonClearsAfter,
              current_multiplier: dungeonXpMultiplier,
              xp_raw: rawXpReward,
            },
          }
        : undefined,
      matchId: match.id,
      durability_changes: durabilityResult.degraded,
    })
  } catch (error) {
    console.error('pvp match/complete error:', error)
    return NextResponse.json({ error: 'Failed to complete match' }, { status: 500 })
  }
}
