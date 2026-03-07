import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ItemType, Rarity } from '@prisma/client'

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    const typeParam = req.nextUrl.searchParams.get('type')
    const rarityParam = req.nextUrl.searchParams.get('rarity')

    if (!characterId) {
      return NextResponse.json(
        { error: 'character_id is required' },
        { status: 400 }
      )
    }

    // Verify character ownership
    const character = await prisma.character.findUnique({
      where: { id: characterId },
    })

    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    // Get item IDs this character already owns (purchased before)
    const ownedItems = await prisma.equipmentInventory.findMany({
      where: { characterId },
      select: { itemId: true },
    })
    const ownedItemIds = new Set(ownedItems.map((e) => e.itemId))

    // Build filter
    const where: { itemType?: ItemType; rarity?: Rarity; itemLevel?: { lte: number } } = {}

    if (typeParam) {
      if (!Object.values(ItemType).includes(typeParam as ItemType)) {
        return NextResponse.json(
          { error: `Invalid type. Must be one of: ${Object.values(ItemType).join(', ')}` },
          { status: 400 }
        )
      }
      where.itemType = typeParam as ItemType
    }

    if (rarityParam) {
      if (!Object.values(Rarity).includes(rarityParam as Rarity)) {
        return NextResponse.json(
          { error: `Invalid rarity. Must be one of: ${Object.values(Rarity).join(', ')}` },
          { status: 400 }
        )
      }
      where.rarity = rarityParam as Rarity
    }

    // Level-based assortment: show items up to character level + 2
    where.itemLevel = { lte: character.level + 2 }

    const items = await prisma.item.findMany({
      where,
      orderBy: [{ itemLevel: 'asc' }, { itemName: 'asc' }],
    })

    // Filter out items this character already owns (consumables are always available)
    const consumableTypes: ItemType[] = [ItemType.consumable]
    const availableItems = items.filter(
      (item) => consumableTypes.includes(item.itemType) || !ownedItemIds.has(item.id)
    )

    // Transform to snake_case format expected by iOS client
    const shopItems = availableItems.map((item) => ({
      id: item.id,
      catalog_id: item.catalogId,
      item_name: item.itemName,
      item_type: item.itemType.toLowerCase(),
      rarity: item.rarity.toLowerCase(),
      item_level: item.itemLevel,
      required_level: item.itemLevel,
      gold_price: item.buyPrice,
      gem_price: 0,
      sell_price: item.sellPrice,
      base_stats: item.baseStats,
      description: item.description,
      image_url: item.imageUrl,
      special_effect: item.specialEffect,
      unique_passive: item.uniquePassive,
      set_name: item.setName,
    }))

    return NextResponse.json({
      items: shopItems,
      character_level: character.level,
    })
  } catch (error) {
    console.error('list shop items error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch shop items' },
      { status: 500 }
    )
  }
}
