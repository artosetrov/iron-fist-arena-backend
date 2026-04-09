import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`sell:${user.id}`, 20, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, inventory_id } = body

    if (!character_id || !inventory_id) {
      return NextResponse.json(
        { error: 'character_id and inventory_id are required' },
        { status: 400 }
      )
    }

    // All verification and sell inside a single transaction with row-level lock
    // to prevent race condition (sell + equip in parallel)
    const result = await prisma.$transaction(async (tx) => {
      // Lock the inventory item to prevent concurrent sell/equip race
      const [invRow] = await tx.$queryRawUnsafe<Array<{
        id: string;
        character_id: string;
        is_equipped: boolean;
        upgrade_level: number;
        item_id: string;
      }>>(
        `SELECT ei.id, ei.character_id, ei.is_equipped, ei.upgrade_level, ei.item_id
         FROM equipment_inventory ei
         WHERE ei.id = $1
         FOR UPDATE`,
        inventory_id
      )

      if (!invRow) throw new Error('INVENTORY_NOT_FOUND')
      if (invRow.character_id !== character_id) throw new Error('ITEM_NOT_OWNED')
      if (invRow.is_equipped) throw new Error('ITEM_EQUIPPED')

      // Verify character ownership
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true },
      })

      if (!character) throw new Error('CHARACTER_NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Fetch item for sell price
      const item = await tx.item.findUnique({
        where: { id: invRow.item_id },
        select: { sellPrice: true },
      })

      if (!item) throw new Error('ITEM_NOT_FOUND')

      // Scale sell price by upgrade level: +10 = 2x, +5 = 1.5x, +0 = 1x
      const finalSellPrice = Math.floor(item.sellPrice * (1 + invRow.upgrade_level * 0.1))

      // Delete the inventory entry
      await tx.equipmentInventory.delete({
        where: { id: inventory_id },
      })

      // Add gold to user
      const updatedUser = await tx.user.update({
        where: { id: user.id },
        data: { gold: { increment: finalSellPrice } },
      })

      return { gold: updatedUser.gold, soldFor: finalSellPrice }
    })

    return NextResponse.json(result)
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'INVENTORY_NOT_FOUND') return NextResponse.json({ error: 'Inventory item not found' }, { status: 404 })
      if (error.message === 'ITEM_NOT_OWNED') return NextResponse.json({ error: 'Item does not belong to this character' }, { status: 403 })
      if (error.message === 'ITEM_EQUIPPED') return NextResponse.json({ error: 'Cannot sell an equipped item. Unequip it first.' }, { status: 400 })
      if (error.message === 'CHARACTER_NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'ITEM_NOT_FOUND') return NextResponse.json({ error: 'Item data not found' }, { status: 404 })
    }
    console.error('sell item error:', error)
    return NextResponse.json(
      { error: 'Failed to sell item' },
      { status: 500 }
    )
  }
}
