import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { recalculateDerivedStats } from '@/lib/game/equipment-stats'
import { invalidateSkillCache, invalidatePassiveCache } from '@/lib/game/combat-loader'
import { rateLimit } from '@/lib/rate-limit'
import { buildInventoryResponse } from '@/lib/game/inventory-response'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`unequip:${user.id}`, 20, 60_000))) {
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
        select: { userId: true },
      }),
      prisma.equipmentInventory.findUnique({
        where: { id: inventory_id },
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

    if (!inventoryItem.isEquipped) {
      // BUG-62 (2026-04-11): return the full inventory snapshot (HTTP 200)
      // instead of an error. Previously the client parsed this as failure
      // and rolled back its optimistic state — the item "bounced" back
      // to the equipment slot. Returning the authoritative snapshot lets
      // the optimistic/server states converge cleanly.
      const snapshot = await buildInventoryResponse(character_id).catch(() => null)
      if (snapshot) return NextResponse.json(snapshot)
      return NextResponse.json({ error: 'Item is not equipped' }, { status: 400 })
    }

    await prisma.$transaction(async (tx) => {
      // Keep the stat recompute in the same transaction as the unequip write.
      // Otherwise the item state can commit and then bubble a false 500 later.
      await tx.equipmentInventory.update({
        where: { id: inventory_id },
        data: {
          isEquipped: false,
          equippedSlot: null,
        },
      })

      await recalculateDerivedStats(character_id, tx)
    })

    // Invalidate caches after the unequip + stat recompute transaction commits.
    // BUG-62 (2026-04-11): inventory fetch moved into the shared
    // `buildInventoryResponse` helper so equip/unequip return the same
    // full snapshot shape as GET /api/inventory (equipment + consumables
    // + inventorySlots). The client used to merge a consumable-less
    // response and silently lost potions.
    await Promise.all([
      invalidateSkillCache(character_id),
      invalidatePassiveCache(character_id),
    ])

    const inventoryResponse = await buildInventoryResponse(character_id)
    return NextResponse.json(inventoryResponse)
  } catch (error) {
    console.error('unequip item error:', error)
    return NextResponse.json(
      { error: 'Failed to unequip item' },
      { status: 500 }
    )
  }
}
