import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { STAMINA, GEM_COSTS } from '@/lib/game/balance'

const GEMS_PER_REFILL = GEM_COSTS.STAMINA_REFILL

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
        max_stamina: number; last_stamina_update: Date | null
      }>>(
        `SELECT id, user_id, current_stamina, max_stamina, last_stamina_update FROM characters WHERE id = $1 FOR UPDATE`,
        character_id
      )

      if (!character) throw new Error('NOT_FOUND')
      if (character.user_id !== user.id) throw new Error('FORBIDDEN')

      const staminaResult = calculateCurrentStamina(
        character.current_stamina,
        character.max_stamina,
        character.last_stamina_update ?? new Date()
      )

      if (staminaResult.stamina >= STAMINA.MAX) throw new Error('STAMINA_FULL')
      if (!userRecord || userRecord.gems < GEMS_PER_REFILL) throw new Error('NOT_ENOUGH_GEMS')

      const now = new Date()

      await tx.user.update({
        where: { id: user.id },
        data: { gems: { decrement: GEMS_PER_REFILL } },
      })

      await tx.character.update({
        where: { id: character_id },
        data: { currentStamina: STAMINA.MAX, lastStaminaUpdate: now },
      })

      return {
        staminaBefore: staminaResult.stamina,
        gemsRemaining: userRecord.gems - GEMS_PER_REFILL,
      }
    })

    return NextResponse.json({
      stamina: { before: result.staminaBefore, after: STAMINA.MAX, max: STAMINA.MAX },
      gems_spent: GEMS_PER_REFILL,
      gems_remaining: result.gemsRemaining,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'STAMINA_FULL') return NextResponse.json({ error: 'Stamina is already full' }, { status: 400 })
      if (error.message === 'NOT_ENOUGH_GEMS') return NextResponse.json({ error: 'Not enough gems', required: GEMS_PER_REFILL }, { status: 400 })
    }
    console.error('stamina refill error:', error)
    return NextResponse.json({ error: 'Failed to refill stamina' }, { status: 500 })
  }
}
