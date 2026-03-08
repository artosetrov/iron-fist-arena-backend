import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'
import { suggestStatAdjustments } from '@/lib/game/item-validation'

/**
 * POST /api/admin/item-balance/suggest
 * Get suggestions for one item. Body: { itemId }
 */
export async function POST(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const { itemId } = await req.json()
    if (!itemId) {
      return NextResponse.json({ error: 'itemId is required' }, { status: 400 })
    }

    const item = await prisma.item.findUnique({ where: { id: itemId } })
    if (!item) {
      return NextResponse.json({ error: 'Item not found' }, { status: 404 })
    }

    const suggestion = await suggestStatAdjustments({
      id: item.id,
      baseStats: (item.baseStats as Record<string, number>) ?? {},
      rarity: item.rarity,
      itemLevel: item.itemLevel,
      itemType: item.itemType,
      sellPrice: item.sellPrice,
    })

    return NextResponse.json({
      item: {
        id: item.id,
        itemName: item.itemName,
        itemType: item.itemType,
        rarity: item.rarity,
        itemLevel: item.itemLevel,
        baseStats: item.baseStats,
        sellPrice: item.sellPrice,
      },
      suggestion,
    })
  } catch (error) {
    console.error('suggest adjustments error:', error)
    return NextResponse.json({ error: 'Failed to generate suggestions' }, { status: 500 })
  }
}
