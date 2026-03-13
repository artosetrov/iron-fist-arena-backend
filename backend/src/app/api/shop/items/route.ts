import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ItemType, Rarity, ConsumableType } from '@prisma/client'

// Gem packages purchasable with gold (1 gem = 15 gold)
const GEM_CATALOG = [
  {
    id: 'gem_pack_small',
    catalog_id: 'gem_pack_small',
    item_name: 'Small Gem Pouch',
    item_type: 'consumable',
    rarity: 'uncommon',
    item_level: 1,
    required_level: 1,
    gold_price: 150,
    gem_price: 0,
    sell_price: 0,
    base_stats: {},
    description: 'Contains 10 gems.',
    image_url: null,
    special_effect: null,
    unique_passive: null,
    set_name: null,
    consumable_type: 'gem_pack_small',
  },
  {
    id: 'gem_pack_medium',
    catalog_id: 'gem_pack_medium',
    item_name: 'Medium Gem Pouch',
    item_type: 'consumable',
    rarity: 'rare',
    item_level: 1,
    required_level: 5,
    gold_price: 750,
    gem_price: 0,
    sell_price: 0,
    base_stats: {},
    description: 'Contains 50 gems.',
    image_url: null,
    special_effect: null,
    unique_passive: null,
    set_name: null,
    consumable_type: 'gem_pack_medium',
  },
  {
    id: 'gem_pack_large',
    catalog_id: 'gem_pack_large',
    item_name: 'Large Gem Pouch',
    item_type: 'consumable',
    rarity: 'epic',
    item_level: 1,
    required_level: 10,
    gold_price: 1500,
    gem_price: 0,
    sell_price: 0,
    base_stats: {},
    description: 'Contains 100 gems.',
    image_url: null,
    special_effect: null,
    unique_passive: null,
    set_name: null,
    consumable_type: 'gem_pack_large',
  },
]

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

    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { id: true, userId: true, level: true },
    })

    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    // Build filter — always exclude consumables from DB (served from CONSUMABLE_CATALOG)
    const where: {
      itemType?: ItemType | { not: ItemType };
      rarity?: Rarity;
      itemLevel?: { lte: number };
      equipment?: { none: { characterId: string } };
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
    where.equipment = { none: { characterId } }

    const items = await prisma.item.findMany({
      where,
      select: {
        id: true,
        catalogId: true,
        itemName: true,
        itemType: true,
        rarity: true,
        itemLevel: true,
        buyPrice: true,
        sellPrice: true,
        baseStats: true,
        description: true,
        imageUrl: true,
        imageKey: true,
        specialEffect: true,
        uniquePassive: true,
        setName: true,
      },
      orderBy: [{ itemLevel: 'asc' }, { itemName: 'asc' }],
    })

    // Transform to snake_case format expected by iOS client
    const shopItems = items.map((item) => ({
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
      image_key: item.imageKey,
      special_effect: item.specialEffect,
      unique_passive: item.uniquePassive,
      set_name: item.setName,
    }))

    // Filter gem catalog by character level
    const availableGems = GEM_CATALOG.filter((g) => character.level >= g.required_level)

    // Append consumable + gem catalog entries (always available)
    const allItems = [...shopItems, ...CONSUMABLE_CATALOG, ...availableGems]

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
