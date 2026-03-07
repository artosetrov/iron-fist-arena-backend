import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import {
  buildSlotsArray,
  MINE_DURATION_HOURS,
  MINE_REWARD_MIN,
  MINE_REWARD_MAX,
} from '@/lib/game/gold-mine'

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

    if (slot_index < 0 || slot_index >= character.goldMineSlots) {
      return NextResponse.json(
        { error: `Invalid slot index. You have ${character.goldMineSlots} slot(s) available (0-${character.goldMineSlots - 1})` },
        { status: 400 }
      )
    }

    // Check no active (uncollected) session for this slot
    const existingSession = await prisma.goldMineSession.findFirst({
      where: {
        characterId: character_id,
        slotIndex: slot_index,
        collected: false,
      },
    })

    if (existingSession) {
      return NextResponse.json(
        { error: 'Slot already has an active mining session' },
        { status: 400 }
      )
    }

    const now = new Date()
    const endsAt = new Date(now.getTime() + MINE_DURATION_HOURS * 60 * 60 * 1000)
    const reward = Math.floor(
      Math.random() * (MINE_REWARD_MAX - MINE_REWARD_MIN + 1) + MINE_REWARD_MIN
    )

    await prisma.goldMineSession.create({
      data: {
        characterId: character_id,
        slotIndex: slot_index,
        startedAt: now,
        endsAt,
        reward,
      },
    })

    const slots = await buildSlotsArray(prisma, character_id, character.goldMineSlots)

    return NextResponse.json({ slots })
  } catch (error) {
    console.error('gold-mine start error:', error)
    return NextResponse.json(
      { error: 'Failed to start gold mine session' },
      { status: 500 }
    )
  }
}
