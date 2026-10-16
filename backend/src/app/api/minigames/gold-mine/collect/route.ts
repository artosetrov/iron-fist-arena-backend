/**
 * POST /api/minigames/gold-mine/collect
 *
 * Drains a single ready slot. The bonus round is optional (2026-10-16): a
 * ready cart can be collected whether or not its bonus was played; a bonus
 * not played by then is simply forfeited. Each collect is one expedition
 * haul — the 5th opens the expedition chest (see gold-mine-expedition.ts).
 *
 * Request body:
 *   { character_id: string, slot_index: number }
 *
 * Response shape (success):
 *   {
 *     slots: SlotInfo[],
 *     gold_collected: number,          // the haul only
 *     gems_collected: number,
 *     gold: number,                    // balances after haul + chest
 *     gems: number,
 *     active_shaft: { key, progress, total, ... },
 *     expedition_chest: { gold, gems, shaft_key } | null,
 *   }
 */

import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { buildSlotsArray } from '@/lib/game/gold-mine'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'
import {
  activeShaftJson,
  advanceExpedition,
  chestJson,
} from '@/lib/game/gold-mine-expedition'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, slot_index } = body

    if (!character_id || slot_index == null) {
      return NextResponse.json(
        { error: 'character_id and slot_index are required' },
        { status: 400 }
      )
    }

    // Use interactive transaction with row-level lock to prevent double-collect
    const result = await prisma.$transaction(async (tx) => {
      // Serialise collects of one character: the expedition counter below is
      // read-modify-write, so two collects at 4/5 must not both pay the chest.
      await tx.$queryRawUnsafe(`SELECT id FROM characters WHERE id = $1 FOR UPDATE`, character_id)

      // Verify character ownership
      const character = await tx.character.findUnique({
        where: { id: character_id },
      })

      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Lock the session row for update to prevent double-collect.
      const [sessionRow] = await tx.$queryRawUnsafe<
        Array<{
          id: string
          collected: boolean
          reward: number
          gem_reward: number
          ends_at: Date
        }>
      >(
        `SELECT id, collected, reward, gem_reward, ends_at
           FROM gold_mine_sessions
          WHERE character_id = $1
            AND slot_index = $2
            AND collected = false
          FOR UPDATE`,
        character_id,
        slot_index
      )

      if (!sessionRow) throw new Error('NO_SESSION')

      const now = new Date()
      if (now < sessionRow.ends_at) throw new Error('NOT_READY')

      // Mark collected
      await tx.goldMineSession.update({
        where: { id: sessionRow.id },
        data: { collected: true },
      })

      // Credit the haul
      await tx.user.update({
        where: { id: user.id },
        data: {
          gold: { increment: sessionRow.reward },
          gems: { increment: sessionRow.gem_reward },
        },
      })

      // One haul on the expedition; the last one also credits the chest.
      const expedition = await advanceExpedition(tx, character)

      const balances = await tx.user.findUniqueOrThrow({
        where: { id: user.id },
        select: { gold: true, gems: true },
      })

      return {
        balances,
        reward: sessionRow.reward,
        gemReward: sessionRow.gem_reward,
        goldMineSlots: character.goldMineSlots,
        expedition,
      }
    })

    // Update daily + weekly quest progress (outside transaction, non-critical)
    await Promise.all([
      updateDailyQuestProgress(prisma, character_id, 'gold_mine_collect'),
      // W3.D5 — Weekly BP challenge: Prospector slot
      updateWeeklyChallengeProgress(prisma, character_id, 'gold_mine_collect'),
    ])

    const slots = await buildSlotsArray(prisma, character_id, result.goldMineSlots, true)
    const { expedition } = result

    return NextResponse.json({
      slots,
      gold_collected: result.reward,
      gems_collected: result.gemReward,
      gold: result.balances.gold,
      gems: result.balances.gems,
      active_shaft: activeShaftJson(
        expedition.activeShaftKey,
        expedition.shaftProgress,
        expedition.shaftTotal
      ),
      expedition_chest: chestJson(expedition.chest),
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND')
        return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN')
        return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'NO_SESSION')
        return NextResponse.json(
          { error: 'No active session for this slot' },
          { status: 404 }
        )
      if (error.message === 'NOT_READY')
        return NextResponse.json(
          { error: 'Mining session not yet complete' },
          { status: 400 }
        )
    }
    console.error('gold-mine collect error:', error)
    return NextResponse.json(
      { error: 'Failed to collect gold mine reward' },
      { status: 500 }
    )
  }
}
