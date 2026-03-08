import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { buildSlotsArray } from '@/lib/game/gold-mine'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, slot_index } = body

    if (!character_id || slot_index == null) {
      return NextResponse.json(
        { error: 'character_id and slot_index are required' },
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

    // Find the active session for this slot
    const session = await prisma.goldMineSession.findFirst({
      where: {
        characterId: character_id,
        slotIndex: slot_index,
        collected: false,
      },
    })

    if (!session) {
      return NextResponse.json({ error: 'No active session for this slot' }, { status: 404 })
    }

    const now = new Date()
    if (now < session.endsAt) {
      return NextResponse.json(
        { error: 'Mining session not yet complete', endsAt: session.endsAt },
        { status: 400 }
      )
    }

    // Collect reward: mark collected, add gold to character, gems to user
    const txOps = [
      prisma.goldMineSession.update({
        where: { id: session.id },
        data: { collected: true },
      }),
      prisma.character.update({
        where: { id: character_id },
        data: { gold: { increment: session.reward } },
      }),
    ]

    if (session.gemReward > 0) {
      txOps.push(
        prisma.user.update({
          where: { id: user.id },
          data: { gems: { increment: session.gemReward } },
        }) as any
      )
    }

    const results = await prisma.$transaction(txOps)
    const updatedCharacter = results[1] as any

    // Get current user gems
    const updatedUser = session.gemReward > 0
      ? results[2] as any
      : await prisma.user.findUnique({ where: { id: user.id }, select: { gems: true } })

    // Update daily quest progress
    await updateDailyQuestProgress(prisma, character_id, 'gold_mine_collect')

    const slots = await buildSlotsArray(prisma, character_id, character.goldMineSlots)

    return NextResponse.json({
      slots,
      gold_collected: session.reward,
      gems_collected: session.gemReward,
      gold: updatedCharacter.gold,
      gems: updatedUser?.gems ?? 0,
    })
  } catch (error) {
    console.error('gold-mine collect error:', error)
    return NextResponse.json(
      { error: 'Failed to collect gold mine reward' },
      { status: 500 }
    )
  }
}
