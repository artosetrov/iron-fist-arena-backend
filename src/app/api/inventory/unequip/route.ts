import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { recalculateDerivedStats } from '@/lib/game/equipment-stats'

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
      select: { userId: true },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Get the inventory item
    const inventoryItem = await prisma.equipmentInventory.findUnique({
      where: { id: inventory_id },
    })

    if (!inventoryItem) {
      return NextResponse.json({ error: 'Inventory item not found' }, { status: 404 })
    }

    if (inventoryItem.characterId !== character_id) {
      return NextResponse.json({ error: 'Item does not belong to this character' }, { status: 403 })
    }

    if (!inventoryItem.isEquipped) {
      return NextResponse.json({ error: 'Item is not equipped' }, { status: 400 })
    }

    // Unequip the item
    await prisma.equipmentInventory.update({
      where: { id: inventory_id },
      data: {
        isEquipped: false,
        equippedSlot: null,
      },
    })

    // Recalculate derived stats (maxHp, armor, magicResist)
    await recalculateDerivedStats(character_id)

    // Return updated inventory
    const equipment = await prisma.equipmentInventory.findMany({
      where: { characterId: character_id },
      include: { item: true },
      orderBy: { acquiredAt: 'desc' },
    })

    return NextResponse.json({ equipment })
  } catch (error) {
    console.error('unequip item error:', error)
    return NextResponse.json(
      { error: 'Failed to unequip item' },
      { status: 500 }
    )
  }
}
