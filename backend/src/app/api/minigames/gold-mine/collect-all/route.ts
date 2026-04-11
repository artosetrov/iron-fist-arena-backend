/**
 * POST /api/minigames/gold-mine/collect-all
 *
 * Drains all READY and MINIGAME-PLAYED gold-mine slots in a single
 * transaction. Under Variant D Phase 2 (per-slot minigame), collection is
 * gated on the per-slot bonus minigame having been played first.
 *
 * Request body:
 *   { character_id: string, picked_shaft_key?: 'stone' | 'ice' }
 *
 * Response shape (success):
 *   {
 *     slots: SlotInfo[],
 *     gold_collected: number,
 *     gems_collected: number,
 *     gold: number,
 *     gems: number,
 *     active_shaft: { key, progress, total, ... } | null,
 *     needs_shaft_pick?: true,
 *     unlocked_shafts?: ShaftKey[],
 *   }
 *
 * Response shape (no playable slots — ready but unplayed):
 *   {
 *     error: 'No playable slots — finish the bonus minigame first',
 *     unplayed_ready_slot_indices: number[],
 *     slots: SlotInfo[],
 *   } with status 409
 *
 * Variant D Phase 2 rules:
 *   - Player must have an active shaft (or picks one in-call).
 *   - Only slots with `minigamePlayedAt != null` can be drained. Slots that
 *     are ready but unplayed are LEFT behind — player must go play the
 *     per-slot bonus minigame first via /slot-minigame/start + /submit.
 *   - Each collect-all cycle advances shaft progress by +1 (preserving
 *     legacy pacing: ~5 cycles per shaft). Shaft progress advancement is
 *     no longer tied to the minigame endpoint — it lives here so that
 *     multi-slot players don't blast through shafts.
 *   - Shaft clears when `shaftProgress >= shaftTotal` → activeShaftKey
 *     reset to NULL so the client re-prompts for a new shaft pick.
 *
 * Server-authoritative — client never calculates gold, gems, caps, or
 * shaft progress.
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
  getUnlockedShaftKeys,
  isValidShaftKey,
  type ShaftKey,
} from '@/lib/game/shaft-catalog'

interface CollectAllBody {
  character_id?: string
  picked_shaft_key?: string
}

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  // Hoisted so the catch block can rebuild the slots snapshot for
  // NO_PLAYABLE_SLOTS without re-parsing the body.
  let character_id: string | undefined
  let goldMineSlotsLevel: number | undefined

  try {
    const body = (await req.json()) as CollectAllBody
    character_id = body.character_id
    const { picked_shaft_key } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    // Pre-transaction: validate shaft pick format. Anything else is validated
    // inside the transaction (against character state).
    if (picked_shaft_key !== undefined && !isValidShaftKey(picked_shaft_key)) {
      return NextResponse.json({ error: 'Invalid shaft key' }, { status: 400 })
    }

    const result = await prisma.$transaction(async (tx) => {
      // Load + ownership check.
      const character = await tx.character.findUnique({
        where: { id: character_id },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')
      goldMineSlotsLevel = character.goldMineSlots

      // Resolve active shaft (existing or picked this call).
      let activeShaftKey: ShaftKey | null = character.activeShaftKey as ShaftKey | null
      let shaftProgress = character.shaftProgress
      const shaftTotal = character.shaftTotal || SHAFT_TOTAL_EXTRACTIONS
      const unlockedShafts = getUnlockedShaftKeys(character.goldMineSlots)

      if (!activeShaftKey) {
        if (picked_shaft_key && isValidShaftKey(picked_shaft_key)) {
          if (!unlockedShafts.includes(picked_shaft_key)) {
            throw new Error('SHAFT_LOCKED')
          }
          activeShaftKey = picked_shaft_key
          shaftProgress = 0
          await tx.character.update({
            where: { id: character_id },
            data: {
              activeShaftKey: picked_shaft_key,
              shaftProgress: 0,
              shaftTotal,
            },
          })
        } else {
          // No active shaft, no pick — client must show the picker.
          return {
            needsShaftPick: true as const,
            unlockedShafts,
            character,
          }
        }
      }

      // Lock all ready sessions for this character — both played and unplayed,
      // so we can partition them and return helpful info about the unplayed
      // ones.
      const now = new Date()
      const readySessions = await tx.$queryRawUnsafe<
        Array<{
          id: string
          slot_index: number
          reward: number
          gem_reward: number
          minigame_played_at: Date | null
        }>
      >(
        `SELECT id, slot_index, reward, gem_reward, minigame_played_at
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

      const playedReady = readySessions.filter((s) => s.minigame_played_at != null)
      const unplayedReady = readySessions.filter((s) => s.minigame_played_at == null)

      if (playedReady.length === 0) {
        // Everything ready, nothing played → signal to client to open the
        // per-slot minigame on one of these slots first.
        const err = new Error('NO_PLAYABLE_SLOTS') as Error & {
          unplayedSlotIndices?: number[]
        }
        err.unplayedSlotIndices = unplayedReady.map((s) => s.slot_index)
        throw err
      }

      const passiveGold = playedReady.reduce((sum, s) => sum + s.reward, 0)
      const passiveGems = playedReady.reduce((sum, s) => sum + s.gem_reward, 0)

      // Mark only the played-ready sessions as collected. Unplayed ready
      // slots stay on the board so the player can come back, play their
      // per-slot bonus minigame, and collect on the next call.
      await tx.goldMineSession.updateMany({
        where: { id: { in: playedReady.map((s) => s.id) } },
        data: { collected: true },
      })

      // Credit the player the passive pool immediately.
      const updatedUserAfterGold = await tx.user.update({
        where: { id: user.id },
        data: { gold: { increment: passiveGold } },
      })
      let updatedUser = updatedUserAfterGold
      if (passiveGems > 0) {
        updatedUser = await tx.user.update({
          where: { id: user.id },
          data: { gems: { increment: passiveGems } },
        })
      }

      // Advance shaft progress by 1 per cycle. This preserves the legacy
      // pacing (~5 cycles per shaft) regardless of how many slots the
      // player unlocked, because it's per cycle, not per slot played.
      let nextShaftKey: ShaftKey | null = activeShaftKey
      let nextShaftProgress = shaftProgress + 1
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

      return {
        needsShaftPick: false as const,
        character,
        activeShaftKey: nextShaftKey,
        shaftProgress: nextShaftProgress,
        shaftTotal,
        passiveGold,
        passiveGems,
        updatedUser,
        unplayedReadySlotIndices: unplayedReady.map((s) => s.slot_index),
      }
    })

    // Handle shaft-pick branch (no drain).
    if (result.needsShaftPick) {
      const slots = await buildSlotsArray(
        prisma,
        character_id,
        result.character.goldMineSlots
      )
      return NextResponse.json({
        slots,
        gold_collected: 0,
        gems_collected: 0,
        needs_shaft_pick: true,
        unlocked_shafts: result.unlockedShafts,
        active_shaft: null,
      })
    }

    // Update quest progress (outside transaction, non-critical).
    await Promise.all([
      updateDailyQuestProgress(prisma, character_id, 'gold_mine_collect'),
      updateWeeklyChallengeProgress(prisma, character_id, 'gold_mine_collect'),
    ])

    const slots = await buildSlotsArray(
      prisma,
      character_id,
      result.character.goldMineSlots
    )

    // Shaft may have cleared this cycle — if so, active_shaft is null and
    // the client will re-prompt with the shaft picker on the next call.
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
      gold_collected: result.passiveGold,
      gems_collected: result.passiveGems,
      gold: result.updatedUser.gold,
      gems: result.updatedUser.gems,
      active_shaft: activeShaft,
      unplayed_ready_slot_indices: result.unplayedReadySlotIndices,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') {
        return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      }
      if (error.message === 'FORBIDDEN') {
        return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      }
      if (error.message === 'SHAFT_LOCKED') {
        return NextResponse.json(
          { error: 'Selected shaft is not unlocked yet' },
          { status: 400 }
        )
      }
      if (error.message === 'NO_READY_SLOTS') {
        return NextResponse.json(
          { error: 'No ready slots to collect' },
          { status: 400 }
        )
      }
      if (error.message === 'NO_PLAYABLE_SLOTS') {
        const unplayed =
          (error as Error & { unplayedSlotIndices?: number[] })
            .unplayedSlotIndices ?? []
        let slots: unknown[] = []
        if (character_id && goldMineSlotsLevel != null) {
          try {
            slots = await buildSlotsArray(
              prisma,
              character_id,
              goldMineSlotsLevel
            )
          } catch {
            // non-critical — client can refetch
          }
        }
        return NextResponse.json(
          {
            error:
              'No playable slots — finish the bonus minigame on a ready slot first',
            code: 'NO_PLAYABLE_SLOTS',
            unplayed_ready_slot_indices: unplayed,
            slots,
          },
          { status: 409 }
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
