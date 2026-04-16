import { NextRequest, NextResponse } from 'next/server'
import { randomInt } from 'crypto'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'
import { rateLimit } from '@/lib/rate-limit'

const MIN_BET = 50
const MAX_BET = 1000

type ShellGameStartError = Error & { code?: 'INSUFFICIENT_GOLD' | 'DAILY_LIMIT_REACHED' }

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, bet_amount } = body

    if (!(await rateLimit('shell-start:' + user.id, 10, 60_000))) {
      return NextResponse.json(
        { error: 'Too many requests. Please try again later.' },
        { status: 429 }
      )
    }

    if (!character_id || bet_amount == null) {
      return NextResponse.json(
        { error: 'character_id and bet_amount are required' },
        { status: 400 }
      )
    }

    if (!Number.isInteger(bet_amount) || bet_amount < MIN_BET || bet_amount > MAX_BET) {
      return NextResponse.json(
        { error: `Bet must be between ${MIN_BET} and ${MAX_BET} gold` },
        { status: 400 }
      )
    }

    const character = await prisma.character.findUnique({
      where: { id: character_id },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const today = new Date().toISOString().split('T')[0]

    // Generate the secret shell server-side. Do not return this from /start;
    // the reveal happens only after /guess so clients cannot pre-read wins.
    const correctShell = randomInt(0, 3)

    // Lock the user row, re-check gold, then deduct + create session atomically
    let sessionResult: {
      session: Awaited<ReturnType<typeof prisma.minigameSession.create>>
      playsRemaining: number
    }
    try {
      sessionResult = await prisma.$transaction(async (tx) => {
        const locked = await tx.$queryRaw<{ gold: number }[]>`
          SELECT gold FROM "users" WHERE id = ${user.id} FOR UPDATE
        `
        const currentGold = locked[0]?.gold ?? 0

        // Daily limit belongs inside the same locked transaction as spend + create.
        const todayGames = await tx.minigameSession.count({
          where: {
            characterId: character_id,
            gameType: 'shell_game',
            createdAt: { gte: new Date(today) },
          },
        })
        if (todayGames >= 20) {
          throw Object.assign(new Error('Daily shell game limit reached (20/day)'), {
            code: 'DAILY_LIMIT_REACHED',
          })
        }

        if (currentGold < bet_amount) {
          throw Object.assign(new Error('Not enough gold'), { code: 'INSUFFICIENT_GOLD' })
        }

        await tx.user.update({
          where: { id: user.id },
          data: { gold: { decrement: bet_amount } },
        })

        const session = await tx.minigameSession.create({
          data: {
            characterId: character_id,
            gameType: 'shell_game',
            betAmount: bet_amount,
            secretData: { correctShell },
            status: 'active',
          },
        })

        return {
          session,
          playsRemaining: Math.max(0, 20 - todayGames - 1),
        }
      }, { isolationLevel: 'Serializable' })
    } catch (error) {
      const shellGameError = error as ShellGameStartError
      if (shellGameError.code === 'DAILY_LIMIT_REACHED') {
        return NextResponse.json(
          { error: 'Daily shell game limit reached (20/day)' },
          { status: 429 }
        )
      }
      if (shellGameError.code === 'INSUFFICIENT_GOLD') {
        return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
      }
      throw error
    }

    // Update daily + weekly quest progress for gold spent
    await Promise.all([
      updateDailyQuestProgress(prisma, character_id, 'gold_spent', bet_amount),
      // W3.D5 — Weekly BP challenge: Spendthrift slot
      updateWeeklyChallengeProgress(prisma, character_id, 'gold_spent', bet_amount),
    ])

    return NextResponse.json({
      session_id: sessionResult.session.id,
      bet_amount: sessionResult.session.betAmount,
      plays_remaining: sessionResult.playsRemaining,
      plays_limit: 20,
    })
  } catch (error) {
    console.error('shell-game start error:', error)
    return NextResponse.json(
      { error: 'Failed to start shell game' },
      { status: 500 }
    )
  }
}
