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
      // Lock the character row for update
      const [charRow] = await tx.$queryRawUnsafe<Array<{ id: string; user_id: string; gold: number }>>(
        `SELECT id, user_id, gold FROM characters WHERE id = $1 FOR UPDATE`,
        character_id
      )

      if (!charRow) throw new Error('NOT_FOUND')
      if (charRow.user_id !== user.id) throw new Error('FORBIDDEN')
      if (charRow.gold < price) throw new Error('NOT_ENOUGH_GOLD')

      const updatedCharacter = await tx.character.update({
        where: { id: character_id },
        data: { gold: { decrement: price } },
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

      return { updatedCharacter, consumable }
    })

    // gems live on User, not Character
    const dbUser = await prisma.user.findUnique({ where: { id: user.id }, select: { gems: true } })

    return NextResponse.json({
      consumable: result.consumable,
      character: {
        gold: result.updatedCharacter.gold,
        gems: dbUser?.gems ?? 0,
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
