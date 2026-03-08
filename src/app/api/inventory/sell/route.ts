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

    // Get the inventory item with item details for sell price
    const inventoryItem = await prisma.equipmentInventory.findUnique({
      where: { id: inventory_id },
      include: { item: true },
    })

    if (!inventoryItem) {
      return NextResponse.json({ error: 'Inventory item not found' }, { status: 404 })
    }

    if (inventoryItem.characterId !== character_id) {
      return NextResponse.json({ error: 'Item does not belong to this character' }, { status: 403 })
    }

    if (inventoryItem.isEquipped) {
      return NextResponse.json(
        { error: 'Cannot sell an equipped item. Unequip it first.' },
        { status: 400 }
      )
    }

    // Scale sell price by upgrade level: +10 = 2x, +5 = 1.5x, +0 = 1x
    const baseSellPrice = inventoryItem.item.sellPrice
    const finalSellPrice = Math.floor(baseSellPrice * (1 + inventoryItem.upgradeLevel * 0.1))

    // Delete the inventory entry and add gold in a transaction
    const updatedCharacter = await prisma.$transaction(async (tx) => {
      await tx.equipmentInventory.delete({
        where: { id: inventory_id },
      })

      return tx.character.update({
        where: { id: character_id },
        data: { gold: { increment: finalSellPrice } },
      })
    })

    return NextResponse.json({ gold: updatedCharacter.gold, soldFor: finalSellPrice })
  } catch (error) {
    console.error('sell item error:', error)
    return NextResponse.json(
      { error: 'Failed to sell item' },
      { status: 500 }
    )
  }
}
