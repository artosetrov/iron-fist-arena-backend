import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { ItemType, Rarity } from '@prisma/client'

export async function GET(req: NextRequest) {
  try {
    const typeParam = req.nextUrl.searchParams.get('type')
    const rarityParam = req.nextUrl.searchParams.get('rarity')

    const where: { itemType?: ItemType; rarity?: Rarity } = {}

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

    const items = await prisma.item.findMany({
      where,
      orderBy: [{ itemLevel: 'asc' }, { itemName: 'asc' }],
    })

    // Transform to snake_case format expected by iOS client
    const shopItems = items.map((item) => ({
      id: item.id,
      catalog_id: item.catalogId,
      item_name: item.itemName,
      item_type: item.itemType.toLowerCase(),
      rarity: item.rarity.toLowerCase(),
      required_level: item.itemLevel,
      gold_price: item.buyPrice,
      gem_price: 0,
      sell_price: item.sellPrice,
      description: item.description,
      image_url: item.imageUrl,
      special_effect: item.specialEffect,
    }))

    return NextResponse.json({ items: shopItems })
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error)
    console.error('list shop items error:', msg)
    return NextResponse.json(
      { error: 'Failed to fetch shop items', detail: msg },
      { status: 500 }
    )
  }
}
