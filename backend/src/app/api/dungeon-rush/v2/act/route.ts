import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { lockDungeonRunForUpdate } from '@/lib/game/dungeon-run-lock'
import { invalidatePassiveCache, invalidateSkillCache } from '@/lib/game/combat-loader'
import { incrementGuildChallenge } from '@/lib/game/guild-challenge'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'
import { DESCENT_DUNGEON_ID, RELIC_KEYS, type RelicKey } from '@/lib/game/descent/content'
import {
  ACTION_TYPES, DescentError, applyAction, isDescentState, resolvePendingLoot,
  type Action, type CampChoice, type DescentState,
} from '@/lib/game/descent/engine'
import { applyDescentEffects, previewBagEntry, serializeState, type AppliedEffects } from '@/lib/game/descent/server'
import { buildDescentView } from '@/lib/game/descent/view'

class StaleRunError extends Error {
  constructor(public readonly state: DescentState) {
    super('STALE')
  }
}

function parseAction(body: Record<string, unknown>): Action | null {
  const type = body.action
  if (typeof type !== 'string' || !(ACTION_TYPES as readonly string[]).includes(type)) return null
  const nodeId = typeof body.node_id === 'string' ? body.node_id : null
  const i = typeof body.i === 'number' && Number.isInteger(body.i) ? body.i : null
  const k = typeof body.k === 'string' ? body.k : null
  switch (type) {
    case 'torch':
    case 'move':
      return nodeId ? { type, nodeId } : null
    case 'choose':
    case 'buy':
      return i !== null && i >= 0 && i < 8 ? { type, i } : null
    case 'camp':
      return k === 'rest' || k === 'sharpen' || k === 'stash' ? { type, k: k as CampChoice } : null
    case 'take_relic':
      if (k === null) return { type, k: null }
      return (RELIC_KEYS as string[]).includes(k) ? { type, k: k as RelicKey } : null
    default:
      return { type } as Action
  }
}

/**
 * POST /api/dungeon-rush/v2/act — apply one player action to the active Descent run.
 * Body: { character_id, run_id, seq, action, node_id?, i?, k? }
 * The server rolls every die; the client only renders the returned view.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  // Auto-fight sends a round every ~0.6 s; leave headroom above that.
  if (!(await rateLimit(`rush2-act:${user.id}`, 240, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  let parsedRunId: string | null = null
  try {
    const body = (await req.json().catch(() => null)) as Record<string, unknown> | null
    if (!body) return NextResponse.json({ error: 'Invalid body' }, { status: 400 })
    const characterId = typeof body.character_id === 'string' ? body.character_id : null
    const runId = typeof body.run_id === 'string' ? body.run_id : null
    parsedRunId = runId
    const seq = typeof body.seq === 'number' ? body.seq : null
    const action = parseAction(body)
    if (!characterId || !runId || seq === null) {
      return NextResponse.json({ error: 'character_id, run_id and seq are required' }, { status: 400 })
    }
    if (!action) return NextResponse.json({ error: 'Unknown or malformed action' }, { status: 400 })

    const character = await prisma.character.findFirst({
      where: { id: characterId, userId: user.id },
      select: { id: true, level: true },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })

    const result = await prisma.$transaction(async (tx) => {
      const locked = await lockDungeonRunForUpdate(tx, runId)
      if (!locked) throw new Error('RUN_NOT_ACTIVE')
      if (locked.characterId !== characterId || locked.dungeonId !== DESCENT_DUNGEON_ID || locked.difficulty !== 'rush') {
        throw new Error('RUN_MISMATCH')
      }
      if (!isDescentState(locked.state)) throw new Error('RUN_NOT_ACTIVE')
      const current = locked.state as unknown as DescentState
      if (current.seq !== seq) throw new StaleRunError(current)

      const { state, fx, effects } = applyAction(current, action, Math.random)
      await resolvePendingLoot(state, () => previewBagEntry(tx, characterId, character.level))
      const applied = await applyDescentEffects(tx, { userId: user.id, characterId, effects })

      if (applied.ended) {
        await tx.dungeonRun.delete({ where: { id: runId } })
      } else {
        await tx.dungeonRun.update({
          where: { id: runId },
          data: { currentFloor: state.depth + 1, state: serializeState(state) },
        })
      }
      return { state, fx, applied }
    }, { timeout: 15_000, maxWait: 10_000 })

    fireAndForgetProgress(characterId, result.applied)
    if (result.applied.character?.leveledUp) {
      await invalidateSkillCache(characterId)
      await invalidatePassiveCache(characterId)
    }

    return NextResponse.json({
      view: buildDescentView(runId, result.state, result.fx),
      ended: result.applied.ended,
      granted: {
        gold: result.applied.goldClaimed,
        xp: result.applied.xpGranted,
        items: result.applied.itemsGranted,
      },
      character: result.applied.character,
    })
  } catch (error) {
    if (error instanceof StaleRunError) {
      return NextResponse.json({
        error: 'This run moved on. Showing the latest state.',
        code: 'STALE',
        view: parsedRunId ? buildDescentView(parsedRunId, error.state) : null,
      }, { status: 409 })
    }
    if (error instanceof DescentError) {
      return NextResponse.json({ error: error.message, code: error.code }, { status: 400 })
    }
    if (error instanceof Error) {
      if (error.message === 'RUN_NOT_ACTIVE') {
        return NextResponse.json({ error: 'This descent is over. Start a new one.', code: 'RUN_NOT_ACTIVE' }, { status: 404 })
      }
      if (error.message === 'RUN_MISMATCH') {
        return NextResponse.json({ error: 'Run does not match this character.', code: 'RUN_MISMATCH' }, { status: 400 })
      }
    }
    console.error('dungeon rush v2 act error:', error)
    return NextResponse.json({ error: 'Failed to process the action' }, { status: 500 })
  }
}

function fireAndForgetProgress(characterId: string, applied: AppliedEffects): void {
  for (const k of applied.kills) {
    incrementGuildChallenge(prisma, 'dungeons_cleared', 1).catch(() => {})
    if (k.kind === 'boss') {
      incrementGuildChallenge(prisma, 'bosses_killed', 1).catch(() => {})
      updateWeeklyChallengeProgress(prisma, characterId, 'dungeons_complete').catch(() => {})
    }
  }
  if (applied.goldClaimed > 0) {
    incrementGuildChallenge(prisma, 'gold_earned', Math.floor(applied.goldClaimed)).catch(() => {})
  }
}
