/**
 * POST /api/minigames/gold-mine/slot-minigame/start
 *
 * Opens a per-slot bonus mini-game session (Variant D Phase 2). Unlike the
 * legacy /collect-all aggregate flow, this is called per individual slot and
 * can be triggered at any time while the slot is mining or ready — so the
 * player can "pre-play" the bonus while their shaft is still cooking.
 *
 * Request body:
 *   { character_id: string, slot_index: number, picked_shaft_key?: ShaftKey }
 *
 * Response shape (success):
 *   {
 *     slots: SlotInfo[],
 *     active_shaft: { key, progress, total, ... },
 *     minigame_session: {
 *       id, slot_index, shaft_key, passive_gold_amount,
 *       cap_gold, gem_cap, expires_at
 *     }
 *   }
 *
 * Response shape (needs shaft pick):
 *   { needs_shaft_pick: true, unlocked_shafts: ShaftKey[], slots: SlotInfo[] }
 *
 * Rules:
 *   - Slot must exist, be uncollected, and not already have
 *     `minigamePlayedAt != null` (one play per slot, no replay).
 *   - If a minigame session is already in flight for this slot AND not
 *     expired, return the existing session (idempotent — player can re-open
 *     the cover).
 *   - Must have an active shaft (or pick one in-call).
 *   - Cap scales with goldMineSlots level via `calcSlotMinigameCap`.
 *   - Bonus gold/gems are credited only after /submit — opening does NOT
 *     pay out.
 */

import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { buildSlotsArray } from '@/lib/game/gold-mine'
import {
  SHAFTS,
  SHAFT_TOTAL_EXTRACTIONS,
  MINIGAME_SESSION_TTL_SEC,
  MINIGAME_GEM_CAP,
  MINIGAME_GAME_TYPE,
  calcSlotMinigameCap,
  getUnlockedShaftKeys,
  isValidShaftKey,
  type ShaftKey,
} from '@/lib/game/shaft-catalog'

