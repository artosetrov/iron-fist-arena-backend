import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ConsumableType } from '@prisma/client'
import { rateLimit } from '@/lib/rate-limit'
import { getGameConfig } from '@/lib/game/config'

// Hardcoded fallbacks — overridden by GameConfig consumable.price.* keys
const DEFAULT_CONSUMABLE_PRICES: Record<ConsumableType, number> = {
  stamina_potion_small: 100,
  stamina_potion_medium: 250,
  stamina_potion_large: 500,
  health_potion_small: 150,
  health_potion_medium: 350,
  health_potion_large: 700,
}

async function getConsumablePrice(type: ConsumableType): Promise<number> {
  return getGameConfig<number>(
    `consumable.price.${type}`,
    DEFAULT_CONSUMABLE_PRICES[type],
  )
}

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`shop-buy-consumable:${user.id}`, 15, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

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

    const unitPrice = await getConsumablePrice(consumable_type as ConsumableType)
    const totalCost = unitPrice * quantity

    // Use interactive transaction with row-level lock to prevent TOCTOU
    const result = await prisma.$transaction(async (tx) => {
      // Lock the user row for update (gold balance)
      const [userRow] = await tx.$queryRawUnsafe<Array<{ id: string; gold: number }>>(
        `SELECT id, gold FROM users WHERE id = $1 FOR UPDATE`,
        user.id
      )

      if (!userRow) throw new Error('USER_NOT_FOUND')
      if (userRow.gold < totalCost) throw new Error('NOT_ENOUGH_GOLD')

      // Verify character ownership
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true },
      })

      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      const updatedUser = await tx.user.update({
        where: { id: user.id },
        data: { gold: { decrement: totalCost } },
      })

      const consumable = await tx.consumableInventory.upsert({
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
      })

      return { updatedUser, consumable }
    })

    return NextResponse.json({
      consumable: result.consumable,
      character: {
        gold: result.updatedUser.gold,
        gems: result.updatedUser.gems,
      },
      cost: totalCost,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'NOT_ENOUGH_GOLD') return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
    }
    console.error('buy consumable error:', error)
    return NextResponse.json(
      { error: 'Failed to buy consumable' },
      { status: 500 }
    )
  }
}
