import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ConsumableType } from '@prisma/client'

const POTION_PRICES: Record<string, number> = {
  stamina_potion_small: 100,
  stamina_potion_medium: 250,
  stamina_potion_large: 500,
}

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, potion_type } = body

    if (!character_id || !potion_type) {
      return NextResponse.json(
        { error: 'character_id and potion_type are required' },
        { status: 400 }
      )
    }

    // Validate potion type
    const price = POTION_PRICES[potion_type]
    if (price === undefined) {
      return NextResponse.json(
        { error: `Invalid potion_type. Must be one of: ${Object.keys(POTION_PRICES).join(', ')}` },
        { status: 400 }
      )
    }

    // Use interactive transaction with row-level lock to prevent TOCTOU
    const result = await prisma.$transaction(async (tx) => {
      // Lock the user row for update (gold balance)
      const [userRow] = await tx.$queryRawUnsafe<Array<{ id: string; gold: number }>>(
        `SELECT id, gold FROM users WHERE id = $1 FOR UPDATE`,
        user.id
      )

      if (!userRow) throw new Error('USER_NOT_FOUND')
      if (userRow.gold < price) throw new Error('NOT_ENOUGH_GOLD')

      // Verify character ownership
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true },
      })

      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      const updatedUser = await tx.user.update({
        where: { id: user.id },
        data: { gold: { decrement: price } },
        select: { gold: true, gems: true },
      })

      const consumable = await tx.consumableInventory.upsert({
        where: {
          characterId_consumableType: {
            characterId: character_id,
            consumableType: potion_type as ConsumableType,
          },
        },
        create: {
          characterId: character_id,
          consumableType: potion_type as ConsumableType,
          quantity: 1,
        },
        update: {
          quantity: { increment: 1 },
        },
      })

      return { updatedUser, consumable }
    })

    return NextResponse.json({
      consumable: result.consumable,
      character: {
        gold: result.updatedUser.gold,
        gems: result.updatedUser.gems,
      },
      cost: price,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'NOT_ENOUGH_GOLD') return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
    }
    console.error('buy potion error:', error)
    return NextResponse.json(
      { error: 'Failed to buy potion' },
      { status: 500 }
    )
  }
}
