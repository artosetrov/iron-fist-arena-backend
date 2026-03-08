import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/admin/economy
 * Returns economy statistics: total gold, gems, IAP revenue, etc.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const [
      totalGold,
      totalGems,
      totalIapGems,
      iapByProduct,
      goldTopCharacters,
    ] = await Promise.all([
      prisma.character.aggregate({ _sum: { gold: true } }),
      prisma.user.aggregate({ _sum: { gems: true } }),
      prisma.iapTransaction.aggregate({
        where: { status: 'verified' },
        _sum: { gemsAwarded: true },
        _count: true,
      }),
      prisma.iapTransaction.groupBy({
        by: ['productId'],
        where: { status: 'verified' },
        _count: true,
        _sum: { gemsAwarded: true },
      }),
      prisma.character.findMany({
        select: { characterName: true, gold: true, level: true },
        orderBy: { gold: 'desc' },
        take: 10,
      }),
    ])

    return NextResponse.json({
      gold: {
        total_in_circulation: totalGold._sum.gold ?? 0,
        top_holders: goldTopCharacters,
      },
      gems: {
        total_in_circulation: totalGems._sum.gems ?? 0,
        total_from_iap: totalIapGems._sum.gemsAwarded ?? 0,
        iap_transactions: totalIapGems._count,
      },
      iap_by_product: iapByProduct.map((p) => ({
        product_id: p.productId,
        count: p._count,
        gems_awarded: p._sum.gemsAwarded ?? 0,
      })),
    })
  } catch (error) {
    console.error('admin economy error:', error)
    return NextResponse.json({ error: 'Failed to fetch economy stats' }, { status: 500 })
  }
}
