import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { getInventoryConfig } from '@/lib/game/live-config'
import { rateLimit } from '@/lib/rate-limit'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`inventory-expand:${user.id}`, 5, 10_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const INVENTORY = await getInventoryConfig()
    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const maxSlots = INVENTORY.BASE_SLOTS + INVENTORY.MAX_EXPANSIONS * INVENTORY.EXPAND_AMOUNT

    const result = await prisma.$transaction(async (tx) => {
      const [charRow] = await tx.$queryRawUnsafe<
        Array<{ id: string; user_id: string; inventory_slots: number; gold: number }>
      >(
        `SELECT id, user_id, inventory_slots, gold FROM characters WHERE id = $1 FOR UPDATE`,
        character_id
      )

      if (!charRow) throw new Error('NOT_FOUND')
      if (charRow.user_id !== user.id) throw new Error('FORBIDDEN')
      if (charRow.gold < INVENTORY.EXPAND_COST_GOLD) throw new Error('NOT_ENOUGH_GOLD')
      if (charRow.inventory_slots >= maxSlots) throw new Error('MAX_SLOTS')

      const updated = await tx.character.update({
        where: { id: character_id },
        data: {
          gold: { decrement: INVENTORY.EXPAND_COST_GOLD },
          inventorySlots: { increment: INVENTORY.EXPAND_AMOUNT },
        },
      })

      return updated
    })

    return NextResponse.json({
      inventorySlots: result.inventorySlots,
      gold: result.gold,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'NOT_ENOUGH_GOLD') return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
      if (error.message === 'MAX_SLOTS') return NextResponse.json({ error: 'Maximum inventory slots reached' }, { status: 400 })
    }
    console.error('inventory expand error:', error)
    return NextResponse.json({ error: 'Failed to expand inventory' }, { status: 500 })
  }
}
