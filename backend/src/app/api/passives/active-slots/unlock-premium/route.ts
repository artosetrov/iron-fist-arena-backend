import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { PASSIVES } from '@/lib/game/balance'
import { invalidateActiveSlotsCache } from '@/lib/game/active-slots'

// Unlock the 4th (premium) active-skill slot for a character.
// Flat gem cost — `PASSIVES.PREMIUM_ACTIVE_SLOT_GEM_COST`.
//
// POST /api/passives/active-slots/unlock-premium
// Body: { character_id }
// Response: { success, gems, max_slots }
//
// Rules:
// - Character must belong to the caller.
// - activeSlotCount must currently equal BASE_ACTIVE_SLOTS (no-op if already maxed).
// - Gems checked + deducted inside a transaction with FOR UPDATE lock on the user row
//   to prevent TOCTOU double-spend.
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`active-slots-unlock-premium:${user.id}`, 5, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id } = body as { character_id?: string }
    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const result = await prisma.$transaction(async (tx) => {
      const [userRow] = await tx.$queryRawUnsafe<Array<{ id: string; gems: number }>>(
        `SELECT id, gems FROM users WHERE id = $1 FOR UPDATE`,
        user.id,
      )
      if (!userRow) throw new Error('USER_NOT_FOUND')
      if (userRow.gems < PASSIVES.PREMIUM_ACTIVE_SLOT_GEM_COST) throw new Error('NOT_ENOUGH_GEMS')

      const [charRow] = await tx.$queryRawUnsafe<Array<{
        id: string
        user_id: string
        active_slot_count: number
      }>>(
        `SELECT id, user_id, active_slot_count FROM characters WHERE id = $1 FOR UPDATE`,
        character_id,
      )
      if (!charRow) throw new Error('NOT_FOUND')
      if (charRow.user_id !== user.id) throw new Error('FORBIDDEN')
      if (charRow.active_slot_count >= PASSIVES.MAX_ACTIVE_SLOTS) throw new Error('ALREADY_MAX')
      if (charRow.active_slot_count !== PASSIVES.BASE_ACTIVE_SLOTS) {
        // Defensive: any non-base non-max value means someone tampered directly
        // with the column. Refuse rather than silently adding a slot.
        throw new Error('UNEXPECTED_STATE')
      }

      const updatedUser = await tx.user.update({
        where: { id: user.id },
        data: { gems: { decrement: PASSIVES.PREMIUM_ACTIVE_SLOT_GEM_COST } },
      })
      const updatedChar = await tx.character.update({
        where: { id: character_id },
        data: { activeSlotCount: { increment: 1 } },
      })

      return { gems: updatedUser.gems, maxSlots: updatedChar.activeSlotCount }
    })

    await invalidateActiveSlotsCache(character_id)
    return NextResponse.json({
      success: true,
      gems: result.gems,
      max_slots: result.maxSlots,
    })
  } catch (error) {
    if (error instanceof Error) {
      const map: Record<string, { msg: string; status: number }> = {
        USER_NOT_FOUND: { msg: 'User not found', status: 404 },
        NOT_FOUND: { msg: 'Character not found', status: 404 },
        FORBIDDEN: { msg: 'Forbidden', status: 403 },
        NOT_ENOUGH_GEMS: { msg: 'Not enough gems', status: 400 },
        ALREADY_MAX: { msg: 'Maximum active slots already reached', status: 400 },
        UNEXPECTED_STATE: { msg: 'Character slot count is in an unexpected state', status: 409 },
      }
      const mapped = map[error.message]
      if (mapped) return NextResponse.json({ error: mapped.msg }, { status: mapped.status })
    }
    console.error('active-slots unlock-premium error:', error)
    return NextResponse.json({ error: 'Failed to unlock premium slot' }, { status: 500 })
  }
}
