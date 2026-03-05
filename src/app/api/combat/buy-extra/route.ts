import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'

const EXTRA_PVP_GEM_COST = 50
const EXTRA_PVP_STAMINA = 5

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

    // Load character and user in parallel
    const [character, dbUser] = await Promise.all([
      prisma.character.findUnique({ where: { id: character_id } }),
      prisma.user.findUnique({ where: { id: user.id } }),
    ])

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    if (!dbUser) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    if (dbUser.gems < EXTRA_PVP_GEM_COST) {
      return NextResponse.json(
        {
          error: 'Not enough gems',
          gemsRequired: EXTRA_PVP_GEM_COST,
          gemsAvailable: dbUser.gems,
        },
        { status: 400 }
      )
    }

    // Deduct gems from user and add stamina to character in a transaction
    const [updatedUser, updatedCharacter] = await prisma.$transaction([
      prisma.user.update({
        where: { id: user.id },
        data: { gems: { decrement: EXTRA_PVP_GEM_COST } },
      }),
      prisma.character.update({
        where: { id: character_id },
        data: {
          currentStamina: {
            increment: EXTRA_PVP_STAMINA,
          },
          lastStaminaUpdate: new Date(),
        },
      }),
    ])

    return NextResponse.json({
      success: true,
      gemsSpent: EXTRA_PVP_GEM_COST,
      gemsRemaining: updatedUser.gems,
      stamina: {
        current: updatedCharacter.currentStamina,
        max: updatedCharacter.maxStamina,
        added: EXTRA_PVP_STAMINA,
      },
    })
  } catch (error) {
    console.error('buy extra pvp error:', error)
    return NextResponse.json(
      { error: 'Failed to purchase extra fights' },
      { status: 500 }
    )
  }
}
