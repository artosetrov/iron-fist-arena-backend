import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { recalculateDerivedStats } from '@/lib/game/equipment-stats'
import { invalidateSkillCache, invalidatePassiveCache } from '@/lib/game/combat-loader'
import { rateLimit } from '@/lib/rate-limit'
import { TWO_HANDED_CATALOG_IDS } from '@/lib/game/item-constants'

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
    console.error('unequip item error:', error)
    return NextResponse.json(
      { error: 'Failed to unequip item' },
      { status: 500 }
    )
  }
}
