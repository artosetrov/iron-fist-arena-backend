import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { getStaminaConfig } from '@/lib/game/live-config'

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const STAMINA = await getStaminaConfig()

    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json(
        { error: 'character_id is required' },
        { status: 400 }
      )
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

    const lastUpdate = character.lastStaminaUpdate ?? new Date()
    const result = await calculateCurrentStamina(
      character.currentStamina,
      character.maxStamina,
      lastUpdate
    )

    const now = new Date()

    if (result.updated) {
      await prisma.character.update({
        where: { id: characterId },
        data: {
          currentStamina: result.stamina,
          lastStaminaUpdate: now,
        },
      })
    }

    // Calculate next regen time
    let nextRegenAt: string | null = null
    if (result.stamina < character.maxStamina) {
      const regenMs = STAMINA.REGEN_INTERVAL_MINUTES * 60 * 1000
      const baseTime = result.updated ? now : lastUpdate
      const elapsed = now.getTime() - baseTime.getTime()
      const remainder = elapsed % regenMs
      const msUntilNext = regenMs - remainder
      nextRegenAt = new Date(now.getTime() + msUntilNext).toISOString()
    }

    return NextResponse.json({
      currentStamina: result.stamina,
      maxStamina: character.maxStamina,
      nextRegenAt,
    })
  } catch (error) {
    console.error('stamina error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch stamina' },
      { status: 500 }
    )
  }
}
