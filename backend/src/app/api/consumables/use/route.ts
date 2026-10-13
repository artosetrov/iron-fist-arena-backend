import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ConsumableType } from '@prisma/client'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { calculateCurrentHp } from '@/lib/game/hp-regen'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'
import { rateLimit } from '@/lib/rate-limit'
import {
  getStaminaRestore,
  getHpRestorePercent,
  isStaminaPotion,
  isHealthPotion,
} from '@/lib/game/consumable-effects'
import { invalidateActiveSlotsCache } from '@/lib/game/active-slots'
import { STAMINA_POTION_DR } from '@/lib/game/balance'
import { currentDailyValue, isDifferentUtcDay } from '@/lib/game/daily-counter'

/**
 * POST /api/consumables/use
 * Body: { character_id, consumable_type }
 * Uses one consumable from inventory and applies its effect.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`consumable-use:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

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

    const ctEnum = consumable_type as ConsumableType
    const result = await prisma.$transaction(async (tx) => {
      const [character] = await tx.$queryRawUnsafe<Array<{
        id: string
        user_id: string
        current_stamina: number
        max_stamina: number
        last_stamina_update: Date | null
        current_hp: number
        max_hp: number
        last_hp_update: Date | null
        stamina_potions_today: number
        stamina_potions_date: Date | null
      }>>(
        `SELECT id, user_id, current_stamina, max_stamina, last_stamina_update,
                current_hp, max_hp, last_hp_update,
                stamina_potions_today, stamina_potions_date
         FROM characters
         WHERE id = $1
         FOR UPDATE`,
        character_id
      )

      if (!character) throw new Error('CHARACTER_NOT_FOUND')
      if (character.user_id !== user.id) throw new Error('FORBIDDEN')

      const [consumable] = await tx.$queryRawUnsafe<Array<{ id: string; quantity: number }>>(
        `SELECT id, quantity
         FROM consumable_inventory
         WHERE character_id = $1 AND consumable_type::text = $2
         FOR UPDATE`,
        character_id,
        consumable_type
      )

      if (!consumable || consumable.quantity < 1) {
        throw new Error('NO_CONSUMABLE')
      }

      const now = new Date()

      if (isStaminaPotion(ctEnum)) {
        const staminaResult = await calculateCurrentStamina(
          character.current_stamina,
          character.max_stamina,
          character.last_stamina_update ?? now
        )

        if (staminaResult.stamina >= character.max_stamina) {
          throw new Error('STAMINA_FULL')
        }

        // Daily cap, lazily reset — mirrors the gem-refill cap. Without it,
        // free contraband potions made the stamina budget meaningless.
        const potionsUsedToday = currentDailyValue(
          character.stamina_potions_today,
          character.stamina_potions_date,
          now
        )
        if (potionsUsedToday >= STAMINA_POTION_DR.DAILY_CAP) {
          throw new Error('STAMINA_POTION_CAP')
        }

        const restore = await getStaminaRestore(ctEnum)
        const newStamina = Math.min(staminaResult.stamina + restore, character.max_stamina)

        const [, updatedConsumable] = await Promise.all([
          tx.character.update({
            where: { id: character_id },
            data: {
              currentStamina: newStamina,
              lastStaminaUpdate: now,
              staminaPotionsToday: potionsUsedToday + 1,
              // Only stamp the date when the day rolled over, so the column
              // keeps marking the day the counter belongs to.
              ...(isDifferentUtcDay(character.stamina_potions_date, now)
                ? { staminaPotionsDate: now }
                : {}),
            },
          }),
          tx.consumableInventory.update({
            where: { id: consumable.id },
            data: { quantity: { decrement: 1 } },
          }),
        ])

        return {
          kind: 'stamina' as const,
          before: staminaResult.stamina,
          after: newStamina,
          max: character.max_stamina,
          remaining: updatedConsumable.quantity,
          potionsUsedToday: potionsUsedToday + 1,
          potionsDailyCap: STAMINA_POTION_DR.DAILY_CAP,
        }
      }

      if (!isHealthPotion(ctEnum)) {
        throw new Error('UNKNOWN_CONSUMABLE')
      }

      const hpResult = await calculateCurrentHp(
        character.current_hp,
        character.max_hp,
        character.last_hp_update ?? now
      )

      if (hpResult.hp >= character.max_hp) {
        throw new Error('HEALTH_FULL')
      }

      const percent = await getHpRestorePercent(ctEnum)
      const restoreAmount = Math.floor(character.max_hp * percent / 100)
      const newHp = Math.min(hpResult.hp + restoreAmount, character.max_hp)

      const [, updatedConsumable] = await Promise.all([
        tx.character.update({
          where: { id: character_id },
          data: { currentHp: newHp, lastHpUpdate: now },
        }),
        tx.consumableInventory.update({
          where: { id: consumable.id },
          data: { quantity: { decrement: 1 } },
        }),
      ])

      return {
        kind: 'health' as const,
        before: hpResult.hp,
        after: newHp,
        max: character.max_hp,
        remaining: updatedConsumable.quantity,
      }
    })

    await Promise.all([
      updateDailyQuestProgress(prisma, character_id, 'consumable_use'),
      // W3.D5 — Weekly BP challenge: Alchemist slot
      updateWeeklyChallengeProgress(prisma, character_id, 'consumable_use'),
      isHealthPotion(ctEnum) ? invalidateActiveSlotsCache(character_id) : Promise.resolve(),
    ])

    if (result.kind === 'stamina') {
      return NextResponse.json({
        consumable_type,
        stamina: {
          before: result.before,
          after: result.after,
          max: result.max,
          restored: result.after - result.before,
        },
        remaining_quantity: result.remaining,
        // So the client can show "2 of 4 today" instead of only discovering
        // the cap by getting a 429 on the fifth potion.
        potions_used_today: result.potionsUsedToday,
        potions_daily_cap: result.potionsDailyCap,
      })
    }

    return NextResponse.json({
      consumable_type,
      health: {
        before: result.before,
        after: result.after,
        max: result.max,
        restored: result.after - result.before,
      },
      remaining_quantity: result.remaining,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'CHARACTER_NOT_FOUND') {
        return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      }
      if (error.message === 'FORBIDDEN') {
        return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      }
      if (error.message === 'NO_CONSUMABLE') {
        return NextResponse.json({ error: 'No consumable of this type in inventory' }, { status: 400 })
      }
      if (error.message === 'STAMINA_FULL') {
        return NextResponse.json({ error: 'Stamina is already full' }, { status: 400 })
      }
      if (error.message === 'STAMINA_POTION_CAP') {
        return NextResponse.json(
          {
            error: `You can drink ${STAMINA_POTION_DR.DAILY_CAP} stamina potions per day. Resets at 00:00 UTC.`,
            code: 'STAMINA_POTION_CAP',
            dailyCap: STAMINA_POTION_DR.DAILY_CAP,
          },
          { status: 429 }
        )
      }
      if (error.message === 'HEALTH_FULL') {
        return NextResponse.json({ error: 'Health is already full' }, { status: 400 })
      }
      if (error.message === 'UNKNOWN_CONSUMABLE') {
        return NextResponse.json({ error: 'Unknown consumable type' }, { status: 400 })
      }
    }
    console.error('use consumable error:', error)
    return NextResponse.json({ error: 'Failed to use consumable' }, { status: 500 })
  }
}
