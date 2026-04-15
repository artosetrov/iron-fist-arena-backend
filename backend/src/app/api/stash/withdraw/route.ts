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

    try {
      await prisma.$transaction(async (tx) => {
        await tx.$queryRawUnsafe(
          'SELECT id FROM characters WHERE id = $1 FOR UPDATE',
          character_id,
        )

        const inventoryCount = await tx.equipmentInventory.count({
          where: { characterId: character_id },
        })
        if (inventoryCount >= character.inventorySlots) {
          throw new Error('INVENTORY_FULL')
        }

        const [stashItem] = await tx.$queryRawUnsafe<Array<{
          id: string
          user_id: string
          item_id: string
          upgrade_level: number
          durability: number
          max_durability: number
          rolled_stats: unknown
        }>>(
          `SELECT id, user_id, item_id, upgrade_level, durability,
                  max_durability, rolled_stats
             FROM stash_items
            WHERE id = $1
            FOR UPDATE`,
          stash_item_id,
        )

        if (!stashItem || stashItem.user_id !== user.id) {
          throw new Error('STASH_ITEM_NOT_FOUND')
        }

        await tx.stashItem.delete({ where: { id: stash_item_id } })
        await tx.equipmentInventory.create({
          data: {
            characterId: character_id,
            itemId: stashItem.item_id,
            upgradeLevel: stashItem.upgrade_level,
            durability: stashItem.durability,
            maxDurability: stashItem.max_durability,
            rolledStats: stashItem.rolled_stats ?? undefined,
            isEquipped: false,
            equippedSlot: null,
          },
        })
      })
    } catch (error) {
      if (error instanceof Error) {
        if (error.message === 'INVENTORY_FULL') {
          return NextResponse.json(
            { error: 'Character inventory is full' },
            { status: 400 }
          )
        }
        if (error.message === 'STASH_ITEM_NOT_FOUND') {
          return NextResponse.json({ error: 'Stash item not found' }, { status: 404 })
        }
      }
      throw error
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('[stash/withdraw]', error)
    return NextResponse.json({ error: 'Failed to withdraw item' }, { status: 500 })
  }
}
