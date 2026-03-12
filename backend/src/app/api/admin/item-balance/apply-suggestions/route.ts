import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

/**
 * POST /api/admin/item-balance/apply-suggestions
 * Apply suggested stat changes to an item.
 * Body: { itemId, suggestedStats, suggestedSellPrice }
 */
export async function POST(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const { itemId, suggestedStats, suggestedSellPrice } = await req.json()

    if (!itemId || !suggestedStats) {
      return NextResponse.json({ error: 'itemId and suggestedStats are required' }, { status: 400 })
    }

    const item = await prisma.item.findUnique({ where: { id: itemId } })
    if (!item) {
      return NextResponse.json({ error: 'Item not found' }, { status: 404 })
    }

    const oldStats = item.baseStats
    const oldPrice = item.sellPrice

    const updated = await prisma.item.update({
      where: { id: itemId },
      data: {
        baseStats: suggestedStats,
        sellPrice: suggestedSellPrice ?? item.sellPrice,
      },
    })

    await prisma.adminLog.create({
      data: {
        adminId: user.id,
        action: 'apply_balance_suggestion',
        details: {
          itemId,
          itemName: item.itemName,
          oldStats,
          newStats: suggestedStats,
          oldPrice,
          newPrice: suggestedSellPrice ?? oldPrice,
        },
      },
    })

    return NextResponse.json({
      item: {
        id: updated.id,
        itemName: updated.itemName,
        itemType: updated.itemType,
        rarity: updated.rarity,
        itemLevel: updated.itemLevel,
        baseStats: updated.baseStats,
        sellPrice: updated.sellPrice,
      },
    })
  } catch (error) {
    console.error('apply suggestions error:', error)
    return NextResponse.json({ error: 'Failed to apply suggestions' }, { status: 500 })
  }
}
