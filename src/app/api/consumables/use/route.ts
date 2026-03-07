import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ConsumableType } from '@prisma/client'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { STAMINA } from '@/lib/game/balance'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'

// How much stamina each potion restores
const STAMINA_RESTORE: Record<ConsumableType, number> = {
  stamina_potion_small: 30,
  stamina_potion_medium: 60,
  stamina_potion_large: 999, // full restore (capped at max)
}

/**
 * POST /api/consumables/use
 * Body: { character_id, consumable_type }
 * Uses one consumable from inventory and applies its effect.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, consumable_type } = body

    if (!character_id || !consumable_type) {
      return NextResponse.json(
        { error: 'character_id and consumable_type are required' },
        { status: 400 }
      )
    }

    if (!Object.values(ConsumableType).includes(consumable_type as ConsumableType)) {
      return NextResponse.json(
        { error: `Invalid consumable_type. Must be one of: ${Object.values(ConsumableType).join(', ')}` },
        { status: 400 }
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

    // Find consumable in inventory
    const consumable = await prisma.consumableInventory.findUnique({
      where: {
        characterId_consumableType: {
          characterId: character_id,
          consumableType: consumable_type as ConsumableType,
        },
      },
    })

    if (!consumable || consumable.quantity < 1) {
      return NextResponse.json({ error: 'No consumable of this type in inventory' }, { status: 400 })
    }

    // Calculate current stamina with regen
    const staminaResult = calculateCurrentStamina(
      character.currentStamina,
      character.maxStamina,
      character.lastStaminaUpdate ?? new Date()
    )

    const restore = STAMINA_RESTORE[consumable_type as ConsumableType]
    const newStamina = Math.min(staminaResult.stamina + restore, character.maxStamina)

    const now = new Date()

    // Decrement consumable and update stamina in transaction
    const [, updatedCharacter] = await prisma.$transaction([
      prisma.consumableInventory.update({
        where: { id: consumable.id },
        data: { quantity: { decrement: 1 } },
      }),
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
      consumable_type,
      stamina: {
        before: staminaResult.stamina,
        after: newStamina,
        max: STAMINA.MAX,
        restored: newStamina - staminaResult.stamina,
      },
      remaining_quantity: consumable.quantity - 1,
    })
  } catch (error) {
    console.error('use consumable error:', error)
    return NextResponse.json({ error: 'Failed to use consumable' }, { status: 500 })
  }
}
