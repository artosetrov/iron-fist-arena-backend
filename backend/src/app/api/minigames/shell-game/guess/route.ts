import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'
import { updateTutorialQuestProgress } from '@/lib/game/tutorial'
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

      // Fetch current gold from database (auth user doesn't have gold field)
      const userRow = await tx.user.findUnique({
        where: { id: user.id },
        select: { gold: true },
      })
      let userGold = userRow?.gold ?? 0

      // Award gold if won
      if (won) {
        const updatedUser = await tx.user.update({
          where: { id: user.id },
          data: { gold: { increment: win_amount } },
          select: { gold: true },
        })
        userGold = updatedUser.gold
      }

      return { won, correctShell: secretData.correctShell, win_amount, gold: userGold, characterId: sessionRow.character_id }
    })

    // Update daily + weekly + tutorial quest progress (outside transaction, non-critical)
    await Promise.all([
      updateDailyQuestProgress(prisma, result.characterId, 'shell_game_play'),
      // W3.D5 — Weekly BP challenge: Lucky Hand slot
      updateWeeklyChallengeProgress(prisma, result.characterId, 'shell_game_play'),
    ])
    updateTutorialQuestProgress(prisma, result.characterId, 'try_tavern').catch(() => {})

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
