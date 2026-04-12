import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'
import { updateTutorialQuestProgress } from '@/lib/game/tutorial'
import { rateLimit, shopRateLimit } from '@/lib/rate-limit'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await shopRateLimit(user.id)) || !(await rateLimit(`shop-buy:${user.id}`, 15, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, item_catalog_id } = body

    if (!character_id || !item_catalog_id) {
      return NextResponse.json(
        { error: 'character_id and item_catalog_id are required' },
        { status: 400 }
      )
    }

    // Find the item in the catalog (read-only, no race concern)
    const item = await prisma.item.findUnique({
      where: { catalogId: item_catalog_id },
    })

    if (!item) {
      return NextResponse.json({ error: 'Item not found in catalog' }, { status: 404 })
    }

    // Use interactive transaction with row-level lock to prevent TOCTOU
    const result = await prisma.$transaction(async (tx) => {
      // Lock the user row for update (gold balance)
      const [userRow] = await tx.$queryRawUnsafe<Array<{ id: string; gold: number; gems: number }>>(
        `SELECT id, gold, gems FROM users WHERE id = $1 FOR UPDATE`,
        user.id
      )

      if (!userRow) throw new Error('USER_NOT_FOUND')
      if (userRow.gold < item.buyPrice) throw new Error('NOT_ENOUGH_GOLD')

      // Verify character ownership and get inventory slots
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true, inventorySlots: true },
      })

      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      const inventoryCount = await tx.equipmentInventory.count({
        where: { characterId: character_id },
      })
      if (inventoryCount >= character.inventorySlots) throw new Error('INVENTORY_FULL')

      const updatedUser = await tx.user.update({
        where: { id: user.id },
        data: { gold: { decrement: item.buyPrice } },
      })

      const inventoryItem = await tx.equipmentInventory.create({
        data: {
          characterId: character_id,
          itemId: item.id,
          upgradeLevel: 0,
          durability: 100,
          maxDurability: 100,
          isEquipped: false,
        },
        include: { item: true },
      })

      return { updatedUser, inventoryItem }
    })

    // Update daily + weekly + tutorial quest progress (outside transaction, non-critical)
    await Promise.all([
      updateDailyQuestProgress(prisma, character_id, 'gold_spent', item.buyPrice),
      // W3.D5 — Weekly BP challenge: Spendthrift slot
      updateWeeklyChallengeProgress(prisma, character_id, 'gold_spent', item.buyPrice),
    ])
    updateTutorialQuestProgress(prisma, character_id, 'equip_gear').catch(() => {})

    return NextResponse.json({
      inventoryItem: result.inventoryItem,
      gold: result.updatedUser.gold,
      gems: result.updatedUser.gems,
      // Legacy nested shape preserved for backwards compatibility
      character: {
        gold: result.updatedUser.gold,
        gems: result.updatedUser.gems,
      },
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'NOT_ENOUGH_GOLD') return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
      if (error.message === 'INVENTORY_FULL') return NextResponse.json({ error: 'Inventory is full' }, { status: 409 })
    }
    console.error('buy item error:', error)
    return NextResponse.json({ error: 'Failed to buy item' }, { status: 500 })
  }
}
