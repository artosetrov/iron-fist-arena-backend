import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { buildSlotsArray, MAX_GOLD_MINE_SLOTS, SLOT_COST_GEMS } from '@/lib/game/gold-mine'
import { rateLimit } from '@/lib/rate-limit'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`gold-mine-buy-slot:${user.id}`, 5, 10_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
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

    if (character.goldMineSlots >= MAX_GOLD_MINE_SLOTS) {
      return NextResponse.json(
        { error: `Maximum gold mine slots (${MAX_GOLD_MINE_SLOTS}) already reached` },
        { status: 400 }
      )
    }

    const userRecord = await prisma.user.findUnique({ where: { id: user.id } })
    if (!userRecord || userRecord.gems < SLOT_COST_GEMS) {
      return NextResponse.json(
        { error: 'Not enough gems', required: SLOT_COST_GEMS, current: userRecord?.gems ?? 0 },
        { status: 400 }
      )
    }

    const [, updatedCharacter] = await prisma.$transaction([
      prisma.user.update({
        where: { id: user.id },
        data: { gems: { decrement: SLOT_COST_GEMS } },
      }),
      prisma.character.update({
        where: { id: character_id },
        data: { goldMineSlots: { increment: 1 } },
      }),
    ])

    const slots = await buildSlotsArray(prisma, character_id, updatedCharacter.goldMineSlots)

    return NextResponse.json({
      slots,
      max_slots: updatedCharacter.goldMineSlots,
      gems: userRecord.gems - SLOT_COST_GEMS,
    })
  } catch (error) {
    console.error('gold-mine buy-slot error:', error)
    return NextResponse.json({ error: 'Failed to buy gold mine slot' }, { status: 500 })
  }
}
