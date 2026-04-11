// =============================================================================
// POST /api/battle-pass/weekly-challenges/claim
// Body: { character_id: string, slot_index: number }
// =============================================================================
//
// Claim a completed weekly BP challenge. Awards BP XP through the canonical
// awardBattlePassXp() pipeline (same path as dailies + PvP + dungeons) so BP
// level-ups propagate through the existing reward-unlock chain.
//
// Idempotent: claiming an already-claimed slot returns 400 without mutating.
// Race-safe: transaction + WHERE claimed=false on the UPDATE.

import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { awardBattlePassXp } from '@/lib/game/battle-pass'
import { isoWeekOf } from '@/lib/game/weekly-challenges'
import { rateLimit } from '@/lib/rate-limit'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const ok = await rateLimit(`weekly-claim:${user.id}`, 10, 60_000)
  if (!ok) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  let body: { character_id?: string; slot_index?: number }
  try {
    body = await req.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 })
  }

  const characterId = body.character_id
  const slotIndex = body.slot_index
  if (!characterId || typeof slotIndex !== 'number' || !Number.isInteger(slotIndex)) {
    return NextResponse.json(
      { error: 'character_id and slot_index are required' },
      { status: 400 },
    )
  }

  try {
    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { userId: true },
    })
    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const isoWeek = isoWeekOf()

    const result = await prisma.$transaction(async (tx) => {
      const row = await tx.weeklyChallengeProgress.findUnique({
        where: {
          characterId_isoWeek_slotIndex: {
            characterId,
            isoWeek,
            slotIndex,
          },
        },
      })

      if (!row) {
        return { error: 'Challenge not found', status: 404 as const }
      }
      if (row.claimed) {
        return { error: 'Already claimed', status: 400 as const }
      }
      if (row.progress < row.goalTarget) {
        return { error: 'Challenge not completed', status: 400 as const }
      }

      // Atomic claim — bail if someone else claimed between findUnique and now.
      const updated = await tx.weeklyChallengeProgress.updateMany({
        where: {
          characterId,
          isoWeek,
          slotIndex,
          claimed: false,
        },
        data: { claimed: true },
      })
      if (updated.count === 0) {
        return { error: 'Already claimed', status: 400 as const }
      }

      // Route XP through canonical BP pipeline (includes level-up detection).
      await awardBattlePassXp(tx, characterId, row.bpXpAward)

      return { bpXp: row.bpXpAward, status: 200 as const }
    })

    if ('error' in result) {
      return NextResponse.json({ error: result.error }, { status: result.status })
    }

    return NextResponse.json({
      success: true,
      iso_week: isoWeek,
      slot_index: slotIndex,
      bp_xp_awarded: result.bpXp,
    })
  } catch (error) {
    console.error('claim weekly challenge error:', error)
    return NextResponse.json(
      { error: 'Failed to claim challenge' },
      { status: 500 },
    )
  }
}
