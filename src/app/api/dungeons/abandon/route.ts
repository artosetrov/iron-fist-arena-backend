import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findFirst({
      where: { id: character_id, userId: user.id },
    })
    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    // Find and delete any active non-rush dungeon run
    const run = await prisma.dungeonRun.findFirst({
      where: {
        characterId: character_id,
        difficulty: { not: 'rush' },
      },
    })

    if (!run) {
      return NextResponse.json({ error: 'No active dungeon run to abandon' }, { status: 404 })
    }

    await prisma.dungeonRun.delete({ where: { id: run.id } })

    return NextResponse.json({ success: true, message: 'Dungeon run abandoned' })
  } catch (error) {
    console.error('abandon dungeon error:', error)
    return NextResponse.json({ error: 'Failed to abandon dungeon' }, { status: 500 })
  }
}
