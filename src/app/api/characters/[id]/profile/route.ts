import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params

    // Note: avoid explicit select with 'class' field (reserved SQL keyword, no @map)
    const raw = await prisma.character.findUnique({
      where: { id },
    })

    if (!raw) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    const character = {
      id: raw.id,
      characterName: raw.characterName,
      class: raw.class,
      origin: raw.origin,
      level: raw.level,
      pvpRating: raw.pvpRating,
      pvpWins: raw.pvpWins,
      pvpLosses: raw.pvpLosses,
      prestigeLevel: raw.prestigeLevel,
    }

    return NextResponse.json({ profile: character })
  } catch (error) {
    console.error('public profile error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch profile' },
      { status: 500 }
    )
  }
}
