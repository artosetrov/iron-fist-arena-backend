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

    // Use interactive transaction with row-level lock to prevent TOCTOU
    const result = await prisma.$transaction(async (tx) => {
      // Lock the user row for update (gems balance)
      const [userRow] = await tx.$queryRawUnsafe<Array<{ id: string; gems: number }>>(
        `SELECT id, gems FROM users WHERE id = $1 FOR UPDATE`,
        user.id
      )

      if (!userRow) throw new Error('USER_NOT_FOUND')
      if (userRow.gems < BOOST_COST_GEMS) throw new Error('NOT_ENOUGH_GEMS')

      // Verify character ownership
      const character = await tx.character.findUnique({
        where: { id: character_id },
      })

      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Lock the session row for update to prevent double-boost
      const [sessionRow] = await tx.$queryRawUnsafe<Array<{ id: string; boosted: boolean; reward: number; gem_reward: number }>>(
        `SELECT id, boosted, reward, gem_reward FROM gold_mine_sessions WHERE character_id = $1 AND slot_index = $2 AND collected = false FOR UPDATE`,
        character_id,
        slot_index
      )

      if (!sessionRow) throw new Error('NO_SESSION')
      if (sessionRow.boosted) throw new Error('ALREADY_BOOSTED')

      const boostedReward = sessionRow.reward * 2
      const boostedGemReward = sessionRow.gem_reward * 2

      const updatedUser = await tx.user.update({
        where: { id: user.id },
        data: { gems: { decrement: BOOST_COST_GEMS } },
      })

      await tx.goldMineSession.update({
        where: { id: sessionRow.id },
        data: { boosted: true, reward: boostedReward, gemReward: boostedGemReward },
      })

      return { updatedUser, goldMineSlots: character.goldMineSlots }
    })

    const slots = await buildSlotsArray(prisma, character_id, result.goldMineSlots)

    return NextResponse.json({
      slots,
      gems: result.updatedUser.gems,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'USER_NOT_FOUND') return NextResponse.json({ error: 'User not found' }, { status: 404 })
      if (error.message === 'NOT_ENOUGH_GEMS') return NextResponse.json({ error: 'Not enough gems' }, { status: 400 })
      if (error.message === 'NO_SESSION') return NextResponse.json({ error: 'No active mining session for this slot' }, { status: 404 })
      if (error.message === 'ALREADY_BOOSTED') return NextResponse.json({ error: 'Session is already boosted' }, { status: 400 })
    }
    console.error('gold-mine boost error:', error)
    return NextResponse.json({ error: 'Failed to boost gold mine session' }, { status: 500 })
  }
}
