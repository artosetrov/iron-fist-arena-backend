import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ItemType, Rarity } from '@prisma/client'
import { getGameConfig } from '@/lib/game/config'

// Hardcoded price fallbacks — overridden by GameConfig consumable.price.* keys
const DEFAULT_CONSUMABLE_PRICES: Record<string, number> = {
  stamina_potion_small: 100,
  stamina_potion_medium: 250,
  stamina_potion_large: 500,
  health_potion_small: 150,
  health_potion_medium: 350,
  health_potion_large: 700,
}

// Gem packs: required level to unlock each tier
const GEM_PACK_REQUIRED_LEVELS: Record<string, number> = {
  gem_pack_small: 1,
  gem_pack_medium: 5,
  gem_pack_large: 10,
}

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

    // --- Load equipment items (non-consumable) ---
    const equipWhere: {
      itemType?: ItemType | { not: ItemType }
      rarity?: Rarity
      itemLevel?: { lte: number }
      equipment?: { none: { characterId: string } }
    } = { itemType: { not: ItemType.consumable } }

    if (typeParam && typeParam !== 'consumable') {
      if (!Object.values(ItemType).includes(typeParam as ItemType)) {
        return NextResponse.json(
          { error: `Invalid type. Must be one of: ${Object.values(ItemType).join(', ')}` },
          { status: 400 }
        )
      }
      equipWhere.itemType = typeParam as ItemType
    }

    if (rarityParam) {
      if (!Object.values(Rarity).includes(rarityParam as Rarity)) {
        return NextResponse.json(
          { error: `Invalid rarity. Must be one of: ${Object.values(Rarity).join(', ')}` },
          { status: 400 }
        )
      }
      equipWhere.rarity = rarityParam as Rarity
    }

    equipWhere.itemLevel = { lte: character.level + 2 }
    equipWhere.equipment = { none: { characterId } }

    const equipmentItems = await prisma.item.findMany({
      where: equipWhere,
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

    // --- Load consumable items from DB ---
    const consumableItems = await prisma.item.findMany({
      where: { itemType: ItemType.consumable },
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
      orderBy: { catalogId: 'asc' },
    })

    // Transform equipment items to snake_case
    const shopItems = equipmentItems.map((item) => ({
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

    // Batch-load all consumable prices from GameConfig ONCE (fix N+1)
    const consumablePriceMap = new Map<string, number>()
    const priceKeys = Object.keys(DEFAULT_CONSUMABLE_PRICES)
    await Promise.all(
      priceKeys.map(async (key) => {
        const price = await getGameConfig<number>(
          `consumable.price.${key}`,
          DEFAULT_CONSUMABLE_PRICES[key]
        )
        consumablePriceMap.set(key, price)
      })
    )

    // Transform consumable items — use pre-loaded GameConfig prices
    const consumableShopItems = consumableItems.map((item) => {
        const catalogId = item.catalogId
        const isGemPack = catalogId.startsWith('gem_pack')

        // For gem packs, check required level
        if (isGemPack) {
          const requiredLevel = GEM_PACK_REQUIRED_LEVELS[catalogId] ?? 1
          if (character.level < requiredLevel) return null
        }

        // Use pre-loaded price from GameConfig (only for potions, not gem packs)
        let goldPrice = item.buyPrice
        if (!isGemPack && consumablePriceMap.has(catalogId)) {
          goldPrice = consumablePriceMap.get(catalogId)!
        }

        return {
          id: item.id,
          catalog_id: catalogId,
          item_name: item.itemName,
          item_type: 'consumable',
          rarity: item.rarity.toLowerCase(),
          item_level: item.itemLevel,
          required_level: isGemPack ? (GEM_PACK_REQUIRED_LEVELS[catalogId] ?? 1) : 1,
          gold_price: goldPrice,
          gem_price: 0,
          sell_price: item.sellPrice,
          base_stats: item.baseStats,
          description: item.description,
          image_url: item.imageUrl,
          image_key: item.imageKey,
          special_effect: item.specialEffect,
          unique_passive: item.uniquePassive,
          set_name: item.setName,
          consumable_type: catalogId,
        }
      })

    // Filter out nulls (gem packs gated by level)
    const filteredConsumables = consumableShopItems.filter(
      (c): c is NonNullable<typeof c> => c !== null
    )

    const allItems = [...shopItems, ...filteredConsumables]

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
