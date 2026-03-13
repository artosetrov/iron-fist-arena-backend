import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { rateLimit } from '@/lib/rate-limit'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { session_id, chosen_cup } = body

    if (!(await rateLimit('shell-guess:' + user.id, 10, 60_000))) {
      return NextResponse.json(
        { error: 'Too many requests. Please try again later.' },
        { status: 429 }
      )
    }

    if (!session_id || chosen_cup == null) {
      return NextResponse.json(
        { error: 'session_id and chosen_cup are required' },
        { status: 400 }
      )
    }

    if (![0, 1, 2].includes(chosen_cup)) {
      return NextResponse.json(
        { error: 'chosen_cup must be 0, 1, or 2' },
        { status: 400 }
      )
    }

    // Use interactive transaction with row-level lock to prevent double-guess
    const result = await prisma.$transaction(async (tx) => {
      // Lock the session row for update
      const [sessionRow] = await tx.$queryRawUnsafe<Array<{
        id: string; character_id: string; status: string;
        secret_data: any; bet_amount: number;
      }>>(
        `SELECT id, character_id, status, secret_data, bet_amount FROM minigame_sessions WHERE id = $1 FOR UPDATE`,
        session_id
      )

      if (!sessionRow) throw new Error('NOT_FOUND')
      if (sessionRow.status !== 'active') throw new Error('NOT_ACTIVE')

      // Verify ownership
      const character = await tx.character.findUnique({
        where: { id: sessionRow.character_id },
      })

      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      const secretData = sessionRow.secret_data as { correctShell: number }
      const won = chosen_cup === secretData.correctShell
      const win_amount = won ? sessionRow.bet_amount * 2 : 0

      // Update session status atomically
      await tx.minigameSession.update({
        where: { id: session_id },
        data: {
          status: 'completed',
          result: { won, chosen_cup, correctShell: secretData.correctShell, win_amount },
        },
      })

      let updatedCharacter = character
      // Award gold if won
      if (won) {
        updatedCharacter = await tx.character.update({
          where: { id: sessionRow.character_id },
          data: { gold: { increment: win_amount } },
        })
      }

      return { won, correctShell: secretData.correctShell, win_amount, gold: updatedCharacter.gold, characterId: sessionRow.character_id }
    })

    // Update daily quest progress (outside transaction, non-critical)
    await updateDailyQuestProgress(prisma, result.characterId, 'shell_game_play')

    return NextResponse.json({
      won: result.won,
      winning_cup: result.correctShell,
      win_amount: result.win_amount,
      gold: result.gold,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Session not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'NOT_ACTIVE') return NextResponse.json({ error: 'Session is no longer active' }, { status: 400 })
    }
    console.error('shell-game guess error:', error)
    return NextResponse.json(
      { error: 'Failed to process guess' },
      { status: 500 }
    )
  }
}
