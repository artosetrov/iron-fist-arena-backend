/**
 * POST /api/minigames/gold-mine/slot-minigame/submit
 *
 * Finalizes a per-slot bonus mini-game session (Variant D Phase 2).
 * Mirrors the legacy /minigame-bonus logic but targets a specific gold-mine
 * slot via `slot_index`. Credits bonus gold/gems immediately and stamps the
 * slot as played — the slot's passive reward is still collected separately
 * via /collect or /collect-all (and those endpoints refuse to pay out unless
 * this has been called first).
 *
 * Request body:
 *   {
 *     character_id: string,
 *     slot_index: number,
 *     session_id: string,       // must match slot.minigame_session_id
 *     caught_count: number,
 *     spawned_count: number,
 *     gold_claimed_in_session: number,
 *     gems_claimed_in_session: number,
 *     skipped?: boolean,
 *   }
 *
 * Response shape:
 *   {
 *     bonus_gold: number,
 *     bonus_gems: number,
 *     gold: number,
 *     gems: number,
 *     slots: SlotInfo[],
 *   }
 *
 * Rules:
 *   - Session must be status 'pending', not expired, owned by caller,
 *     type gold_mine_rush.
 *   - Clamp + cap on server (bonus_gold = min(gold_claim, capGold)).
 *   - Mark slot minigamePlayedAt = now, minigameSessionId = null.
 *   - Does NOT advance shaft progress — shaft advancement is moved to the
 *     /collect-all endpoint so that one collect-all cycle = 1 extraction
 *     regardless of how many slots are played. This preserves legacy
 *     balance (5 collect cycles per shaft).
 */

import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { buildSlotsArray } from '@/lib/game/gold-mine'
import {
  MINIGAME_GEM_CAP,
  MINIGAME_GAME_TYPE,
} from '@/lib/game/shaft-catalog'

// Minimum elapsed time (ms) between session start and submit.
// The actual minigame takes 10-15s; 3s floor blocks instant bot submits
// without false-positiving on fast players who skip.
const MIN_PLAY_ELAPSED_MS = 3_000

interface SubmitBody {
  character_id?: string
  slot_index?: number
  session_id?: string
  caught_count?: number
  spawned_count?: number
  gold_claimed_in_session?: number
  gems_claimed_in_session?: number
  skipped?: boolean
}

// Simple in-memory rate limit — 1 call per 5s per character.
const rateLimitMap = new Map<string, number>()
const RATE_LIMIT_WINDOW_MS = 5_000

function checkRateLimit(characterId: string): boolean {
  const now = Date.now()
  const lastCall = rateLimitMap.get(characterId) ?? 0
  if (now - lastCall < RATE_LIMIT_WINDOW_MS) return false
  rateLimitMap.set(characterId, now)
  if (rateLimitMap.size > 1000) {
    for (const [key, ts] of rateLimitMap.entries()) {
      if (now - ts > RATE_LIMIT_WINDOW_MS * 4) rateLimitMap.delete(key)
    }
  }
  return true
}

