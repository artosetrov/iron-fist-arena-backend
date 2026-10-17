import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { goldBonusMultiplier, PREMIUM_ENTITLEMENT_USER_SELECT } from '@/lib/game/premium'
import { DESCENT, DESCENT_DUNGEON_ID } from '@/lib/game/descent/content'
import { createRun, isDescentState, type DescentState } from '@/lib/game/descent/engine'
import { runScaleFor, serializeState } from '@/lib/game/descent/server'
import { buildDescentView } from '@/lib/game/descent/view'

/**
 * POST /api/dungeon-rush/v2/start — begin a Descent run (or resume the active one).
 * Costs DESCENT.STAMINA_COST stamina when a new run is created.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`rush2-start:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json().catch(() => ({}))
    const characterId = typeof body?.character_id === 'string' ? body.character_id : null
    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const result = await prisma.$transaction(async (tx) => {
      const [character] = await tx.$queryRawUnsafe<Array<{
        id: string; user_id: string; level: number; cha: number
        current_stamina: number; max_stamina: number; last_stamina_update: Date | null
      }>>(
        `SELECT id, user_id, level, cha, current_stamina, max_stamina, last_stamina_update
           FROM characters WHERE id = $1 FOR UPDATE`,
        characterId,
      )
      if (!character) throw new Error('NOT_FOUND')
      if (character.user_id !== user.id) throw new Error('FORBIDDEN')

      const active = await tx.dungeonRun.findFirst({
        where: { characterId, difficulty: 'rush', dungeonId: DESCENT_DUNGEON_ID },
        orderBy: { createdAt: 'desc' },
      })
      if (active) {
        if (isDescentState(active.state)) {
          return { resumed: true, runId: active.id, state: active.state as unknown as DescentState }
        }
        await tx.dungeonRun.delete({ where: { id: active.id } })
      }

      const stamina = await calculateCurrentStamina(
        character.current_stamina,
        character.max_stamina,
        character.last_stamina_update ?? new Date(),
      )
      if (stamina.stamina < DESCENT.STAMINA_COST) {
        throw new Error(`STAMINA:Not enough stamina. Need ${DESCENT.STAMINA_COST}, have ${stamina.stamina}`)
      }
      await tx.character.update({
        where: { id: characterId },
        data: { currentStamina: stamina.stamina - DESCENT.STAMINA_COST, lastStaminaUpdate: new Date() },
      })

      const owner = await tx.user.findUnique({ where: { id: user.id }, select: PREMIUM_ENTITLEMENT_USER_SELECT })
      const scale = runScaleFor(character.level, character.cha, owner ? goldBonusMultiplier(owner) : 1)
      const state = createRun(scale, Math.random)
      const run = await tx.dungeonRun.create({
        data: {
          characterId,
          dungeonId: DESCENT_DUNGEON_ID,
          difficulty: 'rush',
          currentFloor: 1,
          seed: Math.floor(Math.random() * 2147483647),
          state: serializeState(state),
        },
      })
      return { resumed: false, runId: run.id, state, staminaLeft: stamina.stamina - DESCENT.STAMINA_COST }
    })

    return NextResponse.json({
      resumed: result.resumed,
      stamina_cost: DESCENT.STAMINA_COST,
      current_stamina: 'staminaLeft' in result ? result.staminaLeft : null,
      view: buildDescentView(result.runId, result.state),
    }, { status: result.resumed ? 200 : 201 })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND' || error.message === 'FORBIDDEN') {
        return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      }
      if (error.message.startsWith('STAMINA:')) {
        return NextResponse.json({ error: error.message.slice(8), code: 'NO_STAMINA' }, { status: 400 })
      }
    }
    console.error('dungeon rush v2 start error:', error)
    return NextResponse.json({ error: 'Failed to start the descent' }, { status: 500 })
  }
}