interface StartBody {
  character_id?: string
  slot_index?: number
  picked_shaft_key?: string
}

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = (await req.json()) as StartBody
    const { character_id, slot_index, picked_shaft_key } = body

    if (!character_id || slot_index == null) {
      return NextResponse.json(
        { error: 'character_id and slot_index are required' },
        { status: 400 }
      )
    }

    if (picked_shaft_key !== undefined && !isValidShaftKey(picked_shaft_key)) {
      return NextResponse.json({ error: 'Invalid shaft key' }, { status: 400 })
    }

    const result = await prisma.$transaction(async (tx) => {
      const character = await tx.character.findUnique({
        where: { id: character_id },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Resolve active shaft or adopt the picked one.
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
          return {
            needsShaftPick: true as const,
            unlockedShafts,
            character,
          }
        }
      }

      // Lock the slot row.
      const [slotRow] = await tx.$queryRawUnsafe<
        Array<{
          id: string
          reward: number
          gem_reward: number
          minigame_played_at: Date | null
          minigame_session_id: string | null
        }>
      >(
        `SELECT id, reward, gem_reward, minigame_played_at, minigame_session_id
           FROM gold_mine_sessions
          WHERE character_id = $1
            AND slot_index = $2
            AND collected = false
          FOR UPDATE`,
        character_id,
        slot_index
      )

      if (!slotRow) throw new Error('NO_SESSION')
      if (slotRow.minigame_played_at) throw new Error('ALREADY_PLAYED')

      // If an existing in-flight session is still valid, return it as-is
      // (idempotent resume).
      if (slotRow.minigame_session_id) {
        const [existing] = await tx.$queryRawUnsafe<
          Array<{
            id: string
            status: string
            expires_at: Date | null
            cap_gold: number | null
            passive_gold_amount: number | null
            shaft_key: string | null
          }>
        >(
          `SELECT id, status, expires_at, cap_gold, passive_gold_amount, shaft_key
             FROM minigame_sessions
            WHERE id = $1
            FOR UPDATE`,
          slotRow.minigame_session_id
        )

        if (
          existing &&
          existing.status === 'pending' &&
          existing.expires_at &&
          existing.expires_at.getTime() > Date.now()
        ) {
          return {
            needsShaftPick: false as const,
            character,
            activeShaftKey: activeShaftKey!,
            shaftProgress,
            shaftTotal,
            slotIndex: slot_index,
            minigameSessionId: existing.id,
            capGold: existing.cap_gold ?? 0,
            passiveGold: existing.passive_gold_amount ?? 0,
            expiresAt: existing.expires_at,
            resumed: true as const,
          }
        }

        // Stale pointer — expire the old session.
        if (existing) {
          await tx.minigameSession.update({
            where: { id: existing.id },
            data: { status: 'expired' },
          })
        }
      }

      // Fresh session.
      const capGold = calcSlotMinigameCap(slotRow.reward, character.goldMineSlots)
      const now = new Date()
      const expiresAt = new Date(now.getTime() + MINIGAME_SESSION_TTL_SEC * 1000)

      const minigameSession = await tx.minigameSession.create({
        data: {
          characterId: character_id,
          gameType: MINIGAME_GAME_TYPE,
          status: 'pending',
          shaftKey: activeShaftKey!,
          passiveGoldAmount: slotRow.reward,
          capGold,
          expiresAt,
        },
      })

      await tx.goldMineSession.update({
        where: { id: slotRow.id },
        data: { minigameSessionId: minigameSession.id },
      })

      return {
        needsShaftPick: false as const,
        character,
        activeShaftKey: activeShaftKey!,
        shaftProgress,
        shaftTotal,
        slotIndex: slot_index,
        minigameSessionId: minigameSession.id,
        capGold,
        passiveGold: slotRow.reward,
        expiresAt,
        resumed: false as const,
      }
    })

    if (result.needsShaftPick) {
      const slots = await buildSlotsArray(
        prisma,
        character_id,
        result.character.goldMineSlots
      )
      return NextResponse.json({
        needs_shaft_pick: true,
        unlocked_shafts: result.unlockedShafts,
        slots,
      })
    }

    const slots = await buildSlotsArray(
      prisma,
      character_id,
      result.character.goldMineSlots
    )

    return NextResponse.json({
      slots,
      active_shaft: {
        key: result.activeShaftKey,
        progress: result.shaftProgress,
        total: result.shaftTotal,
        display_name: SHAFTS[result.activeShaftKey as ShaftKey].displayName,
        background_asset: SHAFTS[result.activeShaftKey as ShaftKey].backgroundAssetName,
        thumb_asset: SHAFTS[result.activeShaftKey as ShaftKey].thumbAssetName,
      },
      minigame_session: {
        id: result.minigameSessionId,
        slot_index: result.slotIndex,
        shaft_key: result.activeShaftKey,
        passive_gold_amount: result.passiveGold,
        cap_gold: result.capGold,
        gem_cap: MINIGAME_GEM_CAP,
        expires_at: result.expiresAt.toISOString(),
      },
    })
  } catch (error) {
    if (error instanceof Error) {
      switch (error.message) {
        case 'NOT_FOUND':
          return NextResponse.json({ error: 'Character not found' }, { status: 404 })
        case 'FORBIDDEN':
          return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
        case 'SHAFT_LOCKED':
          return NextResponse.json(
            { error: 'Selected shaft is not unlocked yet' },
            { status: 400 }
          )
        case 'NO_SESSION':
          return NextResponse.json(
            { error: 'No active mining session for this slot' },
            { status: 404 }
          )
        case 'ALREADY_PLAYED':
          return NextResponse.json(
            { error: 'Bonus minigame already played for this slot' },
            { status: 409 }
          )
      }
    }
    console.error('gold-mine slot-minigame/start error:', error)
    return NextResponse.json(
      { error: 'Failed to start slot mini-game' },
      { status: 500 }
    )
  }
}
