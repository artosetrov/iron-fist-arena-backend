import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { buildSlotsArray, BOOST_COST_GEMS } from '@/lib/game/gold-mine'
import { rateLimit } from '@/lib/rate-limit'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`gold-mine-boost:${user.id}`, 5, 10_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

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
      return NextResponse.json({ error: 'No active mining session for this slot' }, { status: 404 })
    }

    if (session.boosted) {
      return NextResponse.json({ error: 'Session is already boosted' }, { status: 400 })
    }

    const userRecord = await prisma.user.findUnique({ where: { id: user.id } })
    if (!userRecord || userRecord.gems < BOOST_COST_GEMS) {
      return NextResponse.json(
        { error: 'Not enough gems', required: BOOST_COST_GEMS, current: userRecord?.gems ?? 0 },
        { status: 400 }
      )
    }

    const boostedReward = session.reward * 2
    const boostedGemReward = session.gemReward * 2

    await prisma.$transaction([
      prisma.user.update({
        where: { id: user.id },
        data: { gems: { decrement: BOOST_COST_GEMS } },
      }),
      prisma.goldMineSession.update({
        where: { id: session.id },
        data: { boosted: true, reward: boostedReward, gemReward: boostedGemReward },
      }),
    ])

    const slots = await buildSlotsArray(prisma, character_id, character.goldMineSlots)

    return NextResponse.json({
      slots,
      gems: userRecord.gems - BOOST_COST_GEMS,
    })
  } catch (error) {
    console.error('gold-mine boost error:', error)
    return NextResponse.json({ error: 'Failed to boost gold mine session' }, { status: 500 })
  }
}
