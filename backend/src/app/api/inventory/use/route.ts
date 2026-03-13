import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { rateLimit } from '@/lib/rate-limit'

/**
 * Stamina restore amounts by item name.
 */
const STAMINA_RESTORE: Record<string, number> = {
  'Small Stamina Potion': 30,
  'Medium Stamina Potion': 60,
  'Large Stamina Potion': 999,
}

/**
 * POST /api/inventory/use
 * Body: { character_id, inventory_id }
 * Uses a consumable item from equipmentInventory and applies its effect.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`use-item:${user.id}`, 20, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

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

    // Find the item in equipmentInventory
    const inventoryItem = await prisma.equipmentInventory.findUnique({
      where: { id: inventory_id },
      include: { item: true },
    })

    if (!inventoryItem || inventoryItem.characterId !== character_id) {
      return NextResponse.json({ error: 'Item not found in inventory' }, { status: 404 })
    }

    if (inventoryItem.item.itemType !== 'consumable') {
      return NextResponse.json({ error: 'Item is not a consumable' }, { status: 400 })
    }

    const itemName = inventoryItem.item.itemName
    const staminaRestore = STAMINA_RESTORE[itemName]

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
      prisma.equipmentInventory.delete({ where: { id: inventory_id } }),
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
