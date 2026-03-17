import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ConsumableType } from '@prisma/client'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { calculateCurrentHp } from '@/lib/game/hp-regen'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { rateLimit } from '@/lib/rate-limit'
import { getGameConfig } from '@/lib/game/config'

// Hardcoded fallbacks — overridden by GameConfig consumable.* keys
const DEFAULT_STAMINA_RESTORE: Partial<Record<ConsumableType, number>> = {
  stamina_potion_small: 30,
  stamina_potion_medium: 60,
  stamina_potion_large: 999, // full restore (capped at max)
}

const DEFAULT_HP_RESTORE_PERCENT: Partial<Record<ConsumableType, number>> = {
  health_potion_small: 25,   // 25% of max HP
  health_potion_medium: 50,  // 50% of max HP
  health_potion_large: 100,  // full restore
}

const STAMINA_POTION_TYPES = new Set<string>([
  'stamina_potion_small', 'stamina_potion_medium', 'stamina_potion_large',
])

const HEALTH_POTION_TYPES = new Set<string>([
  'health_potion_small', 'health_potion_medium', 'health_potion_large',
])

function isStaminaPotion(type: ConsumableType): boolean {
  return STAMINA_POTION_TYPES.has(type)
}

function isHealthPotion(type: ConsumableType): boolean {
  return HEALTH_POTION_TYPES.has(type)
}

async function getStaminaRestore(type: ConsumableType): Promise<number> {
  return getGameConfig<number>(
    `consumable.stamina_restore.${type}`,
    DEFAULT_STAMINA_RESTORE[type] ?? 0,
  )
}

async function getHpRestorePercent(type: ConsumableType): Promise<number> {
  return getGameConfig<number>(
    `consumable.hp_restore_percent.${type}`,
    DEFAULT_HP_RESTORE_PERCENT[type] ?? 0,
  )
}

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
      }>>(
        `SELECT id, user_id, current_stamina, max_stamina, last_stamina_update,
                current_hp, max_hp, last_hp_update
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

        const restore = await getStaminaRestore(ctEnum)
        const newStamina = Math.min(staminaResult.stamina + restore, character.max_stamina)

        const [, updatedConsumable] = await Promise.all([
          tx.character.update({
            where: { id: character_id },
            data: {
              currentStamina: newStamina,
              lastStaminaUpdate: now,
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

    await updateDailyQuestProgress(prisma, character_id, 'consumable_use')

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
