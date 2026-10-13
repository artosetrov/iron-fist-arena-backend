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
import { STAMINA_POTION_DR } from '@/lib/game/balance'
import { currentDailyValue, isDifferentUtcDay } from '@/lib/game/daily-counter'

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
    if (!isStaminaPotion(consumableType) && !isHealthPotion(consumableType)) {
      return NextResponse.json(
        { error: 'Unknown consumable effect for this item' },
        { status: 400 },
      )
    }

    // Everything that reads a counter and writes it back happens under a row
    // lock. The pre-tx reads above are only for early 4xx responses; the
    // authoritative stamina/HP/daily-cap checks are re-done here so parallel
    // requests cannot bypass STAMINA_POTION_DR.DAILY_CAP (AUDIT-2026-10-13 M1).
    // Mirrors /api/consumables/use.
    type Outcome =
      | { kind: 'stamina'; before: number; after: number; max: number }
      | { kind: 'health'; before: number; after: number; max: number }

    const outcome = await prisma.$transaction(async (tx): Promise<Outcome> => {
      const [locked] = await tx.$queryRawUnsafe<Array<{
        current_stamina: number
        max_stamina: number
        last_stamina_update: Date | null
        current_hp: number
        max_hp: number
        last_hp_update: Date | null
        stamina_potions_today: number
        stamina_potions_date: Date | null
      }>>(
        `SELECT current_stamina, max_stamina, last_stamina_update,
                current_hp, max_hp, last_hp_update,
                stamina_potions_today, stamina_potions_date
         FROM characters
         WHERE id = $1
         FOR UPDATE`,
        character_id,
      )
      if (!locked) throw new Error('CHARACTER_NOT_FOUND')

      // Lock the inventory row too: two requests for the same inventory_id
      // must not both delete it and both apply the effect.
      const [lockedRow] = await tx.$queryRawUnsafe<Array<{ id: string }>>(
        `SELECT id FROM equipment_inventory WHERE id = $1 AND character_id = $2 FOR UPDATE`,
        inventory_id,
        character_id,
      )
      if (!lockedRow) throw new Error('ITEM_GONE')

      const now = new Date()

      if (isStaminaPotion(consumableType)) {
        const staminaResult = await calculateCurrentStamina(
          locked.current_stamina,
          locked.max_stamina,
          locked.last_stamina_update ?? now,
        )
        if (staminaResult.stamina >= locked.max_stamina) throw new Error('STAMINA_FULL')

        const potionsUsedToday = currentDailyValue(
          locked.stamina_potions_today,
          locked.stamina_potions_date,
          now,
        )
        if (potionsUsedToday >= STAMINA_POTION_DR.DAILY_CAP) throw new Error('STAMINA_POTION_CAP')

        const staminaRestore = await getStaminaRestore(consumableType)
        const newStamina = Math.min(staminaResult.stamina + staminaRestore, locked.max_stamina)
        const dayRolled = isDifferentUtcDay(locked.stamina_potions_date, now)

        await tx.equipmentInventory.delete({ where: { id: inventory_id } })
        await tx.character.update({
          where: { id: character_id },
          data: {
            currentStamina: newStamina,
            lastStaminaUpdate: now,
            // Atomic increment under the lock; reset to 1 on day rollover.
            staminaPotionsToday: dayRolled ? 1 : { increment: 1 },
            ...(dayRolled ? { staminaPotionsDate: now } : {}),
          },
        })

        return { kind: 'stamina', before: staminaResult.stamina, after: newStamina, max: locked.max_stamina }
      }

      const hpResult = await calculateCurrentHp(
        locked.current_hp,
        locked.max_hp,
        locked.last_hp_update ?? now,
      )
      if (hpResult.hp >= locked.max_hp) throw new Error('HP_FULL')

      const hpRestorePercent = await getHpRestorePercent(consumableType)
      const restoreAmount = Math.floor(locked.max_hp * hpRestorePercent / 100)
      const newHp = Math.min(hpResult.hp + restoreAmount, locked.max_hp)

      await tx.equipmentInventory.delete({ where: { id: inventory_id } })
      await tx.character.update({
        where: { id: character_id },
        data: { currentHp: newHp, lastHpUpdate: now },
      })

      return { kind: 'health', before: hpResult.hp, after: newHp, max: locked.max_hp }
    }).catch((err: unknown) => {
      const code = err instanceof Error ? err.message : ''
      switch (code) {
        case 'STAMINA_FULL':
          return NextResponse.json({ error: 'Stamina is already full' }, { status: 400 })
        case 'HP_FULL':
          return NextResponse.json({ error: 'Health is already full' }, { status: 400 })
        case 'STAMINA_POTION_CAP':
          return NextResponse.json(
            {
              error: `You can drink ${STAMINA_POTION_DR.DAILY_CAP} stamina potions per day. Resets at 00:00 UTC.`,
              code: 'STAMINA_POTION_CAP',
              dailyCap: STAMINA_POTION_DR.DAILY_CAP,
            },
            { status: 429 },
          )
        case 'ITEM_GONE':
          return NextResponse.json({ error: 'Item not found in inventory' }, { status: 404 })
        case 'CHARACTER_NOT_FOUND':
          return NextResponse.json({ error: 'Character not found' }, { status: 404 })
        default:
          throw err
      }
    })

    if (outcome instanceof NextResponse) return outcome

    // Update daily + weekly quest progress (W3.D5 — Weekly BP challenge: Alchemist slot)
    await Promise.all([
      updateDailyQuestProgress(prisma, character_id, 'consumable_use'),
      updateWeeklyChallengeProgress(prisma, character_id, 'consumable_use'),
    ])

    const effect = {
      before: outcome.before,
      after: outcome.after,
      max: outcome.max,
      restored: outcome.after - outcome.before,
    }
    return NextResponse.json({
      used: true,
      consumable_type: consumableType,
      itemName,
      ...(outcome.kind === 'stamina' ? { stamina: effect } : { health: effect }),
    })
  } catch (error) {
    console.error('use inventory item error:', error)
    return NextResponse.json(
      { error: 'Failed to use item' },
      { status: 500 },
    )
  }
}
