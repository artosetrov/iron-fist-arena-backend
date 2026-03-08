import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { calculateCurrentStamina } from '@/lib/game/stamina'

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const { id } = await params

    const [character, dbUser] = await Promise.all([
      prisma.character.findUnique({
        where: { id },
        include: {
          equipment: { include: { item: true } },
          consumables: true,
        },
      }),
      prisma.user.findUnique({ where: { id: user.id }, select: { gems: true } }),
    ])

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Compute current stamina without writing to DB
    const staminaResult = calculateCurrentStamina(
      character.currentStamina,
      character.maxStamina,
      character.lastStaminaUpdate
    )

    return NextResponse.json({
      character: {
        ...character,
        currentStamina: staminaResult.stamina,
        gems: dbUser?.gems ?? 0,
      },
    })
  } catch (error) {
    console.error('get character error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch character' },
      { status: 500 }
    )
  }
}
