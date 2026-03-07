import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, item_catalog_id } = body

    if (!character_id || !item_catalog_id) {
      return NextResponse.json(
        { error: 'character_id and item_catalog_id are required' },
        { status: 400 }
      )
    }

    // Verify character ownership
    const character = await prisma.character.findUnique({
      where: { id: character_id },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Find the item in the catalog
    const item = await prisma.item.findUnique({
      where: { catalogId: item_catalog_id },
    })

    if (!item) {
      return NextResponse.json({ error: 'Item not found in catalog' }, { status: 404 })
    }

    // Check gold
    if (character.gold < item.buyPrice) {
      return NextResponse.json(
        { error: 'Not enough gold', required: item.buyPrice, current: character.gold },
        { status: 400 }
      )
    }

    // Deduct gold and create inventory entry in a transaction
    const [updatedCharacter, inventoryItem] = await prisma.$transaction([
      prisma.character.update({
        where: { id: character_id },
        data: { gold: { decrement: item.buyPrice } },
      }),
      prisma.equipmentInventory.create({
        data: {
          characterId: character_id,
          itemId: item.id,
          upgradeLevel: 0,
          durability: 100,
          maxDurability: 100,
          isEquipped: false,
        },
        include: { item: true },
      }),
    ])

    return NextResponse.json({
      inventoryItem,
      character: {
        gold: updatedCharacter.gold,
        gems: updatedCharacter.gems,
      },
    })
  } catch (error) {
    console.error('buy item error:', error)
    return NextResponse.json(
      { error: 'Failed to buy item' },
      { status: 500 }
    )
  }
}
