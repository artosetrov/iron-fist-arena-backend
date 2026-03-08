import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, inventory_id } = body

    if (!character_id || !inventory_id) {
      return NextResponse.json(
        { error: 'character_id and inventory_id are required' },
        { status: 400 }
      )
    }

    // Use interactive transaction with row-level lock to prevent TOCTOU
    const { updatedCharacter, updatedItem, repairCost } = await prisma.$transaction(async (tx) => {
      // Lock the character row for update
      const [charRow] = await tx.$queryRawUnsafe<Array<{ id: string; user_id: string; gold: number }>>(
        `SELECT id, user_id, gold FROM characters WHERE id = $1 FOR UPDATE`,
        character_id
      )

      if (!charRow) throw new Error('NOT_FOUND')
      if (charRow.user_id !== user.id) throw new Error('FORBIDDEN')

      // Get the inventory item
      const inventoryItem = await tx.equipmentInventory.findUnique({
        where: { id: inventory_id },
      })

      if (!inventoryItem) throw new Error('ITEM_NOT_FOUND')
      if (inventoryItem.characterId !== character_id) throw new Error('ITEM_FORBIDDEN')
      if (inventoryItem.durability >= inventoryItem.maxDurability) throw new Error('FULL_DURABILITY')

      // Calculate repair cost: (maxDurability - durability) * 2 gold
      const cost = (inventoryItem.maxDurability - inventoryItem.durability) * 2

      if (charRow.gold < cost) throw new Error('NOT_ENOUGH_GOLD')

      const updatedCharacter = await tx.character.update({
        where: { id: character_id },
        data: { gold: { decrement: cost } },
      })

      const updatedItem = await tx.equipmentInventory.update({
        where: { id: inventory_id },
        data: { durability: inventoryItem.maxDurability },
        include: { item: true },
      })

      return { updatedCharacter, updatedItem, repairCost: cost }
    })

    // gems live on User, not Character
    const dbUser = await prisma.user.findUnique({ where: { id: user.id }, select: { gems: true } })

    return NextResponse.json({
      inventoryItem: updatedItem,
      character: {
        gold: updatedCharacter.gold,
        gems: dbUser?.gems ?? 0,
      },
      repairCost,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'ITEM_NOT_FOUND') return NextResponse.json({ error: 'Inventory item not found' }, { status: 404 })
      if (error.message === 'ITEM_FORBIDDEN') return NextResponse.json({ error: 'Item does not belong to this character' }, { status: 403 })
      if (error.message === 'FULL_DURABILITY') return NextResponse.json({ error: 'Item is already at full durability' }, { status: 400 })
      if (error.message === 'NOT_ENOUGH_GOLD') return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
    }
    console.error('repair item error:', error)
    return NextResponse.json(
      { error: 'Failed to repair item' },
      { status: 500 }
    )
  }
}
