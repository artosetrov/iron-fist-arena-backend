import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { EquippedSlot, ItemType } from '@prisma/client'
import { recalculateDerivedStats } from '@/lib/game/equipment-stats'

// Map item types to the equipment slot they occupy (consumable items are not equippable)
const ITEM_TYPE_TO_SLOT: Partial<Record<ItemType, EquippedSlot>> = {
  weapon: 'weapon',
  helmet: 'helmet',
  chest: 'chest',
  gloves: 'gloves',
  legs: 'legs',
  boots: 'boots',
  accessory: 'accessory',
  amulet: 'amulet',
  belt: 'belt',
  relic: 'relic',
  necklace: 'necklace',
  ring: 'ring',
}

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

    // Get the inventory item with its item details
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

    // Determine the slot from the item type
    const slot = ITEM_TYPE_TO_SLOT[inventoryItem.item.itemType]

    if (!slot) {
      return NextResponse.json({ error: 'Item cannot be equipped' }, { status: 400 })
    }

    // Unequip any item currently in that slot, then equip the new one
    await prisma.$transaction([
      // Unequip current item in that slot
      prisma.equipmentInventory.updateMany({
        where: {
          characterId: character_id,
          equippedSlot: slot,
          isEquipped: true,
        },
        data: {
          isEquipped: false,
          equippedSlot: null,
        },
      }),
      // Equip the new item
      prisma.equipmentInventory.update({
        where: { id: inventory_id },
        data: {
          isEquipped: true,
          equippedSlot: slot,
        },
      }),
    ])

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
    console.error('equip item error:', error)
    return NextResponse.json(
      { error: 'Failed to equip item' },
      { status: 500 }
    )
  }
}
