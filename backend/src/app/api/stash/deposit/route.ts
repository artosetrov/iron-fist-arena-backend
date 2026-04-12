import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

const STASH_MAX_SLOTS = 100

/**
 * POST /api/stash/deposit — move an unequipped item from character inventory to account stash.
 * Body: { character_id, equipment_id }
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, equipment_id } = body

    if (!character_id || !equipment_id) {
      return NextResponse.json(
        { error: 'character_id and equipment_id are required' },
        { status: 400 }
      )
    }

    // Verify character belongs to user
    const character = await prisma.character.findUnique({
      where: { id: character_id },
      select: { userId: true },
    })
    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    // Check stash capacity
    const stashCount = await prisma.stashItem.count({
      where: { userId: user.id },
    })
    if (stashCount >= STASH_MAX_SLOTS) {
      return NextResponse.json(
        { error: 'Stash is full', maxSlots: STASH_MAX_SLOTS },
        { status: 400 }
      )
    }

    // Find the equipment item — must be unequipped
    const equipItem = await prisma.equipmentInventory.findUnique({
      where: { id: equipment_id },
      include: { item: { select: { id: true } } },
    })
    if (!equipItem || equipItem.characterId !== character_id) {
      return NextResponse.json({ error: 'Item not found in inventory' }, { status: 404 })
    }
    if (equipItem.isEquipped) {
      return NextResponse.json(
        { error: 'Cannot deposit equipped items. Unequip first.' },
        { status: 400 }
      )
    }

    // Move: delete from equipment, create in stash (atomic transaction)
    await prisma.$transaction([
      prisma.equipmentInventory.delete({ where: { id: equipment_id } }),
      prisma.stashItem.create({
        data: {
          userId: user.id,
          itemId: equipItem.itemId,
          upgradeLevel: equipItem.upgradeLevel,
          durability: equipItem.durability,
          maxDurability: equipItem.maxDurability,
          rolledStats: equipItem.rolledStats ?? undefined,
        },
      }),
    ])

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('[stash/deposit]', error)
    return NextResponse.json({ error: 'Failed to deposit item' }, { status: 500 })
  }
}
