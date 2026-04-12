import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

/**
 * POST /api/stash/withdraw — move an item from account stash to character inventory.
 * Body: { character_id, stash_item_id }
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, stash_item_id } = body

    if (!character_id || !stash_item_id) {
      return NextResponse.json(
        { error: 'character_id and stash_item_id are required' },
        { status: 400 }
      )
    }

    // Verify character belongs to user
    const character = await prisma.character.findUnique({
      where: { id: character_id },
      select: { userId: true, inventorySlots: true },
    })
    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    // Check character inventory capacity
    const inventoryCount = await prisma.equipmentInventory.count({
      where: { characterId: character_id },
    })
    if (inventoryCount >= character.inventorySlots) {
      return NextResponse.json(
        { error: 'Character inventory is full' },
        { status: 400 }
      )
    }

    // Find the stash item — must belong to user
    const stashItem = await prisma.stashItem.findUnique({
      where: { id: stash_item_id },
    })
    if (!stashItem || stashItem.userId !== user.id) {
      return NextResponse.json({ error: 'Stash item not found' }, { status: 404 })
    }

    // Move: delete from stash, create in equipment (atomic transaction)
    await prisma.$transaction([
      prisma.stashItem.delete({ where: { id: stash_item_id } }),
      prisma.equipmentInventory.create({
        data: {
          characterId: character_id,
          itemId: stashItem.itemId,
          upgradeLevel: stashItem.upgradeLevel,
          durability: stashItem.durability,
          maxDurability: stashItem.maxDurability,
          rolledStats: stashItem.rolledStats ?? undefined,
          isEquipped: false,
          equippedSlot: null,
        },
      }),
    ])

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('[stash/withdraw]', error)
    return NextResponse.json({ error: 'Failed to withdraw item' }, { status: 500 })
  }
}
