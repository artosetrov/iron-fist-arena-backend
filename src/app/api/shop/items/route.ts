import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ItemType, Rarity, ConsumableType } from '@prisma/client'

// Consumable catalog for the shop display
const CONSUMABLE_CATALOG = [
  {
    id: 'consumable_stamina_potion_small',
    catalog_id: 'stamina_potion_small',
    item_name: 'Small Stamina Potion',
    item_type: 'consumable',
    rarity: 'common',
    item_level: 1,
    required_level: 1,
    gold_price: 100,
    gem_price: 0,
    sell_price: 0,
    base_stats: {},
    description: 'Restores 30 stamina.',
    image_url: null,
    special_effect: null,
    unique_passive: null,
    set_name: null,
    consumable_type: 'stamina_potion_small',
  },
  {
    id: 'consumable_stamina_potion_medium',
    catalog_id: 'stamina_potion_medium',
    item_name: 'Medium Stamina Potion',
    item_type: 'consumable',
    rarity: 'uncommon',
    item_level: 1,
    required_level: 1,
    gold_price: 250,
    gem_price: 0,
    sell_price: 0,
    base_stats: {},
    description: 'Restores 60 stamina.',
    image_url: null,
    special_effect: null,
    unique_passive: null,
    set_name: null,
    consumable_type: 'stamina_potion_medium',
  },
  {
    id: 'consumable_stamina_potion_large',
    catalog_id: 'stamina_potion_large',
    item_name: 'Large Stamina Potion',
    item_type: 'consumable',
    rarity: 'rare',
    item_level: 1,
    required_level: 1,
    gold_price: 500,
    gem_price: 0,
    sell_price: 0,
    base_stats: {},
    description: 'Fully restores stamina.',
    image_url: null,
    special_effect: null,
    unique_passive: null,
    set_name: null,
    consumable_type: 'stamina_potion_large',
  },
  {
    id: 'consumable_health_potion_small',
    catalog_id: 'health_potion_small',
    item_name: 'Small Health Potion',
    item_type: 'consumable',
    rarity: 'common',
    item_level: 1,
    required_level: 1,
    gold_price: 150,
    gem_price: 0,
    sell_price: 0,
    base_stats: {},
    description: 'Restores 25% of max HP.',
    image_url: null,
    special_effect: null,
    unique_passive: null,
    set_name: null,
    consumable_type: 'health_potion_small',
  },
  {
    id: 'consumable_health_potion_medium',
    catalog_id: 'health_potion_medium',
    item_name: 'Medium Health Potion',
    item_type: 'consumable',
    rarity: 'uncommon',
    item_level: 1,
    required_level: 1,
    gold_price: 350,
    gem_price: 0,
    sell_price: 0,
    base_stats: {},
    description: 'Restores 50% of max HP.',
    image_url: null,
    special_effect: null,
    unique_passive: null,
    set_name: null,
    consumable_type: 'health_potion_medium',
  },
  {
    id: 'consumable_health_potion_large',
    catalog_id: 'health_potion_large',
    item_name: 'Large Health Potion',
    item_type: 'consumable',
    rarity: 'rare',
    item_level: 1,
    required_level: 1,
    gold_price: 700,
    gem_price: 0,
    sell_price: 0,
    base_stats: {},
    description: 'Fully restores HP.',
    image_url: null,
    special_effect: null,
    unique_passive: null,
    set_name: null,
    consumable_type: 'health_potion_large',
  },
]

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

    // Build filter — always exclude consumables from DB (served from CONSUMABLE_CATALOG)
    const where: {
      itemType?: ItemType | { not: ItemType };
      rarity?: Rarity;
      itemLevel?: { lte: number };
    } = { itemType: { not: ItemType.consumable } }

    if (typeParam && typeParam !== 'consumable') {
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

    // Filter out items this character already owns
    const availableItems = items.filter(
      (item) => !ownedItemIds.has(item.id)
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

    // Append consumable catalog entries (always available)
    const allItems = [...shopItems, ...CONSUMABLE_CATALOG]

    return NextResponse.json({
      items: allItems,
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
