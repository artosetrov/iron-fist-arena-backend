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
  chaGoldBonus,
} from '@/lib/game/balance'
import { applyLevelUp } from '@/lib/game/progression'
import { rollAndPersistLoot, type LootResponseItem } from '@/lib/game/loot'

/**
 * GET /api/pvp/revenge?character_id=xxx
 * Returns available revenge entries for the character.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
    })
    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const now = new Date()

    // Find active (not used, not expired) revenge entries where this character is the victim
    const revengeEntries = await prisma.revengeQueue.findMany({
      where: {
        victimId: characterId,
        isUsed: false,
        expiresAt: { gt: now },
      },
      include: {
        attacker: true,
      },
      orderBy: { createdAt: 'desc' },
      take: 20,
    })

    const entries = revengeEntries.map((r) => ({
      id: r.id,
      attacker_id: r.attacker.id,
      attacker_name: r.attacker.characterName,
      attacker_class: r.attacker.class,
      attacker_level: r.attacker.level,
      attacker_rating: r.attacker.pvpRating,
      rating_lost: 0,
      created_at: r.createdAt.toISOString(),
    }))

    return NextResponse.json({ revenge_list: entries })
  } catch (error) {
    console.error('get revenge list error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch revenge list' },
      { status: 500 }
    )
  }
}

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

  if (!rateLimit(`revenge:${user.id}`, 10, 60_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, revenge_id } = body

    if (!character_id || !revenge_id) {
      return NextResponse.json(
        { error: 'character_id and revenge_id are required' },
        { status: 400 }
      )
    }

    // Load revenge entry
    const revenge = await prisma.revengeQueue.findUnique({
      where: { id: revenge_id },
    })

    if (!revenge) {
      return NextResponse.json({ error: 'Revenge entry not found' }, { status: 404 })
    }

    // Verify the caller is the victim (the one who lost and can take revenge)
    if (revenge.victimId !== character_id) {
      return NextResponse.json(
        { error: 'This revenge does not belong to your character' },
        { status: 403 }
      )
    }

    if (revenge.isUsed) {
      return NextResponse.json(
        { error: 'Revenge has already been used' },
        { status: 400 }
      )
    }

    if (new Date() > revenge.expiresAt) {
      return NextResponse.json(
        { error: 'Revenge has expired' },
        { status: 400 }
      )
    }

    // Load both characters (victim = attacker in revenge, attacker = defender)
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

    const attackerWon = combatResult.winnerId === attacker.id
    const winnerId = combatResult.winnerId
    const loserId = combatResult.loserId

    // ELO calculation
    const winnerRatingBefore = attackerWon ? attacker.pvpRating : defender.pvpRating
    const loserRatingBefore = attackerWon ? defender.pvpRating : attacker.pvpRating
    const winnerCalibration = attackerWon ? attacker.pvpCalibrationGames : defender.pvpCalibrationGames
    const kFactor = getKFactor(winnerCalibration)
    const eloResult = calculateElo(winnerRatingBefore, loserRatingBefore, kFactor)

    // Calculate rewards with REVENGE_MULTIPLIER for gold
    let goldReward = attackerWon
      ? Math.floor(GOLD_REWARDS.PVP_WIN_BASE * GOLD_REWARDS.REVENGE_MULTIPLIER)
      : GOLD_REWARDS.PVP_LOSS_BASE
    let xpReward = attackerWon ? XP_REWARDS.PVP_WIN_XP : XP_REWARDS.PVP_LOSS_XP

    // CHA gold bonus: +0.5% per CHA point
    goldReward = chaGoldBonus(goldReward, attacker.cha)

    // First win of the day bonus
    const firstWin =
      attackerWon && isFirstWinOfDay(attacker.firstWinToday, attacker.firstWinDate)

    if (firstWin) {
      goldReward = goldReward * FIRST_WIN_BONUS.GOLD_MULT
      xpReward = xpReward * FIRST_WIN_BONUS.XP_MULT
    }

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

    // Execute all DB writes in a transaction
    const [updatedAttacker, , pvpMatch] = await prisma.$transaction([
      prisma.character.update({
        where: { id: attacker.id },
        data: attackerUpdate,
      }),
      prisma.character.update({
        where: { id: defender.id },
        data: defenderUpdate,
      }),
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
      // Mark revenge as used
      prisma.revengeQueue.update({
        where: { id: revenge_id },
        data: { isUsed: true },
      }),
    ])

    // Check for level-up after XP award
    const levelUpResult = await applyLevelUp(prisma, attacker.id)

    // Roll for loot drop and persist to inventory
    const loot: LootResponseItem[] = []
    if (attackerWon) {
      const lootItem = await rollAndPersistLoot(prisma, attacker.id, attacker.level, 'pvp', attacker.luk)
      if (lootItem) loot.push(lootItem)
    }

    const ratingChange = attackerWon
      ? attackerNewRating - attacker.pvpRating
      : -(attacker.pvpRating - attackerNewRating)

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
    console.error('pvp revenge error:', error)
    return NextResponse.json(
      { error: 'Failed to process revenge match' },
      { status: 500 }
    )
  }
}
