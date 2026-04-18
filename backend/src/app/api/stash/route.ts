import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { getUpgradeStatBonus } from '@/lib/game/item-balance'
import { buildEffectiveItemStats } from '@/lib/game/item-stats'

const STASH_MAX_SLOTS = 100

/**
 * GET /api/stash — list all items in the user's account-level stash.
 * Shared across all characters of the same user.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const stashItems = await prisma.stashItem.findMany({
      where: { userId: user.id },
      include: {
        item: {
          select: {
            id: true, itemName: true, itemType: true, rarity: true, itemLevel: true,
            baseStats: true, setName: true, specialEffect: true, uniquePassive: true,
            imageUrl: true, imageKey: true, classRestriction: true, description: true,
            catalogId: true, buyPrice: true, sellPrice: true,
          },
        },
      },
      orderBy: { storedAt: 'desc' },
    })

    const upgradeStatBonus = await getUpgradeStatBonus()
    const enriched = stashItems.map((si) => {
      const effectiveStats = buildEffectiveItemStats(
        si.item.baseStats,
        si.rolledStats,
        si.upgradeLevel,
        upgradeStatBonus,
      )
      return { ...si, effectiveStats }
    })

    return NextResponse.json({
      items: enriched,
      maxSlots: STASH_MAX_SLOTS,
      usedSlots: stashItems.length,
    })
  } catch (error) {
    console.error('[stash/GET]', error)
    return NextResponse.json({ error: 'Failed to load stash' }, { status: 500 })
  }
}
