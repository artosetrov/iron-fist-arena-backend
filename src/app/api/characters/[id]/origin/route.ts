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

    // Use interactive transaction with row-level lock to prevent TOCTOU
    const updated = await prisma.$transaction(async (tx) => {
      // Lock the character row for update
      const [charRow] = await tx.$queryRawUnsafe<Array<{
        id: string; user_id: string; gold: number; origin: string; current_hp: number;
        str: number; agi: number; vit: number; end: number; int: number; wis: number; luk: number; cha: number;
      }>>(
        `SELECT id, user_id, gold, origin, current_hp, str, agi, vit, "end", "int", wis, luk, cha FROM characters WHERE id = $1 FOR UPDATE`,
        id
      )

      if (!charRow) throw new Error('NOT_FOUND')
      if (charRow.user_id !== user.id) throw new Error('FORBIDDEN')
      if (charRow.origin === origin) throw new Error('SAME_ORIGIN')
      if (charRow.gold < ORIGIN_CHANGE_COST) throw new Error('NOT_ENOUGH_GOLD')

      // Remove old origin bonuses and apply new ones
      const oldBonuses = ORIGIN_BONUSES[charRow.origin as CharacterOrigin]
      const newBonuses = ORIGIN_BONUSES[origin as CharacterOrigin]

      const newStats: Record<string, number> = {}
      for (const key of STAT_KEYS) {
        newStats[key] = charRow[key] - (oldBonuses[key] ?? 0) + (newBonuses[key] ?? 0)
      }

      const maxHp = calculateMaxHp(newStats.vit, newStats.end)

      return tx.character.update({
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
          currentHp: Math.min(charRow.current_hp, maxHp),
          gold: { decrement: ORIGIN_CHANGE_COST },
        },
      })
    })

    return NextResponse.json({ character: updated })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'SAME_ORIGIN') return NextResponse.json({ error: 'Character already has this origin' }, { status: 400 })
      if (error.message === 'NOT_ENOUGH_GOLD') return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
    }
    console.error('origin change error:', error)
    return NextResponse.json(
      { error: 'Failed to change origin' },
      { status: 500 }
    )
  }
}
