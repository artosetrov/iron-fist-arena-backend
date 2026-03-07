import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'

const BOOST_COST_GEMS = 10

/**
 * POST /api/minigames/gold-mine/boost
 * Body: { character_id, session_id }
 * Boosts a gold mine session: doubles the reward for BOOST_COST_GEMS gems.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`gold-mine-boost:${user.id}`, 5, 10_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, session_id } = body

    if (!character_id || !session_id) {
      return NextResponse.json(
        { error: 'character_id and session_id are required' },
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

    const session = await prisma.goldMineSession.findFirst({
      where: { id: session_id, characterId: character_id, collected: false },
    })

    if (!session) {
      return NextResponse.json({ error: 'Active mining session not found' }, { status: 404 })
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

    await prisma.$transaction([
      prisma.user.update({
        where: { id: user.id },
        data: { gems: { decrement: BOOST_COST_GEMS } },
      }),
      prisma.goldMineSession.update({
        where: { id: session_id },
        data: { boosted: true, reward: boostedReward },
      }),
    ])

    return NextResponse.json({
      session_id,
      boosted: true,
      reward: boostedReward,
      gems_spent: BOOST_COST_GEMS,
      gems_remaining: userRecord.gems - BOOST_COST_GEMS,
    })
  } catch (error) {
    console.error('gold-mine boost error:', error)
    return NextResponse.json({ error: 'Failed to boost gold mine session' }, { status: 500 })
  }
}
