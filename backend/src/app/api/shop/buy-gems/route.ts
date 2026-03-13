import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'

// 1 gem costs 15 gold (worse rate than gems→gold which is 1:10, to maintain economy)
const GOLD_PER_GEM = 15

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`shop-buy-gems:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, gems_amount } = body

    if (!character_id || !gems_amount) {
      return NextResponse.json(
        { error: 'character_id and gems_amount are required' },
        { status: 400 }
      )
    }

    if (typeof gems_amount !== 'number' || gems_amount < 1 || !Number.isInteger(gems_amount)) {
      return NextResponse.json(
        { error: 'gems_amount must be a positive integer' },
        { status: 400 }
      )
    }

    const goldCost = gems_amount * GOLD_PER_GEM

    const result = await prisma.$transaction(async (tx) => {
      // Lock character row for update
      const [charRow] = await tx.$queryRawUnsafe<Array<{ id: string; gold: number; userId: string }>>(
        `SELECT id, gold, user_id AS "userId" FROM characters WHERE id = $1 FOR UPDATE`,
        character_id
      )

      if (!charRow) throw new Error('NOT_FOUND')
      if (charRow.userId !== user.id) throw new Error('FORBIDDEN')
      if (charRow.gold < goldCost) throw new Error('NOT_ENOUGH_GOLD')

      const updatedCharacter = await tx.character.update({
        where: { id: character_id },
        data: { gold: { decrement: goldCost } },
      })

      const updatedUser = await tx.user.update({
        where: { id: user.id },
        data: { gems: { increment: gems_amount } },
      })

      return { updatedCharacter, updatedUser }
    })

    return NextResponse.json({
      character: {
        gold: result.updatedCharacter.gold,
        gems: result.updatedUser.gems,
      },
      goldSpent: goldCost,
      gemsReceived: gems_amount,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'NOT_ENOUGH_GOLD') return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
    }
    console.error('buy gems error:', error)
    return NextResponse.json(
      { error: 'Failed to buy gems' },
      { status: 500 }
    )
  }
}
