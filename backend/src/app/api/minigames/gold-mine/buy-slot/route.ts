import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { buildSlotsArray, MAX_GOLD_MINE_SLOTS, SLOT_COST_GEMS } from '@/lib/game/gold-mine'
import { rateLimit } from '@/lib/rate-limit'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`gold-mine-buy-slot:${user.id}`, 5, 10_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    // Use interactive transaction with row-level lock to prevent TOCTOU
    const result = await prisma.$transaction(async (tx) => {
      // Lock the user row for update (gems balance)
      const [userRow] = await tx.$queryRawUnsafe<Array<{ id: string; gems: number }>>(
        `SELECT id, gems FROM users WHERE id = $1 FOR UPDATE`,
        user.id
      )

      if (!userRow) throw new Error('USER_NOT_FOUND')
      if (userRow.gems < SLOT_COST_GEMS) throw new Error('NOT_ENOUGH_GEMS')

      // Lock the character row for update (goldMineSlots)
      const [charRow] = await tx.$queryRawUnsafe<Array<{ id: string; user_id: string; gold_mine_slots: number }>>(
        `SELECT id, user_id, gold_mine_slots FROM characters WHERE id = $1 FOR UPDATE`,
        character_id
      )

      if (!charRow) throw new Error('NOT_FOUND')
      if (charRow.user_id !== user.id) throw new Error('FORBIDDEN')
      if (charRow.gold_mine_slots >= MAX_GOLD_MINE_SLOTS) throw new Error('MAX_SLOTS')

      const updatedUser = await tx.user.update({
        where: { id: user.id },
        data: { gems: { decrement: SLOT_COST_GEMS } },
      })

      const updatedCharacter = await tx.character.update({
        where: { id: character_id },
        data: { goldMineSlots: { increment: 1 } },
      })

      return { updatedUser, updatedCharacter }
    })

    const slots = await buildSlotsArray(prisma, character_id, result.updatedCharacter.goldMineSlots)

    return NextResponse.json({
      slots,
      max_slots: result.updatedCharacter.goldMineSlots,
      gems: result.updatedUser.gems,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'USER_NOT_FOUND') return NextResponse.json({ error: 'User not found' }, { status: 404 })
      if (error.message === 'NOT_ENOUGH_GEMS') return NextResponse.json({ error: 'Not enough gems' }, { status: 400 })
      if (error.message === 'MAX_SLOTS') return NextResponse.json({ error: `Maximum gold mine slots (${MAX_GOLD_MINE_SLOTS}) already reached` }, { status: 400 })
    }
    console.error('gold-mine buy-slot error:', error)
    return NextResponse.json({ error: 'Failed to buy gold mine slot' }, { status: 500 })
  }
}
