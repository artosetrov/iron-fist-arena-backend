import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { UPGRADE_CHANCES } from '@/lib/game/balance'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { recalculateDerivedStats } from '@/lib/game/equipment-stats'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, inventory_id } = body

    if (!character_id || !inventory_id) {
      return NextResponse.json(
        { error: 'character_id and inventory_id are required' },
        { status: 400 }
      )
    }

    // Get the inventory item (read-only, no race concern on item data)
    const inventoryItem = await prisma.equipmentInventory.findUnique({
      where: { id: inventory_id },
      include: { item: true },
    })

    if (!inventoryItem) {
      return NextResponse.json({ error: 'Inventory item not found' }, { status: 404 })
    }
    if (inventoryItem.characterId !== character_id) {
      return NextResponse.json({ error: 'Item does not belong to this character' }, { status: 403 })
    }

    const currentLevel = inventoryItem.upgradeLevel
    if (currentLevel >= UPGRADE_CHANCES.length) {
      return NextResponse.json({ error: 'Item is already at maximum upgrade level' }, { status: 400 })
    }

    const upgradeCost = (currentLevel + 1) * 100
    const successChance = UPGRADE_CHANCES[currentLevel]
    const roll = Math.random() * 100
    const success = roll < successChance

    // Use interactive transaction with row-level lock to prevent TOCTOU
    const result = await prisma.$transaction(async (tx) => {
      const [character] = await tx.$queryRawUnsafe<Array<{ id: string; user_id: string; gold: number }>>(
        `SELECT id, user_id, gold FROM characters WHERE id = $1 FOR UPDATE`,
        character_id
      )

      if (!character) throw new Error('NOT_FOUND')
      if (character.user_id !== user.id) throw new Error('FORBIDDEN')
      if (character.gold < upgradeCost) throw new Error('NOT_ENOUGH_GOLD')

      const updatedCharacter = await tx.character.update({
        where: { id: character_id },
        data: { gold: { decrement: upgradeCost } },
      })

      let updatedItem = inventoryItem
      if (success) {
        updatedItem = await tx.equipmentInventory.update({
          where: { id: inventory_id },
          data: { upgradeLevel: { increment: 1 } },
          include: { item: true },
        })
      }

      return { updatedCharacter, updatedItem }
    })

    // Non-critical post-transaction work
    await updateDailyQuestProgress(prisma, character_id, 'item_upgrade')
    await updateDailyQuestProgress(prisma, character_id, 'gold_spent', upgradeCost)

    if (success && result.updatedItem.isEquipped) {
      await recalculateDerivedStats(character_id)
    }

    const dbUser = await prisma.user.findUnique({ where: { id: user.id }, select: { gems: true } })

    return NextResponse.json({
      success,
      inventoryItem: result.updatedItem,
      character: {
        gold: result.updatedCharacter.gold,
        gems: dbUser?.gems ?? 0,
      },
      upgradeCost,
      newLevel: success ? currentLevel + 1 : currentLevel,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'NOT_ENOUGH_GOLD') return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
    }
    console.error('upgrade item error:', error)
    return NextResponse.json({ error: 'Failed to upgrade item' }, { status: 500 })
  }
}
