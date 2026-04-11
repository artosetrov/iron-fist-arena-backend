/**
 * POST /api/minigames/gold-mine/collect
 *
 * Drains a single ready slot. Gated on the per-slot bonus minigame having
 * been played first (Variant D Phase 2). Advances shaft progress by +1 per
 * successful call so that the shaft cadence matches /collect-all (each
 * "drain action" = one extraction).
 *
 * Request body:
 *   { character_id: string, slot_index: number }
 *
 * Response shape (success):
 *   {
 *     slots: SlotInfo[],
 *     gold_collected: number,
 *     gems_collected: number,
 *     gold: number,
 *     gems: number,
 *     active_shaft: { key, progress, total } | null,
 *   }
 */

import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { buildSlotsArray } from '@/lib/game/gold-mine'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'
import {
  SHAFTS,
  SHAFT_TOTAL_EXTRACTIONS,
  type ShaftKey,
} from '@/lib/game/shaft-catalog'

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
      // Verify character ownership
      const character = await tx.character.findUnique({
        where: { id: character_id },
      })

      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Lock the session row for update to prevent double-collect. Also
      // fetch minigame_played_at so we can enforce the per-slot bonus gate.
      const [sessionRow] = await tx.$queryRawUnsafe<
        Array<{
          id: string
          collected: boolean
          reward: number
          gem_reward: number
          ends_at: Date
          minigame_played_at: Date | null
        }>
      >(
        `SELECT id, collected, reward, gem_reward, ends_at, minigame_played_at
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
      if (sessionRow.minigame_played_at == null) {
        throw new Error('MINIGAME_REQUIRED')
      }

      // Mark collected
      await tx.goldMineSession.update({
        where: { id: sessionRow.id },
        data: { collected: true },
      })

      // Add gold to user
      const updatedUser = await tx.user.update({
        where: { id: user.id },
        data: { gold: { increment: sessionRow.reward } },
      })

      // Add gems to user if any
      let updatedUserWithGems = updatedUser
      if (sessionRow.gem_reward > 0) {
        updatedUserWithGems = await tx.user.update({
          where: { id: user.id },
          data: { gems: { increment: sessionRow.gem_reward } },
        })
      }

      // Advance shaft progress by +1. Each drain action (single or all)
      // costs one extraction, preserving balance across player behaviours.
      let nextShaftKey: ShaftKey | null =
        character.activeShaftKey as ShaftKey | null
      let nextShaftProgress = character.shaftProgress
      const shaftTotal = character.shaftTotal || SHAFT_TOTAL_EXTRACTIONS
      if (nextShaftKey) {
        nextShaftProgress = character.shaftProgress + 1
        if (nextShaftProgress >= shaftTotal) {
          nextShaftProgress = 0
          nextShaftKey = null
        }
        await tx.character.update({
          where: { id: character_id },
          data: {
            activeShaftKey: nextShaftKey,
            shaftProgress: nextShaftProgress,
            shaftTotal,
          },
        })
      }

      return {
        updatedUser: updatedUserWithGems,
        reward: sessionRow.reward,
        gemReward: sessionRow.gem_reward,
        goldMineSlots: character.goldMineSlots,
        activeShaftKey: nextShaftKey,
        shaftProgress: nextShaftProgress,
        shaftTotal,
      }
    })

    // Get current user gems/gold from updated user
    const userGems = result.updatedUser.gems
    const userGold = result.updatedUser.gold

    // Update daily + weekly quest progress (outside transaction, non-critical)
    await Promise.all([
      updateDailyQuestProgress(prisma, character_id, 'gold_mine_collect'),
      // W3.D5 — Weekly BP challenge: Prospector slot
      updateWeeklyChallengeProgress(prisma, character_id, 'gold_mine_collect'),
    ])

    const slots = await buildSlotsArray(prisma, character_id, result.goldMineSlots)

    const activeShaft = result.activeShaftKey
      ? {
          key: result.activeShaftKey,
          progress: result.shaftProgress,
          total: result.shaftTotal,
          display_name: SHAFTS[result.activeShaftKey as ShaftKey].displayName,
          background_asset:
            SHAFTS[result.activeShaftKey as ShaftKey].backgroundAssetName,
          thumb_asset: SHAFTS[result.activeShaftKey as ShaftKey].thumbAssetName,
        }
      : null

    return NextResponse.json({
      slots,
      gold_collected: result.reward,
      gems_collected: result.gemReward,
      gold: userGold,
      gems: userGems,
      active_shaft: activeShaft,
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
      if (error.message === 'MINIGAME_REQUIRED')
        return NextResponse.json(
          {
            error: 'Play the bonus minigame for this slot before collecting',
            code: 'MINIGAME_REQUIRED',
          },
          { status: 409 }
        )
    }
    console.error('gold-mine collect error:', error)
    return NextResponse.json(
      { error: 'Failed to collect gold mine reward' },
      { status: 500 }
    )
  }
}
