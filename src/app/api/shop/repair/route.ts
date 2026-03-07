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

    if (inventoryItem.durability >= inventoryItem.maxDurability) {
      return NextResponse.json({ error: 'Item is already at full durability' }, { status: 400 })
    }

    // Calculate repair cost: (maxDurability - durability) * 2 gold
    const repairCost = (inventoryItem.maxDurability - inventoryItem.durability) * 2

    if (character.gold < repairCost) {
      return NextResponse.json(
        { error: 'Not enough gold', required: repairCost, current: character.gold },
        { status: 400 }
      )
    }

    // Deduct gold and restore durability in a transaction
    const [updatedCharacter, updatedItem] = await prisma.$transaction([
      prisma.character.update({
        where: { id: character_id },
        data: { gold: { decrement: repairCost } },
      }),
      prisma.equipmentInventory.update({
        where: { id: inventory_id },
        data: { durability: inventoryItem.maxDurability },
        include: { item: true },
      }),
    ])

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
    console.error('repair item error:', error)
    return NextResponse.json(
      { error: 'Failed to repair item' },
      { status: 500 }
    )
  }
}
