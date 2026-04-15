import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ConsumableType } from '@prisma/client'
import { calculateCurrentHp } from '@/lib/game/hp-regen'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'
import { rateLimit } from '@/lib/rate-limit'
import {
  getHpRestorePercent,
  getStaminaRestore,
  isHealthPotion,
  isStaminaPotion,
} from '@/lib/game/consumable-effects'

const LEGACY_CONSUMABLE_BY_NAME: Record<string, ConsumableType> = {
  'Small Stamina Potion': 'stamina_potion_small',
  'Medium Stamina Potion': 'stamina_potion_medium',
  'Large Stamina Potion': 'stamina_potion_large',
  'Small Health Potion': 'health_potion_small',
  'Medium Health Potion': 'health_potion_medium',
  'Large Health Potion': 'health_potion_large',
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
    const catalogConsumableType =
      inventoryItem.item.catalogId &&
      Object.values(ConsumableType).includes(inventoryItem.item.catalogId as ConsumableType)
        ? inventoryItem.item.catalogId as ConsumableType
        : null
    const consumableType = catalogConsumableType ?? LEGACY_CONSUMABLE_BY_NAME[itemName]

    if (!consumableType) {
      return NextResponse.json(
        { error: 'Unknown consumable effect for this item' },
        { status: 400 },
      )
    }
    const now = new Date()
    if (isStaminaPotion(consumableType)) {
      const staminaResult = await calculateCurrentStamina(
        character.currentStamina,
        character.maxStamina,
        character.lastStaminaUpdate ?? now,
      )

      if (staminaResult.stamina >= character.maxStamina) {
        return NextResponse.json(
          { error: 'Stamina is already full' },
          { status: 400 },
        )
      }

      const staminaRestore = await getStaminaRestore(consumableType)
      const newStamina = Math.min(staminaResult.stamina + staminaRestore, character.maxStamina)

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

      // Update daily + weekly quest progress
      await Promise.all([
        updateDailyQuestProgress(prisma, character_id, 'consumable_use'),
        updateWeeklyChallengeProgress(prisma, character_id, 'consumable_use'),
      ])

      return NextResponse.json({
        used: true,
        consumable_type: consumableType,
        itemName,
        stamina: {
          before: staminaResult.stamina,
          after: newStamina,
          max: character.maxStamina,
          restored: newStamina - staminaResult.stamina,
        },
      })
    }

    if (!isHealthPotion(consumableType)) {
      return NextResponse.json(
        { error: 'Unknown consumable effect for this item' },
        { status: 400 },
      )
    }

    const hpResult = await calculateCurrentHp(
      character.currentHp,
      character.maxHp,
      character.lastHpUpdate ?? now,
    )

    if (hpResult.hp >= character.maxHp) {
      return NextResponse.json(
        { error: 'Health is already full' },
        { status: 400 },
      )
    }

    const hpRestorePercent = await getHpRestorePercent(consumableType)
    const restoreAmount = Math.floor(character.maxHp * hpRestorePercent / 100)
    const newHp = Math.min(hpResult.hp + restoreAmount, character.maxHp)

    await prisma.$transaction([
      prisma.equipmentInventory.delete({ where: { id: inventory_id } }),
      prisma.character.update({
        where: { id: character_id },
        data: {
          currentHp: newHp,
          lastHpUpdate: now,
        },
      }),
    ])

    // Update daily + weekly quest progress
    await Promise.all([
      updateDailyQuestProgress(prisma, character_id, 'consumable_use'),
      // W3.D5 — Weekly BP challenge: Alchemist slot
      updateWeeklyChallengeProgress(prisma, character_id, 'consumable_use'),
    ])

    return NextResponse.json({
      used: true,
      consumable_type: consumableType,
      itemName,
      health: {
        before: hpResult.hp,
        after: newHp,
        max: character.maxHp,
        restored: newHp - hpResult.hp,
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
