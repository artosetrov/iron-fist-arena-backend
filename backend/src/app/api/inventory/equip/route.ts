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

    // Atomic read-validate-write in interactive transaction with FOR UPDATE
    // Prevents TOCTOU race: double-slot exploit, broken item equip, stale occupancy
    await prisma.$transaction(async (tx) => {
      // Step 1: Lock character + verify ownership
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true, level: true, class: true },
      })

      if (!character) throw new Error('CHARACTER_NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Step 2: Lock the target inventory item with FOR UPDATE
      const lockedItems = await tx.$queryRawUnsafe<any[]>(
        `SELECT ei.id, ei.character_id AS "characterId", ei.is_equipped AS "isEquipped",
                ei.equipped_slot AS "equippedSlot", ei.durability,
                i.item_type AS "itemType", i.item_level AS "itemLevel",
                i.class_restriction AS "classRestriction", i.catalog_id AS "catalogId"
         FROM equipment_inventory ei
         JOIN items i ON ei.item_id = i.id
         WHERE ei.id = $1
         FOR UPDATE`,
        inventory_id
      )

      const inventoryItem = lockedItems[0]
      if (!inventoryItem) throw new Error('ITEM_NOT_FOUND')
      if (inventoryItem.characterId !== character_id) throw new Error('ITEM_NOT_OWNED')

      // Validate: broken, level, class
      if (inventoryItem.durability === 0) throw new Error('ITEM_BROKEN')
      if (character.level < inventoryItem.itemLevel) throw new Error('LEVEL_TOO_LOW')

      const classRestriction = inventoryItem.classRestriction?.toLowerCase()
      if (classRestriction && classRestriction !== character.class) throw new Error('CLASS_RESTRICTED')

      // Determine possible slots
      const possibleSlots = ITEM_TYPE_TO_SLOTS[inventoryItem.itemType as ItemType]
      if (!possibleSlots?.length) throw new Error('NOT_EQUIPPABLE')

      // Already equipped — no-op
      if (inventoryItem.isEquipped && inventoryItem.equippedSlot) throw new Error('ALREADY_EQUIPPED')

      // Step 3: Lock ALL equipped items for this character (prevents double-slot)
      const equippedRows = await tx.$queryRawUnsafe<any[]>(
        `SELECT id, equipped_slot AS "equippedSlot", item_id AS "itemId"
         FROM equipment_inventory
         WHERE character_id = $1 AND is_equipped = true
         FOR UPDATE`,
        character_id
      )

      const occupiedSlots = new Set(equippedRows.map((r: any) => r.equippedSlot))

      // Find first empty slot, or fall back to priority slot
      let slot: EquippedSlot | null = null
      for (const candidate of possibleSlots) {
        if (!occupiedSlots.has(candidate)) {
          slot = candidate
          break
        }
      }
      if (!slot) {
        slot = possibleSlots[0]
      }

      // Two-handed weapon checks (using locked data — no extra query needed)
      const isTwoHanded = inventoryItem.itemType === 'weapon' &&
        TWO_HANDED_CATALOG_IDS.has(inventoryItem.catalogId)

      let mainHandIsTwoHanded = false
      if (slot === 'relic' && inventoryItem.itemType === 'weapon') {
        // Check main hand from already-locked equippedRows
        const mainHandRow = equippedRows.find((r: any) => r.equippedSlot === 'weapon')
        if (mainHandRow) {
          // Need catalog info for the main hand item
          const mainHandInfo = await tx.equipmentInventory.findUnique({
            where: { id: mainHandRow.id },
            select: { item: { select: { itemType: true, catalogId: true } } },
          })
          if (mainHandInfo && mainHandInfo.item.itemType === 'weapon' &&
              TWO_HANDED_CATALOG_IDS.has(mainHandInfo.item.catalogId)) {
            mainHandIsTwoHanded = true
          }
        }
      }

      // Step 4: Execute all writes inside the transaction

      // If two-handed: unequip off-hand (relic) slot
      if (isTwoHanded) {
        await tx.equipmentInventory.updateMany({
          where: {
            characterId: character_id,
            equippedSlot: 'relic',
            isEquipped: true,
          },
          data: { isEquipped: false, equippedSlot: null },
        })
      }

      // If equipping weapon to off-hand while main hand is two-handed: unequip main hand
      if (mainHandIsTwoHanded) {
        await tx.equipmentInventory.updateMany({
          where: {
            characterId: character_id,
            equippedSlot: 'weapon',
            isEquipped: true,
          },
          data: { isEquipped: false, equippedSlot: null },
        })
      }

      // Unequip current item in target slot
      await tx.equipmentInventory.updateMany({
        where: {
          characterId: character_id,
          equippedSlot: slot,
          isEquipped: true,
        },
        data: { isEquipped: false, equippedSlot: null },
      })

      // Equip the new item
      await tx.equipmentInventory.update({
        where: { id: inventory_id },
        data: {
          isEquipped: true,
          equippedSlot: slot as EquippedSlot,
        },
      })
    })

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
  } catch (error: any) {
    // Sentinel errors from interactive transaction → granular HTTP responses
    if (error.message === 'CHARACTER_NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    if (error.message === 'ITEM_NOT_FOUND') return NextResponse.json({ error: 'Inventory item not found' }, { status: 404 })
    if (error.message === 'ITEM_NOT_OWNED') return NextResponse.json({ error: 'Item does not belong to this character' }, { status: 403 })
    if (error.message === 'ITEM_BROKEN') return NextResponse.json({ error: 'Cannot equip a broken item. Repair it first.' }, { status: 400 })
    if (error.message === 'LEVEL_TOO_LOW') return NextResponse.json({ error: 'Character level too low for this item' }, { status: 400 })
    if (error.message === 'CLASS_RESTRICTED') return NextResponse.json({ error: 'This item is class-restricted' }, { status: 400 })
    if (error.message === 'NOT_EQUIPPABLE') return NextResponse.json({ error: 'Item cannot be equipped' }, { status: 400 })
    if (error.message === 'ALREADY_EQUIPPED') return NextResponse.json({ message: 'Item is already equipped' })

    console.error('equip item error:', error)
    return NextResponse.json(
      { error: 'Failed to equip item' },
      { status: 500 }
    )
  }
}
