import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/consumables?character_id=xxx
 * Returns all consumables for the character.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const consumables = await prisma.consumableInventory.findMany({
      where: { characterId },
      orderBy: { consumableType: 'asc' },
    })

    return NextResponse.json({ consumables })
  } catch (error) {
    console.error('get consumables error:', error)
    return NextResponse.json({ error: 'Failed to fetch consumables' }, { status: 500 })
  }
}
