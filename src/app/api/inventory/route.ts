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
      select: { userId: true },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const equipment = await prisma.equipmentInventory.findMany({
      where: { characterId },
      include: { item: true },
      orderBy: { acquiredAt: 'desc' },
    })

    const consumables = await prisma.consumableInventory.findMany({
      where: { characterId },
      orderBy: { consumableType: 'asc' },
    })

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

    return NextResponse.json({ equipment: equipmentWithEffectiveStats, consumables })
  } catch (error) {
    console.error('get inventory error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch inventory' },
      { status: 500 }
    )
  }
}
