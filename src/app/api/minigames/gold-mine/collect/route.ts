import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { session_id } = body

    if (!session_id) {
      return NextResponse.json(
        { error: 'session_id is required' },
        { status: 400 }
      )
    }

    const session = await prisma.goldMineSession.findUnique({
      where: { id: session_id },
      include: { character: true },
    })

    if (!session) {
      return NextResponse.json({ error: 'Session not found' }, { status: 404 })
    }

    if (session.character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    if (session.collected) {
      return NextResponse.json(
        { error: 'Reward already collected' },
        { status: 400 }
      )
    }

    const now = new Date()
    if (now < session.endsAt) {
      return NextResponse.json(
        { error: 'Mining session not yet complete', endsAt: session.endsAt },
        { status: 400 }
      )
    }

    // Collect reward: mark collected and add gold
    await prisma.$transaction([
      prisma.goldMineSession.update({
        where: { id: session_id },
        data: { collected: true },
      }),
      prisma.character.update({
        where: { id: session.characterId },
        data: { gold: { increment: session.reward } },
      }),
    ])

    // Update daily quest progress
    await updateDailyQuestProgress(prisma, session.characterId, 'gold_mine_collect')

    return NextResponse.json({
      reward: session.reward,
      collected: true,
    })
  } catch (error) {
    console.error('gold-mine collect error:', error)
    return NextResponse.json(
      { error: 'Failed to collect gold mine reward' },
      { status: 500 }
    )
  }
}
