/**
 * POST /api/minigames/gold-mine/collect-all
 *
 * Drains every READY gold-mine slot in one transaction (2026-10-16 rework):
 *   - The bonus round is optional — played or not, a ready cart is paid.
 *   - No shaft picker: with no running expedition one starts on its own
 *     (`picked_shaft_key` is still honoured when sent and unlocked).
 *   - Every cart drained is one expedition haul (same as collecting it on its
 *     own); the 5th opens the expedition chest and the next expedition
 *     starts right away, extra carts carrying over (gold-mine-expedition.ts).
 *
 * Request body:
 *   { character_id: string, picked_shaft_key?: 'stone' | 'ice' }
 *
 * Response shape (success):
 *   {
 *     slots: SlotInfo[],
 *     gold_collected: number,          // carts only
 *     gems_collected: number,
 *     gold: number,                    // balances after carts + chest
 *     gems: number,
 *     active_shaft: { key, progress, total, ... },
 *     expedition_chest: { gold, gems, shaft_key } | null,
 *     unplayed_ready_slot_indices: [],  // kept for older clients
 *   }
 *
 * Server-authoritative — client never calculates gold, gems or progress.
 */

import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { buildSlotsArray } from '@/lib/game/gold-mine'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'
import { isValidShaftKey } from '@/lib/game/shaft-catalog'
import {
  activeShaftJson,
  advanceExpedition,
  chestJson,
} from '@/lib/game/gold-mine-expedition'

interface CollectAllBody {
  character_id?: string
  picked_shaft_key?: string
}

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = (await req.json()) as CollectAllBody
    const { character_id, picked_shaft_key } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }
    if (picked_shaft_key !== undefined && !isValidShaftKey(picked_shaft_key)) {
      return NextResponse.json({ error: 'Invalid shaft key' }, { status: 400 })
    }

    const result = await prisma.$transaction(async (tx) => {
      // Serialise collects of one character: the expedition counter below is
      // read-modify-write, so two collects at 4/5 must not both pay the chest.
      await tx.$queryRawUnsafe(`SELECT id FROM characters WHERE id = $1 FOR UPDATE`, character_id)

      const character = await tx.character.findUnique({
        where: { id: character_id },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Lock every ready, uncollected session of this character.
      const now = new Date()
      const readySessions = await tx.$queryRawUnsafe<
        Array<{ id: string; reward: number; gem_reward: number }>
      >(
        `SELECT id, reward, gem_reward
           FROM gold_mine_sessions
          WHERE character_id = $1
            AND collected = false
            AND ends_at <= $2
          FOR UPDATE`,
        character_id,
        now
      )

      if (readySessions.length === 0) {
        throw new Error('NO_READY_SLOTS')
      }

      const gold = readySessions.reduce((sum, s) => sum + s.reward, 0)
      const gems = readySessions.reduce((sum, s) => sum + s.gem_reward, 0)

      await tx.goldMineSession.updateMany({
        where: { id: { in: readySessions.map((s) => s.id) } },
        data: { collected: true },
      })

      await tx.user.update({
        where: { id: user.id },
        data: { gold: { increment: gold }, gems: { increment: gems } },
      })

      // One haul per cart — the same count as collecting them one by one.
      const expedition = await advanceExpedition(
        tx,
        character,
        picked_shaft_key,
        readySessions.length
      )

      const balances = await tx.user.findUniqueOrThrow({
        where: { id: user.id },
        select: { gold: true, gems: true },
      })

      return { character, gold, gems, expedition, balances, carts: readySessions.length }
    })

    // Quest progress — one per cart, like collecting them one by one
    // (outside the transaction, non-critical).
    await Promise.all([
      updateDailyQuestProgress(prisma, character_id, 'gold_mine_collect', result.carts),
      updateWeeklyChallengeProgress(prisma, character_id, 'gold_mine_collect', result.carts),
    ])

    const slots = await buildSlotsArray(
      prisma,
      character_id,
      result.character.goldMineSlots,
      true
    )
    const { expedition } = result

    return NextResponse.json({
      slots,
      gold_collected: result.gold,
      gems_collected: result.gems,
      gold: result.balances.gold,
      gems: result.balances.gems,
      active_shaft: activeShaftJson(
        expedition.activeShaftKey,
        expedition.shaftProgress,
        expedition.shaftTotal
      ),
      expedition_chest: chestJson(expedition.chest),
      unplayed_ready_slot_indices: [],
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') {
        return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      }
      if (error.message === 'FORBIDDEN') {
        return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      }
      if (error.message === 'NO_READY_SLOTS') {
        return NextResponse.json(
          { error: 'No ready slots to collect' },
          { status: 400 }
        )
      }
    }
    console.error('gold-mine collect-all error:', error)
    return NextResponse.json(
      { error: 'Failed to collect gold mine rewards' },
      { status: 500 }
    )
  }
}
