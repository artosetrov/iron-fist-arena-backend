import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ItemType, Rarity } from '@prisma/client'
import { getGameConfig } from '@/lib/game/config'
import { TWO_HANDED_CATALOG_IDS } from '@/lib/game/item-constants'
import { GEM_PACKS, isGemPackCatalogId } from '@/lib/game/gem-packs'

// Hardcoded price fallbacks — overridden by GameConfig consumable.price.* keys
// Economy v2 — consumable prices increased ~25-35% to create recurring gold sink pressure
const DEFAULT_CONSUMABLE_PRICES: Record<string, number> = {
  stamina_potion_small: 150,   // was 100
  stamina_potion_medium: 300,  // was 250
  stamina_potion_large: 600,   // was 500
  health_potion_small: 200,    // was 150
  health_potion_medium: 400,   // was 350
  health_potion_large: 800,    // was 700
}

// Gem pack required levels and fallback prices are now the single source of truth
// in @/lib/game/gem-packs — shared with /api/shop/buy-gems so listing and transaction
// agree on amounts and prices. Do NOT duplicate these values here.
const GEM_PACK_REQUIRED_LEVELS: Record<string, number> = Object.fromEntries(
  Object.values(GEM_PACKS).map((p) => [p.catalogId, p.requiredLevel])
)
const GEM_PACK_FALLBACK_PRICES: Record<string, number> = Object.fromEntries(
  Object.values(GEM_PACKS).map((p) => [p.catalogId, p.goldPrice])
)

// Calculate fallback price for equipment items with buyPrice = 0
function calculateFallbackPrice(rarity: string, level: number): number {
  const base = {
    common: 100,
    uncommon: 300,
    rare: 800,
    epic: 2500,
    legendary: 8000,
  }
  const basePrice = base[rarity as keyof typeof base] ?? 100
  return Math.round(basePrice * (1 + (level - 1) * 0.15))
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
      select: { id: true, userId: true, level: true, class: true },
    })

    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    // --- Load equipment items (non-consumable) ---
    // Filter out items restricted to other classes
    const equipWhere: {
      itemType?: ItemType | { not: ItemType }
      rarity?: Rarity
      itemLevel?: { lte: number }
      equipment?: { none: { characterId: string } }
      OR?: Array<{ classRestriction: null } | { classRestriction: string }>
    } = {
      itemType: { not: ItemType.consumable },
      OR: [
        { classRestriction: null },          // universal items
        { classRestriction: character.class }, // items for player's class
      ],
    }

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
        classRestriction: true,
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

    // Build per-type image fallback map: itemType → { imageUrl, imageKey }
    // Items without their own image will borrow the image of another item
    // of the same type (e.g. a helmet without art shows another helmet's art).
    const typeFallbackImage = new Map<string, { imageUrl: string | null; imageKey: string | null }>()
    for (const item of equipmentItems) {
      const t = item.itemType.toLowerCase()
      if (!typeFallbackImage.has(t) && (item.imageUrl || item.imageKey)) {
        typeFallbackImage.set(t, { imageUrl: item.imageUrl, imageKey: item.imageKey })
      }
    }

    // Transform equipment items to snake_case
    const shopItems = equipmentItems.map((item) => {
      const hasImage = !!(item.imageUrl || item.imageKey)
      const fallback = hasImage ? null : typeFallbackImage.get(item.itemType.toLowerCase())
      return {
        id: item.id,
        catalog_id: item.catalogId,
        item_name: item.itemName,
        item_type: item.itemType.toLowerCase(),
        rarity: item.rarity.toLowerCase(),
        item_level: item.itemLevel,
        required_level: item.itemLevel,
        gold_price: item.buyPrice > 0 ? item.buyPrice : calculateFallbackPrice(item.rarity.toLowerCase(), item.itemLevel),
        gem_price: 0,
        sell_price: item.sellPrice,
        base_stats: item.baseStats,
        description: item.description,
        image_url: item.imageUrl ?? fallback?.imageUrl ?? null,
        image_key: item.imageKey ?? fallback?.imageKey ?? null,
        special_effect: item.specialEffect,
        unique_passive: item.uniquePassive,
        set_name: item.setName,
        class_restriction: item.classRestriction?.toLowerCase() ?? null,
        is_two_handed: item.itemType === 'weapon' && TWO_HANDED_CATALOG_IDS.has(item.catalogId),
      }
    })

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

        // Gem packs: ALWAYS use the canonical value from GEM_PACKS, ignore DB.
        // /api/shop/buy-gems trusts GEM_PACKS as the single source of truth — if the
        // listing used a different price from DB, clients would deduct X gold
        // optimistically while the server actually charges Y. Keep them aligned.
        if (isGemPack && isGemPackCatalogId(catalogId)) {
          goldPrice = GEM_PACKS[catalogId].goldPrice
        }

        // Safety net: no item should ever cost 0 gold
        if (goldPrice <= 0) {
          goldPrice = calculateFallbackPrice(item.rarity.toLowerCase(), item.itemLevel)
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
