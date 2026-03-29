import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { EquippedSlot, ItemType } from '@prisma/client'
import { recalculateDerivedStats } from '@/lib/game/equipment-stats'
import { invalidateSkillCache, invalidatePassiveCache } from '@/lib/game/combat-loader'
import { rateLimit } from '@/lib/rate-limit'
import { TWO_HANDED_CATALOG_IDS } from '@/lib/game/item-constants'

// Map item types to possible equipment slots (priority order).
// Universal slots: amulet accepts necklace, relic accepts accessory + weapon (off-hand).
// Ring supports dual slots (ring + ring2).
const ITEM_TYPE_TO_SLOTS: Partial<Record<ItemType, EquippedSlot[]>> = {
  weapon:    ['weapon', 'relic'],     // main hand primary, off-hand secondary (dual wield)
  helmet:    ['helmet'],
  chest:     ['chest'],
  gloves:    ['gloves'],
  legs:      ['legs'],
  boots:     ['boots'],
  accessory: ['relic'],               // goes to off-hand (relic) slot
  amulet:    ['amulet'],
  necklace:  ['amulet'],              // shares amulet slot
  belt:      ['belt'],
  relic:     ['relic'],               // off-hand slot
  ring:      ['ring', 'ring2'],       // dual ring slots
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

    // Verify character ownership + fetch inventory item in parallel (saves one DB round-trip)
    const [character, inventoryItem] = await Promise.all([
      prisma.character.findUnique({
        where: { id: character_id },
        select: { userId: true, level: true, class: true },
      }),
      prisma.equipmentInventory.findUnique({
        where: { id: inventory_id },
        include: { item: true },
      }),
    ])

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    if (!inventoryItem) {
      return NextResponse.json({ error: 'Inventory item not found' }, { status: 404 })
    }

    if (inventoryItem.characterId !== character_id) {
      return NextResponse.json({ error: 'Item does not belong to this character' }, { status: 403 })
    }

    // Prevent equipping broken items
    if (inventoryItem.durability === 0) {
      return NextResponse.json(
        { error: 'Cannot equip a broken item. Repair it first.' },
        { status: 400 }
      )
    }

    // Check character level meets item level requirement
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

    // Determine possible slots from item type (universal slot support)
    const possibleSlots = ITEM_TYPE_TO_SLOTS[inventoryItem.item.itemType]

    if (!possibleSlots?.length) {
      return NextResponse.json({ error: 'Item cannot be equipped' }, { status: 400 })
    }

    // If item is already equipped, keep its current slot
    if (inventoryItem.isEquipped && inventoryItem.equippedSlot) {
      return NextResponse.json({ message: 'Item is already equipped' })
    }

    // Batch-load all occupied slots for this character at once (avoids N+1 per candidate slot)
    const occupiedRows = await prisma.equipmentInventory.findMany({
      where: {
        characterId: character_id,
        equippedSlot: { in: possibleSlots as EquippedSlot[] },
        isEquipped: true,
      },
      select: { equippedSlot: true },
    })
    const occupiedSlots = new Set(occupiedRows.map((r) => r.equippedSlot))

    // Find first empty slot, or fall back to priority slot
    let slot: EquippedSlot | null = null
    for (const candidate of possibleSlots) {
      if (!occupiedSlots.has(candidate)) {
        slot = candidate
        break
      }
    }

    // If all possible slots are full, replace the first slot in priority order
    if (!slot) {
      slot = possibleSlots[0]
    }

    // For two-handed weapons: also clear the relic (off-hand) slot
    const isTwoHanded = inventoryItem.item.itemType === 'weapon' &&
      TWO_HANDED_CATALOG_IDS.has(inventoryItem.item.catalogId)

    // Unequip any item currently in that slot, then equip the new one
    const updates: any[] = [
      // Unequip current item in target slot
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
    ]

    // If two-handed: also unequip off-hand (relic) slot
    if (isTwoHanded) {
      updates.unshift(
        prisma.equipmentInventory.updateMany({
          where: {
            characterId: character_id,
            equippedSlot: 'relic',
            isEquipped: true,
          },
          data: {
            isEquipped: false,
            equippedSlot: null,
          },
        })
      )
    }

    await prisma.$transaction(updates)

    // Recalculate derived stats + invalidate caches + fetch updated inventory — all in parallel
    // Previously sequential (3 awaits = ~150-200ms extra); now parallel saves that time.
    const [equipment] = await Promise.all([
      prisma.equipmentInventory.findMany({
        where: { characterId: character_id },
        include: { item: true },
        orderBy: { acquiredAt: 'desc' },
      }),
      recalculateDerivedStats(character_id),
      invalidateSkillCache(character_id),
      invalidatePassiveCache(character_id),
    ])

    // Enrich equipment with isTwoHanded flag (same as GET /api/inventory)
    const enrichedEquipment = equipment.map(eq => ({
      ...eq,
      isTwoHanded: eq.item.itemType === 'weapon' && TWO_HANDED_CATALOG_IDS.has(eq.item.catalogId),
    }))

    return NextResponse.json({ equipment: enrichedEquipment })
  } catch (error) {
    console.error('equip item error:', error)
    return NextResponse.json(
      { error: 'Failed to equip item' },
      { status: 500 }
    )
  }
}
