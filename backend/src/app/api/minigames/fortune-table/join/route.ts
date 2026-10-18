import { NextRequest, NextResponse } from 'next/server'
import type { Prisma } from '@prisma/client'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'
import { FORTUNE_TABLE, openRound, tierFor } from '@/lib/game/fortune-table'
import {
  FORTUNE_TABLE_GAME, activeRound, roundView, serializableTx, settleDueRounds, todayStart,
} from '@/lib/game/fortune-table-server'

type JoinError = Error & { code?: string }

/** Sit down at Fortune's Table: stake gold and open a round (or resume the open one). */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    if (!(await rateLimit('fortune-table-join:' + user.id, 20, 60_000))) {
      return NextResponse.json({ error: 'Too many requests. Please try again later.' }, { status: 429 })
    }
    const body = await req.json()
    const { character_id: characterId, tier: tierKey, stake } = body ?? {}
    if (!characterId || !tierKey || stake == null) {
      return NextResponse.json({ error: 'character_id, tier and stake are required' }, { status: 400 })
    }
    const tier = tierFor(String(tierKey))
    if (!tier) return NextResponse.json({ error: 'Unknown table', code: 'UNKNOWN_TIER' }, { status: 400 })
    if (!Number.isInteger(stake) || stake < tier.minStake || stake > tier.maxStake) {
      return NextResponse.json(
        { error: `Stake must be between ${tier.minStake} and ${tier.maxStake} gold`, code: 'BAD_STAKE' },
        { status: 400 },
      )
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { userId: true, level: true, characterName: true },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    if (character.level < tier.minLevel) {
      return NextResponse.json(
        { error: `This table opens at level ${tier.minLevel}`, code: 'TIER_LOCKED' },
        { status: 403 },
      )
    }

    const now = Date.now()
    await settleDueRounds(prisma, { characterId, userId: user.id, level: character.level, nowMs: now })

    let outcome: { session: Awaited<ReturnType<typeof prisma.minigameSession.create>>; gold: number; roundsToday: number; resumed: boolean }
    try {
      outcome = await serializableTx(prisma, async (tx) => {
        const locked = await tx.$queryRaw<{ gold: number }[]>`
          SELECT gold FROM "users" WHERE id = ${user.id} FOR UPDATE
        `
        const gold = locked[0]?.gold ?? 0

        // One round at a time: an open lobby is resumed, not paid for twice.
        const open = await activeRound(tx, characterId, now)
        const roundsToday = await tx.minigameSession.count({
          where: { characterId, gameType: FORTUNE_TABLE_GAME, createdAt: { gte: todayStart(now) } },
        })
        if (open) return { session: open, gold, roundsToday, resumed: true }

        if (roundsToday >= FORTUNE_TABLE.dailyRounds) {
          throw Object.assign(new Error('DAILY_LIMIT'), { code: 'DAILY_LIMIT' })
        }
        if (gold < stake) throw Object.assign(new Error('NOT_ENOUGH_GOLD'), { code: 'NOT_ENOUGH_GOLD' })

        await tx.user.update({ where: { id: user.id }, data: { gold: { decrement: stake } } })
        const secret = openRound({ tier, stake, playerName: character.characterName })
        const session = await tx.minigameSession.create({
          data: {
            characterId,
            gameType: FORTUNE_TABLE_GAME,
            betAmount: stake,
            secretData: secret as unknown as Prisma.InputJsonValue,
            status: 'active',
          },
        })
        return { session, gold: gold - stake, roundsToday: roundsToday + 1, resumed: false }
      })
    } catch (error) {
      const code = (error as JoinError).code
      if (code === 'DAILY_LIMIT') {
        return NextResponse.json(
          { error: `Fortune's Table is closed for today (${FORTUNE_TABLE.dailyRounds} rounds)`, code },
          { status: 429 },
        )
      }
      if (code === 'NOT_ENOUGH_GOLD') return NextResponse.json({ error: 'Not enough gold', code }, { status: 400 })
      throw error
    }

    if (!outcome.resumed) {
      await Promise.all([
        updateDailyQuestProgress(prisma, characterId, 'shell_game_play'),
        updateDailyQuestProgress(prisma, characterId, 'gold_spent', stake),
        updateWeeklyChallengeProgress(prisma, characterId, 'shell_game_play'),
        updateWeeklyChallengeProgress(prisma, characterId, 'gold_spent', stake),
      ])
    }

    return NextResponse.json({
      round: roundView(outcome.session, Date.now()),
      gold: outcome.gold,
      rounds_today: outcome.roundsToday,
      rounds_limit: FORTUNE_TABLE.dailyRounds,
      resumed: outcome.resumed,
    })
  } catch (error) {
    console.error('fortune-table join error:', error)
    return NextResponse.json({ error: 'Failed to join the table' }, { status: 500 })
  }
}
