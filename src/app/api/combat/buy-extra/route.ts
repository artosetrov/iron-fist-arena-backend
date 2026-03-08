import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { GEM_COSTS, EXTRA_PVP } from '@/lib/game/balance'

const EXTRA_PVP_GEM_COST = GEM_COSTS.EXTRA_PVP_COMBAT
const EXTRA_PVP_STAMINA = EXTRA_PVP.STAMINA_GRANTED

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`buy-extra:${user.id}`, 5, 60_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json(
        { error: 'character_id is required' },
        { status: 400 }
      )
    }

    // Use interactive transaction with row-level lock to prevent TOCTOU
    const result = await prisma.$transaction(async (tx) => {
      // Lock the user row for update (gems balance)
      const [userRow] = await tx.$queryRawUnsafe<Array<{ id: string; gems: number }>>(
        `SELECT id, gems FROM users WHERE id = $1 FOR UPDATE`,
        user.id
      )

      if (!userRow) throw new Error('USER_NOT_FOUND')
      if (userRow.gems < EXTRA_PVP_GEM_COST) throw new Error('NOT_ENOUGH_GEMS')

      // Verify character ownership
      const character = await tx.character.findUnique({
        where: { id: character_id },
      })

      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      const updatedUser = await tx.user.update({
        where: { id: user.id },
        data: { gems: { decrement: EXTRA_PVP_GEM_COST } },
      })

      const updatedCharacter = await tx.character.update({
        where: { id: character_id },
        data: {
          currentStamina: {
            increment: EXTRA_PVP_STAMINA,
          },
          lastStaminaUpdate: new Date(),
        },
      })

      return { updatedUser, updatedCharacter }
    })

    return NextResponse.json({
      success: true,
      gemsSpent: EXTRA_PVP_GEM_COST,
      gemsRemaining: result.updatedUser.gems,
      stamina: {
        current: result.updatedCharacter.currentStamina,
        max: result.updatedCharacter.maxStamina,
        added: EXTRA_PVP_STAMINA,
      },
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'USER_NOT_FOUND') return NextResponse.json({ error: 'User not found' }, { status: 404 })
      if (error.message === 'NOT_ENOUGH_GEMS') return NextResponse.json({ error: 'Not enough gems' }, { status: 400 })
    }
    console.error('buy extra pvp error:', error)
    return NextResponse.json(
      { error: 'Failed to purchase extra fights' },
      { status: 500 }
    )
  }
}
