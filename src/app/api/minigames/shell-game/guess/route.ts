import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { session_id, guess } = body

    if (!session_id || guess == null) {
      return NextResponse.json(
        { error: 'session_id and guess are required' },
        { status: 400 }
      )
    }

    if (![0, 1, 2].includes(guess)) {
      return NextResponse.json(
        { error: 'guess must be 0, 1, or 2' },
        { status: 400 }
      )
    }

    const session = await prisma.minigameSession.findUnique({
      where: { id: session_id },
      include: { character: true },
    })

    if (!session) {
      return NextResponse.json({ error: 'Session not found' }, { status: 404 })
    }

    if (session.character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    if (session.status !== 'active') {
      return NextResponse.json(
        { error: 'Session is no longer active' },
        { status: 400 }
      )
    }

    const secretData = session.secretData as { correctShell: number }
    const won = guess === secretData.correctShell
    const reward = won ? session.betAmount * 2 : 0

    // Update session status
    await prisma.minigameSession.update({
      where: { id: session_id },
      data: {
        status: 'completed',
        result: { won, guess, correctShell: secretData.correctShell, reward },
      },
    })

    // Award gold if won
    if (won) {
      await prisma.character.update({
        where: { id: session.characterId },
        data: { gold: { increment: reward } },
      })
    }

    return NextResponse.json({
      won,
      guess,
      correctShell: secretData.correctShell,
      reward,
    })
  } catch (error) {
    console.error('shell-game guess error:', error)
    return NextResponse.json(
      { error: 'Failed to process guess' },
      { status: 500 }
    )
  }
}
