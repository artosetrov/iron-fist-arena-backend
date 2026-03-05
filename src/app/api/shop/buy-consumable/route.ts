import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ConsumableType } from '@prisma/client'

const CONSUMABLE_PRICES: Record<ConsumableType, number> = {
  stamina_potion_small: 100,
  stamina_potion_medium: 250,
  stamina_potion_large: 500,
}

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, consumable_type, quantity = 1 } = body

    if (!character_id || !consumable_type) {
      return NextResponse.json(
        { error: 'character_id and consumable_type are required' },
        { status: 400 }
      )
    }

    // Validate consumable type
    if (!Object.values(ConsumableType).includes(consumable_type as ConsumableType)) {
      return NextResponse.json(
        { error: `Invalid consumable_type. Must be one of: ${Object.values(ConsumableType).join(', ')}` },
        { status: 400 }
      )
    }

    if (typeof quantity !== 'number' || quantity < 1 || !Number.isInteger(quantity)) {
      return NextResponse.json(
        { error: 'quantity must be a positive integer' },
        { status: 400 }
      )
    }

    const unitPrice = CONSUMABLE_PRICES[consumable_type as ConsumableType]
    const totalCost = unitPrice * quantity

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
    if (character.gold < totalCost) {
      return NextResponse.json(
        { error: 'Not enough gold', required: totalCost, current: character.gold },
        { status: 400 }
      )
    }

    // Deduct gold and upsert consumable in a transaction
    const [updatedCharacter, consumable] = await prisma.$transaction([
      prisma.character.update({
        where: { id: character_id },
        data: { gold: { decrement: totalCost } },
      }),
      prisma.consumableInventory.upsert({
        where: {
          characterId_consumableType: {
            characterId: character_id,
            consumableType: consumable_type as ConsumableType,
          },
        },
        create: {
          characterId: character_id,
          consumableType: consumable_type as ConsumableType,
          quantity,
        },
        update: {
          quantity: { increment: quantity },
        },
      }),
    ])

    return NextResponse.json({
      consumable,
      gold: updatedCharacter.gold,
      cost: totalCost,
    })
  } catch (error) {
    console.error('buy consumable error:', error)
    return NextResponse.json(
      { error: 'Failed to buy consumable' },
      { status: 500 }
    )
  }
}
