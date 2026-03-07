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

    // Verify character ownership
    const character = await prisma.character.findUnique({
      where: { id: character_id },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Check gold
    if (character.gold < price) {
      return NextResponse.json(
        { error: 'Not enough gold', required: price, current: character.gold },
        { status: 400 }
      )
    }

    // Deduct gold and upsert consumable in a transaction
    const [updatedCharacter, consumable] = await prisma.$transaction([
      prisma.character.update({
        where: { id: character_id },
        data: { gold: { decrement: price } },
      }),
      prisma.consumableInventory.upsert({
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
      }),
    ])

    // gems live on User, not Character
    const dbUser = await prisma.user.findUnique({ where: { id: user.id }, select: { gems: true } })

    return NextResponse.json({
      consumable,
      character: {
        gold: updatedCharacter.gold,
        gems: dbUser?.gems ?? 0,
      },
      cost: price,
    })
  } catch (error) {
    console.error('buy potion error:', error)
    return NextResponse.json(
      { error: 'Failed to buy potion' },
      { status: 500 }
    )
  }
}
