import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { CharacterOrigin } from '@prisma/client'

const ORIGIN_CHANGE_COST = 100

const ORIGIN_BONUSES: Record<CharacterOrigin, Partial<Record<string, number>>> = {
  human:    { cha: 2, wis: 1 },
  orc:      { str: 3, int: -1 },
  skeleton: { end: 2, agi: 1 },
  demon:    { int: 2, wis: 2, cha: -1 },
  dogfolk:  { agi: 2, luk: 1 },
}

const STAT_KEYS = ['str', 'agi', 'vit', 'end', 'int', 'wis', 'luk', 'cha'] as const

function calculateMaxHp(vit: number, end: number): number {
  return 80 + vit * 5 + end * 3
}

export async function PATCH(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const { id } = await params
    const { origin } = await req.json()

    if (!origin) {
      return NextResponse.json(
        { error: 'origin is required' },
        { status: 400 }
      )
    }

    if (!Object.values(CharacterOrigin).includes(origin)) {
      return NextResponse.json(
        { error: `Invalid origin. Must be one of: ${Object.values(CharacterOrigin).join(', ')}` },
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

    if (character.origin === origin) {
      return NextResponse.json(
        { error: 'Character already has this origin' },
        { status: 400 }
      )
    }

    if (character.gold < ORIGIN_CHANGE_COST) {
      return NextResponse.json(
        { error: `Not enough gold. Required: ${ORIGIN_CHANGE_COST}, Current: ${character.gold}` },
        { status: 400 }
      )
    }

    // Remove old origin bonuses and apply new ones
    const oldBonuses = ORIGIN_BONUSES[character.origin]
    const newBonuses = ORIGIN_BONUSES[origin as CharacterOrigin]

    const newStats: Record<string, number> = {}
    for (const key of STAT_KEYS) {
      newStats[key] = character[key] - (oldBonuses[key] ?? 0) + (newBonuses[key] ?? 0)
    }

    const maxHp = calculateMaxHp(newStats.vit, newStats.end)

    const updated = await prisma.character.update({
      where: { id },
      data: {
        origin: origin as CharacterOrigin,
        str: newStats.str,
        agi: newStats.agi,
        vit: newStats.vit,
        end: newStats.end,
        int: newStats.int,
        wis: newStats.wis,
        luk: newStats.luk,
        cha: newStats.cha,
        maxHp,
        currentHp: Math.min(character.currentHp, maxHp),
        gold: character.gold - ORIGIN_CHANGE_COST,
      },
    })

    return NextResponse.json({ character: updated })
  } catch (error) {
    console.error('origin change error:', error)
    return NextResponse.json(
      { error: 'Failed to change origin' },
      { status: 500 }
    )
  }
}