function clampInt(value: unknown, min: number, max: number): number {
  const n = typeof value === 'number' && Number.isFinite(value) ? Math.floor(value) : 0
  if (n < min) return min
  if (n > max) return max
  return n
}

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = (await req.json()) as SubmitBody
    const {
      character_id,
      slot_index,
      session_id,
      caught_count,
      spawned_count,
      gold_claimed_in_session,
      gems_claimed_in_session,
      skipped,
    } = body

    if (!character_id || slot_index == null || !session_id) {
      return NextResponse.json(
        { error: 'character_id, slot_index and session_id are required' },
        { status: 400 }
      )
    }

    if (!checkRateLimit(character_id)) {
      return NextResponse.json(
        { error: 'Too many mini-game claims, slow down' },
        { status: 429 }
      )
    }

    const result = await prisma.$transaction(async (tx) => {
      const character = await tx.character.findUnique({
        where: { id: character_id },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Lock the slot row + verify it points to this session.
      const [slotRow] = await tx.$queryRawUnsafe<
        Array<{
          id: string
          reward: number
          minigame_played_at: Date | null
          minigame_session_id: string | null
        }>
      >(
        `SELECT id, reward, minigame_played_at, minigame_session_id
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
      if (slotRow.minigame_session_id !== session_id) {
        throw new Error('SESSION_MISMATCH')
      }

      // Lock + verify the minigame session itself.
      const [minigameRow] = await tx.$queryRawUnsafe<
        Array<{
          id: string
          character_id: string
          game_type: string
          status: string
          cap_gold: number | null
          passive_gold_amount: number | null
          expires_at: Date | null
          created_at: Date
        }>
      >(
        `SELECT id, character_id, game_type, status,
                cap_gold, passive_gold_amount, expires_at, created_at
           FROM minigame_sessions
          WHERE id = $1
          FOR UPDATE`,
        session_id
      )

      if (!minigameRow) throw new Error('SESSION_NOT_FOUND')
      if (minigameRow.character_id !== character_id) throw new Error('FORBIDDEN')
      if (minigameRow.game_type !== MINIGAME_GAME_TYPE) throw new Error('WRONG_GAME_TYPE')
      if (minigameRow.status !== 'pending') throw new Error('SESSION_NOT_PENDING')

      // Proof-of-play: reject instant submits (bot protection).
      // Skipped games are exempt — skip button is available immediately.
      if (!skipped) {
        const elapsedMs = Date.now() - minigameRow.created_at.getTime()
        if (elapsedMs < MIN_PLAY_ELAPSED_MS) {
          throw new Error('TOO_FAST')
        }
      }
      if (
        minigameRow.expires_at &&
        minigameRow.expires_at.getTime() < Date.now()
      ) {
        await tx.minigameSession.update({
          where: { id: minigameRow.id },
          data: { status: 'expired' },
        })
        // Drop the stale pointer on the slot so the player can restart.
        await tx.goldMineSession.update({
          where: { id: slotRow.id },
          data: { minigameSessionId: null },
        })
        throw new Error('SESSION_EXPIRED')
      }

      const capGold = minigameRow.cap_gold ?? 0
      const passivePool = minigameRow.passive_gold_amount ?? 0

      // Clamp + cap. Gold claim can never exceed the passive pool AND
      // never exceed the per-slot cap.
      const spawned = clampInt(spawned_count, 0, 500)
      const caught = clampInt(caught_count, 0, spawned)
      const goldClaim = clampInt(gold_claimed_in_session, 0, passivePool)
      const gemsClaim = clampInt(gems_claimed_in_session, 0, 5) // hard safety

      const bonusGold = Math.min(goldClaim, capGold)
      const bonusGems = Math.min(gemsClaim, MINIGAME_GEM_CAP)

      // Credit bonus.
      const updatedUserAfterGold = await tx.user.update({
        where: { id: user.id },
        data: { gold: { increment: bonusGold } },
      })
      let updatedUser = updatedUserAfterGold
      if (bonusGems > 0) {
        updatedUser = await tx.user.update({
          where: { id: user.id },
          data: { gems: { increment: bonusGems } },
        })
      }

      // Mark minigame session claimed/skipped.
      await tx.minigameSession.update({
        where: { id: minigameRow.id },
        data: {
          status: skipped ? 'skipped' : 'claimed',
          claimedGold: bonusGold,
          claimedGems: bonusGems,
          caughtCount: caught,
          spawnedCount: spawned,
          claimedAt: new Date(),
        },
      })

      // Stamp slot as played.
      await tx.goldMineSession.update({
        where: { id: slotRow.id },
        data: {
          minigameSessionId: null,
          minigamePlayedAt: new Date(),
        },
      })

      return {
        updatedUser,
        bonusGold,
        bonusGems,
        goldMineSlots: character.goldMineSlots,
      }
    })

    const slots = await buildSlotsArray(prisma, character_id, result.goldMineSlots)

    return NextResponse.json({
      bonus_gold: result.bonusGold,
      bonus_gems: result.bonusGems,
      gold: result.updatedUser.gold,
      gems: result.updatedUser.gems,
      slots,
    })
  } catch (error) {
    if (error instanceof Error) {
      switch (error.message) {
        case 'NOT_FOUND':
          return NextResponse.json({ error: 'Character not found' }, { status: 404 })
        case 'FORBIDDEN':
          return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
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
        case 'SESSION_MISMATCH':
          return NextResponse.json(
            { error: 'Session id does not match the active slot session' },
            { status: 400 }
          )
        case 'SESSION_NOT_FOUND':
          return NextResponse.json({ error: 'Mini-game session not found' }, { status: 404 })
        case 'SESSION_NOT_PENDING':
          return NextResponse.json(
            { error: 'Mini-game session already claimed' },
            { status: 400 }
          )
        case 'SESSION_EXPIRED':
          return NextResponse.json({ error: 'Mini-game session expired' }, { status: 400 })
        case 'WRONG_GAME_TYPE':
          return NextResponse.json(
            { error: 'Session is not a Gold Mine mini-game' },
            { status: 400 }
          )
        case 'TOO_FAST':
          return NextResponse.json(
            { error: 'Mini-game completed too quickly — please play before submitting' },
            { status: 400 }
          )
      }
    }
    console.error('gold-mine slot-minigame/submit error:', error)
    return NextResponse.json(
      { error: 'Failed to claim slot mini-game bonus' },
      { status: 500 }
    )
  }
}
