/**
 * POST /api/minigames/gold-mine/minigame-bonus
 *
 * Finalizes a Gold Mine mini-game session opened by /collect-all.
 *
 * Request body:
 *   {
 *     character_id: string,
 *     session_id: string,
 *     caught_count: number,  // how many drops the player caught
 *     spawned_count: number, // how many drops were spawned in total
 *     gold_claimed_in_session: number, // sum of gold values of caught drops
 *     gems_claimed_in_session: number, // sum of gem drops caught
 *     skipped?: boolean,     // true if user tapped Skip / timer ran out with 0 caught
 *   }
 *
 * Response shape:
 *   {
 *     bonus_gold: number,
 *     bonus_gems: number,
 *     gold: number,
 *     gems: number,
 *     active_shaft: { key, progress, total, ... } | null,
 *     shaft_completed: boolean,
 *   }
 *
 * Server-authoritative rules:
 *   - bonus_gold = min(gold_claimed_in_session, session.capGold)
 *   - bonus_gems = min(gems_claimed_in_session, 1)
 *   - Negative / out-of-bounds values are clamped.
 *   - Shaft progress advances only if !skipped && caught_count > 0.
 *   - Session must be status === 'pending' and not expired.
 *   - 1 call per 30s per character (rate limit).
 *
 * Variant D rules:
 *   - When shaft progress hits shaft_total, the shaft is cleared:
 *       activeShaftKey cleared → player may pick again on next collect-all.
 *       shaftProgress reset to 0.
 *       No completion reward in Phase 1 (by design, locked).
 */

import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import {
  SHAFTS,
  MINIGAME_GEM_CAP,
  MINIGAME_GAME_TYPE,
  type ShaftKey,
} from '@/lib/game/shaft-catalog'

interface MinigameBonusBody {
  character_id?: string
  session_id?: string
  caught_count?: number
  spawned_count?: number
  gold_claimed_in_session?: number
  gems_claimed_in_session?: number
  skipped?: boolean
}

// Simple in-memory rate limiter — 1 call per 30s per character.
// Backend runs as a single Next.js instance; if horizontally scaled later,
// replace with Redis-backed limiter.
const rateLimitMap = new Map<string, number>()
const RATE_LIMIT_WINDOW_MS = 30_000

function checkRateLimit(characterId: string): boolean {
  const now = Date.now()
  const lastCall = rateLimitMap.get(characterId) ?? 0
  if (now - lastCall < RATE_LIMIT_WINDOW_MS) return false
  rateLimitMap.set(characterId, now)
  // Opportunistic cleanup of stale keys.
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
    const body = (await req.json()) as MinigameBonusBody
    const {
      character_id,
      session_id,
      caught_count,
      spawned_count,
      gold_claimed_in_session,
      gems_claimed_in_session,
      skipped,
    } = body

    if (!character_id || !session_id) {
      return NextResponse.json(
        { error: 'character_id and session_id are required' },
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
      // Lock the session row.
      const [sessionRow] = await tx.$queryRawUnsafe<
        Array<{
          id: string
          character_id: string
          game_type: string
          status: string
          shaft_key: string | null
          passive_gold_amount: number | null
          cap_gold: number | null
          expires_at: Date | null
        }>
      >(
        `SELECT id, character_id, game_type, status, shaft_key,
                passive_gold_amount, cap_gold, expires_at
           FROM minigame_sessions
          WHERE id = $1
          FOR UPDATE`,
        session_id
      )

      if (!sessionRow) throw new Error('SESSION_NOT_FOUND')
      if (sessionRow.character_id !== character_id) throw new Error('FORBIDDEN')
      if (sessionRow.game_type !== MINIGAME_GAME_TYPE) throw new Error('WRONG_GAME_TYPE')
      if (sessionRow.status !== 'pending') throw new Error('SESSION_NOT_PENDING')
      if (sessionRow.expires_at && sessionRow.expires_at.getTime() < Date.now()) {
        await tx.minigameSession.update({
          where: { id: sessionRow.id },
          data: { status: 'expired' },
        })
        throw new Error('SESSION_EXPIRED')
      }

      // Load character + ownership check.
      const character = await tx.character.findUnique({
        where: { id: character_id },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      const capGold = sessionRow.cap_gold ?? 0
      const passivePool = sessionRow.passive_gold_amount ?? 0

      // Clamp + cap. Gold claim can never exceed the passive pool AND
      // never exceed the 15% cap derived from it.
      const spawned = clampInt(spawned_count, 0, 500)
      const caught = clampInt(caught_count, 0, spawned)
      const goldClaim = clampInt(gold_claimed_in_session, 0, passivePool)
      const gemsClaim = clampInt(gems_claimed_in_session, 0, 5) // hard upper safety

      const bonusGold = Math.min(goldClaim, capGold)
      const bonusGems = Math.min(gemsClaim, MINIGAME_GEM_CAP)

      // Credit the bonus.
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

      // Mark session claimed.
      await tx.minigameSession.update({
        where: { id: sessionRow.id },
        data: {
          status: skipped ? 'skipped' : 'claimed',
          claimedGold: bonusGold,
          claimedGems: bonusGems,
          caughtCount: caught,
          spawnedCount: spawned,
          claimedAt: new Date(),
        },
      })

      // Shaft progress advances only on a real play.
      // Anti-abuse: skipped or caught === 0 does NOT advance.
      const shouldAdvance = !skipped && caught > 0 && !!character.activeShaftKey
      let shaftProgress = character.shaftProgress
      let activeShaftKey = character.activeShaftKey as ShaftKey | null
      let shaftCompleted = false

      if (shouldAdvance) {
        shaftProgress = Math.min(character.shaftTotal, character.shaftProgress + 1)
        if (shaftProgress >= character.shaftTotal) {
          shaftCompleted = true
          await tx.character.update({
            where: { id: character_id },
            data: {
              activeShaftKey: null,
              shaftProgress: 0,
            },
          })
          activeShaftKey = null
          shaftProgress = 0
        } else {
          await tx.character.update({
            where: { id: character_id },
            data: { shaftProgress },
          })
        }
      }

      return {
        updatedUser,
        bonusGold,
        bonusGems,
        activeShaftKey,
        shaftProgress,
        shaftTotal: character.shaftTotal,
        shaftCompleted,
      }
    })

    const activeShaft =
      result.activeShaftKey != null
        ? {
            key: result.activeShaftKey,
            progress: result.shaftProgress,
            total: result.shaftTotal,
            display_name: SHAFTS[result.activeShaftKey].displayName,
            background_asset: SHAFTS[result.activeShaftKey].backgroundAssetName,
            thumb_asset: SHAFTS[result.activeShaftKey].thumbAssetName,
          }
        : null

    return NextResponse.json({
      bonus_gold: result.bonusGold,
      bonus_gems: result.bonusGems,
      gold: result.updatedUser.gold,
      gems: result.updatedUser.gems,
      active_shaft: activeShaft,
      shaft_completed: result.shaftCompleted,
    })
  } catch (error) {
    if (error instanceof Error) {
      switch (error.message) {
        case 'NOT_FOUND':
          return NextResponse.json({ error: 'Character not found' }, { status: 404 })
        case 'FORBIDDEN':
          return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
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
      }
    }
    console.error('gold-mine minigame-bonus error:', error)
    return NextResponse.json(
      { error: 'Failed to claim mini-game bonus' },
      { status: 500 }
    )
  }
}
