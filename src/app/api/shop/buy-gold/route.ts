import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

const GEMS_TO_GOLD_RATE = 10 // 1 gem = 10 gold

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

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

    const goldToAdd = gems_amount * GEMS_TO_GOLD_RATE

    // Use interactive transaction with row-level lock to prevent TOCTOU
    const result = await prisma.$transaction(async (tx) => {
      // Lock the user row for update (gems balance)
      const [userRow] = await tx.$queryRawUnsafe<Array<{ id: string; gems: number }>>(
        `SELECT id, gems FROM users WHERE id = $1 FOR UPDATE`,
        user.id
      )

      if (!userRow) throw new Error('USER_NOT_FOUND')
      if (userRow.gems < gems_amount) throw new Error('NOT_ENOUGH_GEMS')

      // Verify character ownership
      const character = await tx.character.findUnique({
        where: { id: character_id },
      })

      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      const updatedUser = await tx.user.update({
        where: { id: user.id },
        data: { gems: { decrement: gems_amount } },
      })

      const updatedCharacter = await tx.character.update({
        where: { id: character_id },
        data: { gold: { increment: goldToAdd } },
      })

      return { updatedUser, updatedCharacter }
    })

    return NextResponse.json({
      character: {
        gold: result.updatedCharacter.gold,
        gems: result.updatedUser.gems,
      },
      gemsSpent: gems_amount,
      goldReceived: goldToAdd,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'USER_NOT_FOUND') return NextResponse.json({ error: 'User not found' }, { status: 404 })
      if (error.message === 'NOT_ENOUGH_GEMS') return NextResponse.json({ error: 'Not enough gems' }, { status: 400 })
    }
    console.error('buy gold error:', error)
    return NextResponse.json(
      { error: 'Failed to buy gold' },
      { status: 500 }
    )
  }
}
