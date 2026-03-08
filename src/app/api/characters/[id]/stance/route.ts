import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

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

    // Validate stance structure
    if (
      typeof stance !== 'object' ||
      typeof stance.offense !== 'number' ||
      typeof stance.defense !== 'number'
    ) {
      return NextResponse.json(
        { error: 'stance must have numeric offense and defense properties' },
        { status: 400 }
      )
    }

    if (stance.offense < 0 || stance.offense > 100 || stance.defense < 0 || stance.defense > 100) {
      return NextResponse.json(
        { error: 'offense and defense must be between 0 and 100' },
        { status: 400 }
      )
    }

    const total = stance.offense + stance.defense
    if (total < 95 || total > 105) {
      return NextResponse.json(
        { error: 'offense + defense must sum to approximately 100' },
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
