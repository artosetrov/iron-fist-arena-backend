import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { STAMINA } from '@/lib/game/balance'

const GEMS_PER_REFILL = 30

/**
 * POST /api/stamina/refill
 * Body: { character_id }
 * Fully restores stamina for GEMS_PER_REFILL gems.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`stamina-refill:${user.id}`, 5, 10_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
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

    // Calculate current stamina with regen
    const staminaResult = calculateCurrentStamina(
      character.currentStamina,
      character.maxStamina,
      character.lastStaminaUpdate ?? new Date()
    )

    if (staminaResult.stamina >= STAMINA.MAX) {
      return NextResponse.json({ error: 'Stamina is already full' }, { status: 400 })
    }

    // Check gems on user record
    const userRecord = await prisma.user.findUnique({ where: { id: user.id } })
    if (!userRecord || userRecord.gems < GEMS_PER_REFILL) {
      return NextResponse.json(
        { error: 'Not enough gems', required: GEMS_PER_REFILL, current: userRecord?.gems ?? 0 },
        { status: 400 }
      )
    }

    const now = new Date()

    await prisma.$transaction([
      prisma.user.update({
        where: { id: user.id },
        data: { gems: { decrement: GEMS_PER_REFILL } },
      }),
      prisma.character.update({
        where: { id: character_id },
        data: {
          currentStamina: STAMINA.MAX,
          lastStaminaUpdate: now,
        },
      }),
    ])

    return NextResponse.json({
      stamina: {
        before: staminaResult.stamina,
        after: STAMINA.MAX,
        max: STAMINA.MAX,
      },
      gems_spent: GEMS_PER_REFILL,
      gems_remaining: userRecord.gems - GEMS_PER_REFILL,
    })
  } catch (error) {
    console.error('stamina refill error:', error)
    return NextResponse.json({ error: 'Failed to refill stamina' }, { status: 500 })
  }
}
