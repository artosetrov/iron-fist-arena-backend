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

    try {
      await prisma.$transaction(async (tx) => {
        await tx.$queryRawUnsafe(
          'SELECT id FROM users WHERE id = $1 FOR UPDATE',
          user.id,
        )

        const stashCount = await tx.stashItem.count({
          where: { userId: user.id },
        })
        if (stashCount >= STASH_MAX_SLOTS) {
          throw new Error('STASH_FULL')
        }

        const [equipItem] = await tx.$queryRawUnsafe<Array<{
          id: string
          character_id: string
          item_id: string
          upgrade_level: number
          durability: number
          max_durability: number
          rolled_stats: unknown
          is_equipped: boolean
        }>>(
          `SELECT id, character_id, item_id, upgrade_level, durability,
                  max_durability, rolled_stats, is_equipped
             FROM equipment_inventory
            WHERE id = $1
            FOR UPDATE`,
          equipment_id,
        )

        if (!equipItem || equipItem.character_id !== character_id) {
          throw new Error('ITEM_NOT_FOUND')
        }
        if (equipItem.is_equipped) {
          throw new Error('ITEM_EQUIPPED')
        }

        await tx.equipmentInventory.delete({ where: { id: equipment_id } })
        await tx.stashItem.create({
          data: {
            userId: user.id,
            itemId: equipItem.item_id,
            upgradeLevel: equipItem.upgrade_level,
            durability: equipItem.durability,
            maxDurability: equipItem.max_durability,
            rolledStats: equipItem.rolled_stats ?? undefined,
          },
        })
      })
    } catch (error) {
      if (error instanceof Error) {
        if (error.message === 'STASH_FULL') {
          return NextResponse.json(
            { error: 'Stash is full', maxSlots: STASH_MAX_SLOTS },
            { status: 400 }
          )
        }
        if (error.message === 'ITEM_NOT_FOUND') {
          return NextResponse.json({ error: 'Item not found in inventory' }, { status: 404 })
        }
        if (error.message === 'ITEM_EQUIPPED') {
          return NextResponse.json(
            { error: 'Cannot deposit equipped items. Unequip first.' },
            { status: 400 }
          )
        }
      }
      throw error
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('[stash/deposit]', error)
    return NextResponse.json({ error: 'Failed to deposit item' }, { status: 500 })
  }
}
