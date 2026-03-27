import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { calculateSetBonuses, ITEM_SETS } from '@/lib/game/item-sets'

/**
 * GET /api/characters/:id/set-bonuses
 * Returns active set bonuses for the character's equipped items.
 */
export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const user = await getAuthUser(req)
    if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

    const { id: characterId } = await params

    // Verify ownership
    const character = await prisma.character.findFirst({
      where: { id: characterId, userId: user.id },
      select: { id: true },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    // Fetch equipped items with catalog info
    const equippedItems = await prisma.equipmentInventory.findMany({
      where: { characterId, isEquipped: true },
      include: { item: { select: { catalogId: true, setName: true, itemName: true } } },
    })

    const catalogKeys = equippedItems.map(i => i.item.catalogId)
    const activeSets = calculateSetBonuses(catalogKeys)

    // Enrich with full set piece names
    const setsWithDetails = activeSets.map(set => {
      const setDef = ITEM_SETS.find(s => s.id === set.setId)
      return {
        ...set,
        allPieces: setDef?.pieces.map(key => ({
          key,
          owned: catalogKeys.includes(key),
        })) ?? [],
      }
    })

    return NextResponse.json({ sets: setsWithDetails })
  } catch (error) {
    console.error('set-bonuses GET error:', error)
    return NextResponse.json({ error: 'Internal error' }, { status: 500 })
  }
}
