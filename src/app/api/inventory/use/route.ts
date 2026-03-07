import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'

/**
 * Map item names to stamina restore amounts.
 * This handles consumable items from the regular inventory (drops/loot).
 */
const STAMINA_RESTORE_BY_NAME: Record<string, number> = {
  'Small Stamina Potion': 30,
  'Medium Stamina Potion': 60,
  'Large Stamina Potion': 999, // full restore (capped at max)
}

/**
 * POST /api/inventory/use
 * Body: { character_id, inventory_id }
 * Uses a consumable item from the regular inventory and applies its effect.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, inventory_id } = body

    if (!character_id || !inventory_id) {
      return NextResponse.json(
        { error: 'character_id and inventory_id are required' },
        { status: 400 },
      )
    }

    const character = await prisma.character.findUnique({
      where: { id: character_id },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Find the item in inventory
    const item = await prisma.inventory.findFirst({
      where: {
        id: inventory_id,
        characterId: character_id,
      },
      include: { catalogItem: true },
    })

    if (!item) {
      return NextResponse.json({ error: 'Item not found in inventory' }, { status: 404 })
    }

    const itemName = item.catalogItem?.itemName ?? ''
    const itemType = item.catalogItem?.itemType ?? ''

    if (itemType !== 'consumable') {
      return NextResponse.json({ error: 'Item is not a consumable' }, { status: 400 })
    }

    // Determine the effect
    const staminaRestore = STAMINA_RESTORE_BY_NAME[itemName]

    if (staminaRestore == null) {
      return NextResponse.json(
        { error: 'Unknown consumable effect for this item' },
        { status: 400 },
      )
    }

    // Calculate current stamina with regen
    const staminaResult = calculateCurrentStamina(
      character.currentStamina,
      character.maxStamina,
      character.lastStaminaUpdate ?? new Date(),
    )

    if (staminaResult.stamina >= character.maxStamina) {
      return NextResponse.json(
        { error: 'Stamina is already full' },
        { status: 400 },
      )
    }

    const newStamina = Math.min(staminaResult.stamina + staminaRestore, character.maxStamina)
    const now = new Date()

    // Delete item and update stamina in a transaction
    await prisma.$transaction([
      prisma.inventory.delete({ where: { id: inventory_id } }),
      prisma.character.update({
        where: { id: character_id },
        data: {
          currentStamina: newStamina,
          lastStaminaUpdate: now,
        },
      }),
    ])

    // Update daily quest progress
    await updateDailyQuestProgress(prisma, character_id, 'consumable_use')

    return NextResponse.json({
      used: true,
      itemName,
      stamina: {
        before: staminaResult.stamina,
        after: newStamina,
        max: character.maxStamina,
        restored: newStamina - staminaResult.stamina,
      },
    })
  } catch (error) {
    console.error('use inventory item error:', error)
    return NextResponse.json(
      { error: 'Failed to use item' },
      { status: 500 },
    )
  }
}
