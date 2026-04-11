import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { getStaminaConfig, getGemCostsConfig } from '@/lib/game/live-config'
import { staminaRefillGemCost, STAMINA_REFILL_DR } from '@/lib/game/balance'
import { currentDailyValue } from '@/lib/game/daily-counter'

/**
 * POST /api/stamina/refill
 * Body: { character_id }
 * Fully restores stamina for GEMS_PER_REFILL gems.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`stamina-refill:${user.id}`, 5, 10_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const [STAMINA, GEM_COSTS] = await Promise.all([
      getStaminaConfig(),
      getGemCostsConfig(),
    ])
    const BASE_GEMS_PER_REFILL = GEM_COSTS.STAMINA_REFILL

    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    // Use interactive transaction with row-level locks to prevent TOCTOU
    const result = await prisma.$transaction(async (tx) => {
      // Lock both user and character rows
      const [userRecord] = await tx.$queryRawUnsafe<Array<{ id: string; gems: number }>>(
        `SELECT id, gems FROM users WHERE id = $1 FOR UPDATE`,
        user.id
      )

      const [character] = await tx.$queryRawUnsafe<Array<{
        id: string; user_id: string; current_stamina: number;
        max_stamina: number; last_stamina_update: Date | null;
        stamina_refills_today: number; stamina_refills_date: Date | null;
      }>>(
        `SELECT id, user_id, current_stamina, max_stamina, last_stamina_update,
                stamina_refills_today, stamina_refills_date
         FROM characters WHERE id = $1 FOR UPDATE`,
        character_id
      )

      if (!character) throw new Error('NOT_FOUND')
      if (character.user_id !== user.id) throw new Error('FORBIDDEN')

      const staminaResult = await calculateCurrentStamina(
        character.current_stamina,
        character.max_stamina,
        character.last_stamina_update ?? new Date()
      )

      if (staminaResult.stamina >= STAMINA.MAX) throw new Error('STAMINA_FULL')

      const now = new Date()

      // W3.D4 — stamina refill diminishing returns + hard daily cap.
      // Lazy reset: if the stored date is not today, the counter is effectively 0.
      const refillsUsedToday = currentDailyValue(
        character.stamina_refills_today,
        character.stamina_refills_date,
        now,
      )

      const dynamicCost = staminaRefillGemCost(BASE_GEMS_PER_REFILL, refillsUsedToday)
      if (dynamicCost === null) throw new Error('REFILL_CAP_REACHED')
      if (!userRecord || userRecord.gems < dynamicCost) throw new Error('NOT_ENOUGH_GEMS')

      await tx.user.update({
        where: { id: user.id },
        data: { gems: { decrement: dynamicCost } },
      })

      await tx.character.update({
        where: { id: character_id },
        data: {
          currentStamina: STAMINA.MAX,
          lastStaminaUpdate: now,
          staminaRefillsToday: refillsUsedToday + 1,
          staminaRefillsDate: now,
        },
      })

      return {
        staminaBefore: staminaResult.stamina,
        gemsRemaining: userRecord.gems - dynamicCost,
        refillIndex: refillsUsedToday + 1,
        cost: dynamicCost,
      }
    })

    return NextResponse.json({
      stamina: { before: result.staminaBefore, after: STAMINA.MAX, max: STAMINA.MAX },
      gems_spent: result.cost,
      gems_remaining: result.gemsRemaining,
      refill_index: result.refillIndex,
      daily_cap: STAMINA_REFILL_DR.DAILY_CAP,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'STAMINA_FULL') return NextResponse.json({ error: 'Stamina is already full' }, { status: 400 })
      if (error.message === 'REFILL_CAP_REACHED') {
        return NextResponse.json(
          { error: 'Daily refill cap reached', cap: STAMINA_REFILL_DR.DAILY_CAP },
          { status: 429 },
        )
      }
      if (error.message === 'NOT_ENOUGH_GEMS') {
        try {
          const GEM_COSTS = await getGemCostsConfig()
          return NextResponse.json({ error: 'Not enough gems', required: GEM_COSTS.STAMINA_REFILL }, { status: 400 })
        } catch {
          return NextResponse.json({ error: 'Not enough gems' }, { status: 400 })
        }
      }
    }
    console.error('stamina refill error:', error)
    return NextResponse.json({ error: 'Failed to refill stamina' }, { status: 500 })
  }
}
