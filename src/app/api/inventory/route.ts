import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { getUpgradeStatBonus } from '@/lib/game/item-balance'

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')

    if (!characterId) {
      return NextResponse.json(
        { error: 'character_id is required' },
        { status: 400 }
      )
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { userId: true, inventorySlots: true },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Fetch equipment and consumables in parallel
    const [equipment, consumables] = await Promise.all([
      prisma.equipmentInventory.findMany({
        where: { characterId },
        include: {
          item: {
            select: {
              id: true, itemName: true, itemType: true, rarity: true, itemLevel: true,
              baseStats: true, setName: true, specialEffect: true, uniquePassive: true,
              imageUrl: true, classRestriction: true, description: true,
            },
          },
        },
        orderBy: { acquiredAt: 'desc' },
      }),
      prisma.consumableInventory.findMany({
        where: { characterId },
        orderBy: { consumableType: 'asc' },
      }),
    ])

    // Calculate effective stats for each equipment item (baseStats + upgrade bonus)
    const upgradeStatBonus = await getUpgradeStatBonus()
    const equipmentWithEffectiveStats = equipment.map((eq) => {
      const baseStats = (eq.item.baseStats as Record<string, number>) ?? {}
      const effectiveStats: Record<string, number> = {}
      for (const [stat, baseValue] of Object.entries(baseStats)) {
        effectiveStats[stat] = baseValue + eq.upgradeLevel * upgradeStatBonus
      }
      return { ...eq, effectiveStats }
    })

    return NextResponse.json({
      equipment: equipmentWithEffectiveStats,
      consumables,
      inventorySlots: character.inventorySlots,
    })
  } catch (error) {
    console.error('get inventory error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch inventory' },
      { status: 500 }
    )
  }
}
