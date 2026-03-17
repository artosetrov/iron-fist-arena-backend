import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { getGemCostsConfig, getExtraPvpConfig } from '@/lib/game/live-config'
import { calculateCurrentStamina } from '@/lib/game/stamina'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`buy-extra:${user.id}`, 5, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const [GEM_COSTS, EXTRA_PVP] = await Promise.all([
      getGemCostsConfig(),
      getExtraPvpConfig(),
    ])
    const EXTRA_PVP_GEM_COST = GEM_COSTS.EXTRA_PVP_COMBAT
    const EXTRA_PVP_STAMINA = EXTRA_PVP.STAMINA_GRANTED

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

      const [character] = await tx.$queryRawUnsafe<Array<{
        id: string
        user_id: string
        current_stamina: number
        max_stamina: number
        last_stamina_update: Date | null
      }>>(
        `SELECT id, user_id, current_stamina, max_stamina, last_stamina_update
         FROM characters
         WHERE id = $1
         FOR UPDATE`,
        character_id
      )

      if (!character) throw new Error('NOT_FOUND')
      if (character.user_id !== user.id) throw new Error('FORBIDDEN')

      const staminaResult = await calculateCurrentStamina(
        character.current_stamina,
        character.max_stamina,
        character.last_stamina_update ?? new Date()
      )
      if (staminaResult.stamina >= character.max_stamina) throw new Error('STAMINA_FULL')
      const nextStamina = Math.min(
        staminaResult.stamina + EXTRA_PVP_STAMINA,
        character.max_stamina
      )
      const staminaAdded = nextStamina - staminaResult.stamina

      const updatedUser = await tx.user.update({
        where: { id: user.id },
        data: { gems: { decrement: EXTRA_PVP_GEM_COST } },
      })

      const updatedCharacter = await tx.character.update({
        where: { id: character_id },
        data: {
          currentStamina: nextStamina,
          lastStaminaUpdate: new Date(),
        },
      })

      return { updatedUser, updatedCharacter, staminaAdded }
    })

    return NextResponse.json({
      success: true,
      gemsSpent: EXTRA_PVP_GEM_COST,
      gemsRemaining: result.updatedUser.gems,
      gems: result.updatedUser.gems,
      stamina: {
        current: result.updatedCharacter.currentStamina,
        max: result.updatedCharacter.maxStamina,
        added: result.staminaAdded,
      },
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'USER_NOT_FOUND') return NextResponse.json({ error: 'User not found' }, { status: 404 })
      if (error.message === 'NOT_ENOUGH_GEMS') return NextResponse.json({ error: 'Not enough gems' }, { status: 400 })
      if (error.message === 'STAMINA_FULL') return NextResponse.json({ error: 'Stamina is already full' }, { status: 400 })
    }
    console.error('buy extra pvp error:', error)
    return NextResponse.json(
      { error: 'Failed to purchase extra fights' },
      { status: 500 }
    )
  }
}
