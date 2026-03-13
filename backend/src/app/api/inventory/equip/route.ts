import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { EquippedSlot, ItemType } from '@prisma/client'
import { recalculateDerivedStats } from '@/lib/game/equipment-stats'
import { invalidateSkillCache, invalidatePassiveCache } from '@/lib/game/combat-loader'
import { rateLimit } from '@/lib/rate-limit'

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

  if (!(await rateLimit(`equip:${user.id}`, 20, 60_000))) {
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

    // Verify character ownership
    const character = await prisma.character.findUnique({
      where: { id: character_id },
      select: { userId: true, level: true, class: true },
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

    // Bug 4: Prevent equipping broken items
    if (inventoryItem.durability === 0) {
      return NextResponse.json(
        { error: 'Cannot equip a broken item. Repair it first.' },
        { status: 400 }
      )
    }

    // Bug 3: Check character level meets item level requirement
    if (character.level < inventoryItem.item.itemLevel) {
      return NextResponse.json(
        { error: 'Character level too low for this item' },
        { status: 400 }
      )
    }

    const classRestriction = inventoryItem.item.classRestriction?.toLowerCase()
    if (classRestriction && classRestriction !== character.class) {
      return NextResponse.json(
        { error: `This item can only be equipped by ${inventoryItem.item.classRestriction}` },
        { status: 400 }
      )
    }

    // Determine the slot from the item type
    let slot = ITEM_TYPE_TO_SLOT[inventoryItem.item.itemType]

    if (!slot) {
      return NextResponse.json({ error: 'Item cannot be equipped' }, { status: 400 })
    }

    // Rings support two slots: ring and ring2
    if (slot === 'ring') {
      const equippedRings = await prisma.equipmentInventory.findMany({
        where: {
          characterId: character_id,
          equippedSlot: { in: ['ring', 'ring2'] },
          isEquipped: true,
        },
      })

      const ring1 = equippedRings.find(r => r.equippedSlot === 'ring')
      const ring2 = equippedRings.find(r => r.equippedSlot === 'ring2')

      // If re-equipping the same item, keep its current slot
      const alreadyEquipped = equippedRings.find(r => r.id === inventory_id)
      if (alreadyEquipped) {
        return NextResponse.json({ message: 'Item is already equipped' })
      }

      if (!ring1) {
        slot = 'ring'
      } else if (!ring2) {
        slot = 'ring2'
      } else {
        // Both slots full — replace ring1 (oldest)
        slot = 'ring'
      }
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
          equippedSlot: slot as EquippedSlot,
        },
      }),
    ])

    // Recalculate derived stats (maxHp, armor, magicResist)
    await recalculateDerivedStats(character_id)

    // Invalidate combat caches so PvP uses fresh equipment data
    await invalidateSkillCache(character_id)
    await invalidatePassiveCache(character_id)

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
