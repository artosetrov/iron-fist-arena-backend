import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { STANCE_ZONES } from '@/lib/game/balance'

export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const { id } = await params
    const { stance } = await req.json()

    if (stance === undefined || stance === null) {
      return NextResponse.json(
        { error: 'stance is required' },
        { status: 400 }
      )
    }

    // Validate stance structure — zone-based
    const validZones: readonly string[] = STANCE_ZONES.VALID_ZONES

    if (
      typeof stance !== 'object' ||
      typeof stance.attack !== 'string' ||
      typeof stance.defense !== 'string'
    ) {
      return NextResponse.json(
        { error: 'stance must have attack and defense string properties' },
        { status: 400 }
      )
    }

    if (!validZones.includes(stance.attack) || !validZones.includes(stance.defense)) {
      return NextResponse.json(
        { error: 'attack and defense must be one of: head, chest, legs' },
        { status: 400 }
      )
    }

    const character = await prisma.character.findUnique({ where: { id } })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const updated = await prisma.character.update({
      where: { id },
      data: { combatStance: stance },
    })

    return NextResponse.json({ character: updated })
  } catch (error) {
    console.error('stance error:', error)
    return NextResponse.json(
      { error: 'Failed to update stance' },
      { status: 500 }
    )
  }
}
