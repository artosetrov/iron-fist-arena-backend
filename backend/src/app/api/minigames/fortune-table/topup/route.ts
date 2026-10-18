import { NextRequest, NextResponse } from 'next/server'
import type { Prisma } from '@prisma/client'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'
import { asRoundSecret, tierFor, topUpRejection, withTopUp } from '@/lib/game/fortune-table'
import { FORTUNE_TABLE_GAME, roundView, serializableTx } from '@/lib/game/fortune-table-server'

type TopUpError = Error & { code?: string }

const MESSAGES: Record<string, [string, number]> = {
  NOT_FOUND: ['Round not found', 404],
  NOT_OPEN: ['This round is over', 409],
  LOCKED: ['Bets are closed', 409],
  BELOW_MIN: ['That top-up is below the table minimum', 400],
  OVER_MAX: ['That would pass the table maximum for one seat', 400],
  NOT_ENOUGH_GOLD: ['Not enough gold', 400],
}

/** Add gold to your seat while the lobby is open — a bigger slice of the wheel. */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    if (!(await rateLimit('fortune-table-topup:' + user.id, 30, 60_000))) {
      return NextResponse.json({ error: 'Too many requests. Please try again later.' }, { status: 429 })
    }
    const body = await req.json()
    const { character_id: characterId, round_id: roundId, amount } = body ?? {}
    if (!characterId || !roundId || amount == null) {
      return NextResponse.json({ error: 'character_id, round_id and amount are required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({ where: { id: characterId }, select: { userId: true } })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    let outcome: { session: Awaited<ReturnType<typeof prisma.minigameSession.update>>; gold: number; now: number }
    try {
      outcome = await serializableTx(prisma, async (tx) => {
        // Round row first, then the user — the same order as settleRound, so
        // a last-second top-up and the draw queue instead of deadlocking.
        await tx.$queryRaw`SELECT id FROM "minigame_sessions" WHERE id = ${roundId} FOR UPDATE`
        const lockedUser = await tx.$queryRaw<{ gold: number }[]>`
          SELECT gold FROM "users" WHERE id = ${user.id} FOR UPDATE
        `
        const row = await tx.minigameSession.findUnique({ where: { id: roundId } })
        if (!row || row.characterId !== characterId || row.gameType !== FORTUNE_TABLE_GAME) {
          throw Object.assign(new Error('NOT_FOUND'), { code: 'NOT_FOUND' })
        }
        const secret = asRoundSecret(row.secretData)
        const tier = secret ? tierFor(secret.tier) : undefined
        if (row.status !== 'active' || !secret || !tier) throw Object.assign(new Error('NOT_OPEN'), { code: 'NOT_OPEN' })

        const now = Date.now()
        const elapsed = now - row.createdAt.getTime()
        const rejection = topUpRejection(secret, tier, amount, elapsed)
        if (rejection) throw Object.assign(new Error(rejection), { code: rejection })

        const gold = lockedUser[0]?.gold ?? 0
        if (gold < amount) throw Object.assign(new Error('NOT_ENOUGH_GOLD'), { code: 'NOT_ENOUGH_GOLD' })

        await tx.user.update({ where: { id: user.id }, data: { gold: { decrement: amount } } })
        const session = await tx.minigameSession.update({
          where: { id: row.id },
          data: {
            betAmount: { increment: amount },
            secretData: withTopUp(secret, amount, elapsed) as unknown as Prisma.InputJsonValue,
          },
        })
        return { session, gold: gold - amount, now }
      })
    } catch (error) {
      const code = (error as TopUpError).code
      if (code && MESSAGES[code]) {
        const [message, status] = MESSAGES[code]
        return NextResponse.json({ error: message, code }, { status })
      }
      throw error
    }

    await Promise.all([
      updateDailyQuestProgress(prisma, characterId, 'gold_spent', amount),
      updateWeeklyChallengeProgress(prisma, characterId, 'gold_spent', amount),
    ])

    return NextResponse.json({ round: roundView(outcome.session, outcome.now), gold: outcome.gold })
  } catch (error) {
    console.error('fortune-table topup error:', error)
    return NextResponse.json({ error: 'Failed to top up' }, { status: 500 })
  }
}
