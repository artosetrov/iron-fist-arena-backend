import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { rateLimit } from '@/lib/rate-limit'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`shop-buy:${user.id}`, 15, 60_000)) {
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
      // Lock the character row for update
      const [character] = await tx.$queryRawUnsafe<Array<{ id: string; user_id: string; gold: number }>>(
        `SELECT id, user_id, gold FROM characters WHERE id = $1 FOR UPDATE`,
        character_id
      )

      if (!character) throw new Error('NOT_FOUND')
      if (character.user_id !== user.id) throw new Error('FORBIDDEN')
      if (character.gold < item.buyPrice) throw new Error('NOT_ENOUGH_GOLD')

      const updatedCharacter = await tx.character.update({
        where: { id: character_id },
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

      return { updatedCharacter, inventoryItem }
    })

    // Update daily quest progress (outside transaction, non-critical)
    await updateDailyQuestProgress(prisma, character_id, 'gold_spent', item.buyPrice)

    const dbUser = await prisma.user.findUnique({ where: { id: user.id }, select: { gems: true } })

    return NextResponse.json({
      inventoryItem: result.inventoryItem,
      character: {
        gold: result.updatedCharacter.gold,
        gems: dbUser?.gems ?? 0,
      },
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'NOT_ENOUGH_GOLD') return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
    }
    console.error('buy item error:', error)
    return NextResponse.json({ error: 'Failed to buy item' }, { status: 500 })
  }
}
