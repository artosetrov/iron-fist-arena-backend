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

    if (character.gold < bet_amount) {
      return NextResponse.json(
        { error: 'Not enough gold' },
        { status: 400 }
      )
    }

    // Generate secret shell (0, 1, or 2)
    const correctShell = Math.floor(Math.random() * 3)

    // Deduct gold and create session in a transaction
    const [, session] = await prisma.$transaction([
      prisma.character.update({
        where: { id: character_id },
        data: { gold: { decrement: bet_amount } },
      }),
      prisma.minigameSession.create({
        data: {
          characterId: character_id,
          gameType: 'shell_game',
          betAmount: bet_amount,
          secretData: { correctShell },
          status: 'active',
        },
      }),
    ])

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
