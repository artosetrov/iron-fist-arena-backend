import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { logTutorialEvent } from '@/lib/game/tutorial-analytics'

/**
 * POST /api/tutorial/step
 * Advance tutorial step: 1→2 (weapon equipped), 2→3 (first fight won → tutorial complete).
 * Body: { character_id, step }
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`tutorial-step:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, step } = body

    if (!character_id || typeof step !== 'number') {
      return NextResponse.json({ error: 'character_id and step are required' }, { status: 400 })
    }

    if (step < 1 || step > 3) {
      return NextResponse.json({ error: 'Invalid step (must be 1-3)' }, { status: 400 })
    }

    const result = await prisma.$transaction(async (tx) => {
      const [character] = await tx.$queryRawUnsafe<
        Array<{ id: string; user_id: string; tutorial_step: number }>
      >(
        `SELECT id, user_id, tutorial_step FROM characters WHERE id = $1 FOR UPDATE`,
        character_id
      )

      if (!character) throw new Error('NOT_FOUND')
      if (character.user_id !== user.id) throw new Error('FORBIDDEN')

      // Step must advance sequentially (no skipping, no going back)
      if (step !== character.tutorial_step + 1) {
        throw new Error('INVALID_STEP_SEQUENCE')
      }

      const updated = await tx.character.update({
        where: { id: character_id },
        data: { tutorialStep: step },
        select: { tutorialStep: true },
      })

      return updated
    })

    logTutorialEvent({
      event: 'tutorial_step',
      characterId: character_id,
      step,
      completed: result.tutorialStep >= 3,
    })

    return NextResponse.json({
      tutorialStep: result.tutorialStep,
      completed: result.tutorialStep >= 3,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'INVALID_STEP_SEQUENCE') return NextResponse.json({ error: 'Invalid step sequence' }, { status: 400 })
    }
    console.error('tutorial step error:', error)
    return NextResponse.json({ error: 'Failed to advance tutorial' }, { status: 500 })
  }
}
