import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { rateLimit } from '@/lib/rate-limit'

const MIN_BET = 50
const MAX_BET = 1000

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

    // Daily limit: max 20 shell games per day
    const today = new Date().toISOString().split('T')[0]
    const todayGames = await prisma.minigameSession.count({
      where: {
        characterId: character_id,
        gameType: 'shell_game',
        createdAt: { gte: new Date(today) },
      },
    })
    if (todayGames >= 20) {
      return NextResponse.json(
        { message: 'Daily shell game limit reached (20/day)' },
        { status: 429 }
      )
    }

    // Generate secret shell (0, 1, or 2)
    const correctShell = Math.floor(Math.random() * 3)

    // Lock the row, re-check gold, then deduct + create session atomically
    let session: Awaited<ReturnType<typeof prisma.minigameSession.create>>
    try {
      session = await prisma.$transaction(async (tx) => {
        const locked = await tx.$queryRaw<{ gold: number }[]>`
          SELECT gold FROM "Character" WHERE id = ${character_id} FOR UPDATE
        `
        const currentGold = locked[0]?.gold ?? 0
        if (currentGold < bet_amount) {
          throw Object.assign(new Error('Not enough gold'), { code: 'INSUFFICIENT_GOLD' })
        }

        await tx.character.update({
          where: { id: character_id },
          data: { gold: { decrement: bet_amount } },
        })

        return tx.minigameSession.create({
          data: {
            characterId: character_id,
            gameType: 'shell_game',
            betAmount: bet_amount,
            secretData: { correctShell },
            status: 'active',
          },
        })
      }, { isolationLevel: 'Serializable' })
    } catch (err: any) {
      if (err.code === 'INSUFFICIENT_GOLD') {
        return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
      }
      throw err
    }

    // Update daily quest progress for gold spent
    await updateDailyQuestProgress(prisma, character_id, 'gold_spent', bet_amount)

    return NextResponse.json({
      session_id: session.id,
      bet_amount: session.betAmount,
    })
  } catch (error) {
    console.error('shell-game start error:', error)
    return NextResponse.json(
      { error: 'Failed to start shell game' },
      { status: 500 }
    )
  }
}
