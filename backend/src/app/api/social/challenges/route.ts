import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
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
} from '@/lib/game/live-config'
import {
  chaGoldBonus,
  streakGoldMultiplier,
  levelScaledReward,
} from '@/lib/game/balance'
import { cacheDeletePrefix } from '@/lib/cache'
import { applyLevelUp } from '@/lib/game/progression'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { degradeEquipment } from '@/lib/game/durability'

const MAX_PENDING_CHALLENGES = 5
const CHALLENGE_EXPIRY_HOURS = 24
const MAX_CHALLENGES_PER_DAY = 10
const CHALLENGE_GOLD_MULTIPLIER = 1.2

function isNewUtcDay(date: Date | null): boolean {
  if (!date) return true
  const today = new Date()
  today.setUTCHours(0, 0, 0, 0)
  const d = new Date(date)
  d.setUTCHours(0, 0, 0, 0)
  return d.getTime() < today.getTime()
}

/**
 * GET /api/social/challenges?character_id=xxx
 * Returns pending + recent challenges for the character.
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
      select: { id: true, userId: true },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    const now = new Date()

    // Expire old challenges
    await prisma.challenge.updateMany({
      where: {
        status: 'pending',
        expiresAt: { lt: now },
      },
      data: { status: 'expired' },
    })

    // Get incoming (defender) challenges
    const incoming = await prisma.challenge.findMany({
      where: {
        defenderId: characterId,
        status: 'pending',
      },
      include: {
        challenger: {
          select: {
            id: true,
            characterName: true,
            class: true,
            level: true,
            pvpRating: true,
            avatar: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 20,
    })

    // Get outgoing (challenger) challenges
    const outgoing = await prisma.challenge.findMany({
      where: {
        challengerId: characterId,
        status: { in: ['pending', 'accepted', 'declined'] },
        createdAt: { gte: new Date(now.getTime() - 48 * 60 * 60 * 1000) },
      },
      include: {
        defender: {
          select: {
            id: true,
            characterName: true,
            class: true,
            level: true,
            pvpRating: true,
            avatar: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 20,
    })

    // Get recent completed duels (last 48h)
    const completed = await prisma.challenge.findMany({
      where: {
        OR: [
          { challengerId: characterId },
          { defenderId: characterId },
        ],
        status: 'completed',
        completedAt: { gte: new Date(now.getTime() - 48 * 60 * 60 * 1000) },
      },
      include: {
        challenger: {
          select: {
            id: true,
            characterName: true,
            class: true,
            level: true,
            pvpRating: true,
          },
        },
        defender: {
          select: {
            id: true,
            characterName: true,
            class: true,
            level: true,
            pvpRating: true,
          },
        },
        match: {
          select: {
            winnerId: true,
            goldReward: true,
            xpReward: true,
          },
        },
      },
      orderBy: { completedAt: 'desc' },
      take: 10,
    })

    return NextResponse.json({
      incoming: incoming.map((c: any) => ({
        id: c.id,
        challenger: c.challenger,
        message: c.message,
        goldWager: c.goldWager,
        createdAt: c.createdAt,
        expiresAt: c.expiresAt,
      })),
      outgoing: outgoing.map((c: any) => ({
        id: c.id,
        defender: c.defender,
        status: c.status,
        message: c.message,
        goldWager: c.goldWager,
        createdAt: c.createdAt,
        respondedAt: c.respondedAt,
      })),
      completed: completed.map((c: any) => ({
        id: c.id,
        challenger: c.challenger,
        defender: c.defender,
        winnerId: c.match?.winnerId,
        goldReward: c.match?.goldReward ?? 0,
        xpReward: c.match?.xpReward ?? 0,
        completedAt: c.completedAt,
      })),
    })
  } catch (err: any) {
    console.error('get challenges error:', err)
    return NextResponse.json({ error: 'Failed to fetch challenges' }, { status: 500 })
  }
}

/**
 * POST /api/social/challenges
 * Body: { character_id, action, ... }
 * Actions: send, accept, decline
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, action } = body

    if (!character_id || !action) {
      return NextResponse.json({ error: 'character_id and action are required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: character_id },
      select: {
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
        luk: true,
        level: true,
        characterName: true,
        class: true,
        pvpWins: true,
        pvpLosses: true,
        pvpWinStreak: true,
        pvpLossStreak: true,
        currentHp: true,
        gold: true,
      },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    switch (action) {
      case 'send':
        return handleSend(character, body)
      case 'accept':
        return handleAccept(character, body)
      case 'decline':
        return handleDecline(character, body)
      default:
        return NextResponse.json({ error: `Unknown action: ${action}` }, { status: 400 })
    }
  } catch (err: any) {
    console.error('challenge action error:', err)
    return NextResponse.json({ error: 'Failed to process challenge' }, { status: 500 })
  }
}

async function handleSend(character: any, body: any) {
  const { target_id, message } = body
  if (!target_id) {
    return NextResponse.json({ error: 'target_id is required' }, { status: 400 })
  }
  if (character.id === target_id) {
    return NextResponse.json({ error: 'Cannot challenge yourself' }, { status: 400 })
  }

  // Check target exists
  const target = await prisma.character.findUnique({
    where: { id: target_id },
    select: { id: true, characterName: true },
  })
  if (!target) {
    return NextResponse.json({ error: 'Target not found' }, { status: 404 })
  }

  const now = new Date()
  const todayStart = new Date()
  todayStart.setUTCHours(0, 0, 0, 0)

  // Check daily limit
  const todaySent = await prisma.challenge.count({
    where: {
      challengerId: character.id,
      createdAt: { gte: todayStart },
    },
  })
  if (todaySent >= MAX_CHALLENGES_PER_DAY) {
    return NextResponse.json({ error: 'Daily challenge limit reached (10)' }, { status: 429 })
  }

  // Check no duplicate pending challenge to same target
  const existingPending = await prisma.challenge.findFirst({
    where: {
      challengerId: character.id,
      defenderId: target_id,
      status: 'pending',
    },
  })
  if (existingPending) {
    return NextResponse.json({ error: 'Challenge already pending to this player' }, { status: 409 })
  }

  // Check target doesn't have too many pending incoming
  const targetPending = await prisma.challenge.count({
    where: {
      defenderId: target_id,
      status: 'pending',
    },
  })
  if (targetPending >= MAX_PENDING_CHALLENGES * 4) {
    return NextResponse.json({ error: 'Target has too many pending challenges' }, { status: 429 })
  }

  // Check stamina (challenger pays on send)
  const STAMINA = await getStaminaConfig()
  const staminaResult = await calculateCurrentStamina(
    character.currentStamina,
    character.maxStamina,
    character.lastStaminaUpdate
  )
  const currentStamina = staminaResult.stamina
  const staminaCost = STAMINA.PVP_COST
  if (currentStamina < staminaCost) {
    return NextResponse.json({ error: 'Not enough stamina' }, { status: 400 })
  }

  // Create challenge + deduct stamina
  const expiresAt = new Date(now.getTime() + CHALLENGE_EXPIRY_HOURS * 60 * 60 * 1000)

  const [challenge] = await prisma.$transaction([
    prisma.challenge.create({
      data: {
        challengerId: character.id,
        defenderId: target_id,
        message: message?.slice(0, 100) || null,
        expiresAt,
      },
    }),
    prisma.character.update({
      where: { id: character.id },
      data: {
        currentStamina: currentStamina - staminaCost,
        lastStaminaUpdate: now,
      },
    }),
  ])

  return NextResponse.json({
    challenge: {
      id: challenge.id,
      defenderId: target_id,
      defenderName: target.characterName,
      status: 'pending',
      message: challenge.message,
      expiresAt: challenge.expiresAt,
    },
  })
}

async function handleAccept(character: any, body: any) {
  const { challenge_id } = body
  if (!challenge_id) {
    return NextResponse.json({ error: 'challenge_id is required' }, { status: 400 })
  }

  const challenge = await prisma.challenge.findUnique({
    where: { id: challenge_id },
  })
  if (!challenge) return NextResponse.json({ error: 'Challenge not found' }, { status: 404 })
  if (challenge.defenderId !== character.id) {
    return NextResponse.json({ error: 'This challenge is not for you' }, { status: 403 })
  }
  if (challenge.status !== 'pending') {
    return NextResponse.json({ error: `Challenge is ${challenge.status}, not pending` }, { status: 400 })
  }
  if (challenge.expiresAt < new Date()) {
    await prisma.challenge.update({ where: { id: challenge_id }, data: { status: 'expired' } })
    return NextResponse.json({ error: 'Challenge has expired' }, { status: 410 })
  }

  // Mark as accepted
  await prisma.challenge.update({
    where: { id: challenge_id },
    data: { status: 'accepted', respondedAt: new Date() },
  })

  // --- Run the fight (reuse combat engine) ---
  const [STAMINA, GOLD_REWARDS, XP_REWARDS] = await Promise.all([
    getStaminaConfig(),
    getGoldRewardsConfig(),
    getXpRewardsConfig(),
  ])

  await initCombatConfig()

  // Load full combat data for both
  const [attackerData, defenderData] = await Promise.all([
    loadCombatCharacter(challenge.challengerId),
    loadCombatCharacter(character.id),
  ])

  if (!attackerData || !defenderData) {
    return NextResponse.json({ error: 'Failed to load combat data' }, { status: 500 })
  }

  // Run combat — challenger is player1, defender is player2
  const combatResult = await runCombat(attackerData, defenderData)

  // Determine winner/loser
  const challengerWon = combatResult.winnerId === challenge.challengerId
  const winnerId = combatResult.winnerId
  const loserId = challengerWon ? character.id : challenge.challengerId

  // Load winner/loser for rewards
  const [winner, loser] = await Promise.all([
    prisma.character.findUnique({
      where: { id: winnerId },
      select: {
        id: true, level: true, cha: true, luk: true,
        pvpWins: true, pvpLosses: true, pvpWinStreak: true, pvpLossStreak: true,
        pvpRating: true, pvpCalibrationGames: true, highestPvpRank: true,
        firstWinToday: true, firstWinDate: true,
        gold: true, currentHp: true,
      },
    }),
    prisma.character.findUnique({
      where: { id: loserId },
      select: {
        id: true, level: true, cha: true,
        pvpWins: true, pvpLosses: true, pvpWinStreak: true, pvpLossStreak: true,
        pvpRating: true, pvpCalibrationGames: true, highestPvpRank: true,
        gold: true, currentHp: true,
      },
    }),
  ])

  if (!winner || !loser) {
    return NextResponse.json({ error: 'Winner/loser not found' }, { status: 500 })
  }

  // ELO calculation
  const winnerK = await getKFactor(winner.pvpCalibrationGames)
  const loserK = await getKFactor(loser.pvpCalibrationGames)
  const expectedWin = 1 / (1 + Math.pow(10, (loser.pvpRating - winner.pvpRating) / 400))
  const expectedLose = 1 - expectedWin
  const newWinnerRating = Math.max(0, Math.round(winner.pvpRating + winnerK * (1 - expectedWin)))
  const newLoserRating = Math.max(0, Math.round(loser.pvpRating + loserK * (0 - expectedLose)))

  // Gold/XP rewards (with duel multiplier)
  const winnerGoldBase = levelScaledReward(GOLD_REWARDS.PVP_WIN_BASE, winner.level)
  const loserGoldBase = levelScaledReward(GOLD_REWARDS.PVP_LOSS_BASE, loser.level)
  const winnerGold = chaGoldBonus(Math.round(winnerGoldBase * CHALLENGE_GOLD_MULTIPLIER), winner.cha)
  const loserGold = chaGoldBonus(loserGoldBase, loser.cha)
  const winnerXp = levelScaledReward(XP_REWARDS.PVP_WIN_XP, winner.level)
  const loserXp = levelScaledReward(XP_REWARDS.PVP_LOSS_XP, loser.level)

  // Persist HP
  const winnerFinalHp = Math.max(combatResult.finalHp[winnerId] ?? 0, 0)
  const loserFinalHp = Math.max(combatResult.finalHp[loserId] ?? 0, 0)

  // Create PvpMatch + update characters + complete challenge — all in transaction
  const [pvpMatch] = await prisma.$transaction([
    prisma.pvpMatch.create({
      data: {
        player1Id: challenge.challengerId,
        player2Id: character.id,
        player1RatingBefore: challengerWon ? winner.pvpRating : loser.pvpRating,
        player1RatingAfter: challengerWon ? newWinnerRating : newLoserRating,
        player2RatingBefore: challengerWon ? loser.pvpRating : winner.pvpRating,
        player2RatingAfter: challengerWon ? newLoserRating : newWinnerRating,
        winnerId,
        loserId,
        combatLog: JSON.parse(JSON.stringify(combatResult.turns)),
        matchDuration: 0,
        turnsTaken: combatResult.totalTurns,
        goldReward: winnerGold,
        xpReward: winnerXp,
        matchType: 'challenge',
        isRevenge: false,
      },
    }),
    // Update winner
    prisma.character.update({
      where: { id: winnerId },
      data: {
        pvpRating: newWinnerRating,
        pvpWins: { increment: 1 },
        pvpWinStreak: { increment: 1 },
        pvpLossStreak: 0,
        pvpCalibrationGames: { increment: 1 },
        highestPvpRank: Math.max(winner.highestPvpRank, newWinnerRating),
        gold: { increment: winnerGold },
        currentHp: Math.max(1, winnerFinalHp),
        lastHpUpdate: new Date(),
      },
    }),
    // Update loser
    prisma.character.update({
      where: { id: loserId },
      data: {
        pvpRating: newLoserRating,
        pvpLosses: { increment: 1 },
        pvpLossStreak: { increment: 1 },
        pvpWinStreak: 0,
        pvpCalibrationGames: { increment: 1 },
        gold: { increment: loserGold },
        currentHp: Math.max(1, loserFinalHp),
        lastHpUpdate: new Date(),
      },
    }),
    // Complete the challenge
    prisma.challenge.update({
      where: { id: challenge_id },
      data: {
        status: 'completed',
        completedAt: new Date(),
      },
    }),
  ])

  // Update matchId (after transaction — match ID now available)
  await prisma.challenge.update({
    where: { id: challenge_id },
    data: { matchId: pvpMatch.id },
  })

  // Post-combat async side effects
  Promise.allSettled([
    applyLevelUp(prisma, winnerId),
    applyLevelUp(prisma, loserId),
    updateDailyQuestProgress(prisma, winnerId, 'pvp_win', 1),
    updateDailyQuestProgress(prisma, character.id, 'pvp_fight', 1),
    updateDailyQuestProgress(prisma, challenge.challengerId, 'pvp_fight', 1),
    degradeEquipment(prisma, winnerId),
    degradeEquipment(prisma, loserId),
    cacheDeletePrefix(`leaderboard:`),
  ]).catch((err: any) => console.error('duel post-combat side effects error:', err))

  // Build response with combat data for the accepter (defender)
  const defenderWon = !challengerWon
  return NextResponse.json({
    result: {
      matchId: pvpMatch.id,
      challengeId: challenge_id,
      won: defenderWon,
      winnerId,
      loserId,
      combatLog: combatResult.log,
      turns: combatResult.turns,
      ratingBefore: defenderWon ? winner.pvpRating : loser.pvpRating,
      ratingAfter: defenderWon ? newWinnerRating : newLoserRating,
      ratingChange: defenderWon
        ? newWinnerRating - winner.pvpRating
        : newLoserRating - loser.pvpRating,
      goldReward: defenderWon ? winnerGold : loserGold,
      xpReward: defenderWon ? winnerXp : loserXp,
      challengerName: (await prisma.character.findUnique({
        where: { id: challenge.challengerId },
        select: { characterName: true },
      }))?.characterName ?? 'Unknown',
    },
  })
}

async function handleDecline(character: any, body: any) {
  const { challenge_id } = body
  if (!challenge_id) {
    return NextResponse.json({ error: 'challenge_id is required' }, { status: 400 })
  }

  const challenge = await prisma.challenge.findUnique({
    where: { id: challenge_id },
  })
  if (!challenge) return NextResponse.json({ error: 'Challenge not found' }, { status: 404 })
  if (challenge.defenderId !== character.id) {
    return NextResponse.json({ error: 'This challenge is not for you' }, { status: 403 })
  }
  if (challenge.status !== 'pending') {
    return NextResponse.json({ error: `Challenge is ${challenge.status}, not pending` }, { status: 400 })
  }

  await prisma.challenge.update({
    where: { id: challenge_id },
    data: {
      status: 'declined',
      respondedAt: new Date(),
    },
  })

  return NextResponse.json({ success: true })
}
