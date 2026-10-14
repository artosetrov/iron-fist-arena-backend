/**
 * Dice combat routes — /api/pvp/dice/act, /api/pvp/dice/resolve, /api/dice/socket.
 * Prisma is mocked; the dice state lives in match.interactiveActives.dice.
 */
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const { state, prismaMock } = vi.hoisted(() => {
  const state: {
    match: Record<string, unknown> | null
    writes: Array<Record<string, unknown>>
    updateCount: number
    character: Record<string, unknown>
    passives: Array<{ node: { nodeKey: string } }>
    dieRunes: Array<{ die: string; faceIndex: number; runeKey: string }>
    liveMatch: unknown
  } = {
    match: null, writes: [], updateCount: 1,
    character: { id: 'char-1', userId: 'user-1', class: 'warrior', level: 25 },
    passives: [], dieRunes: [], liveMatch: null,
  }
  const prismaMock = {
    pvpMatch: {
      findUnique: vi.fn(async () => state.match),
      findFirst: vi.fn(async () => state.liveMatch),
      updateMany: vi.fn(async (args: { data: Record<string, unknown> }) => {
        state.writes.push(args.data)
        return { count: state.updateCount }
      }),
    },
    character: { findUnique: vi.fn(async () => state.character) },
    characterPassive: { findMany: vi.fn(async () => state.passives) },
    passiveNode: { findMany: vi.fn(async () => []) },
    characterDieRune: {
      findMany: vi.fn(async (args?: { where?: { die?: string } }) =>
        state.dieRunes.filter((r) => !args?.where?.die || r.die === args.where.die)),
      deleteMany: vi.fn(async (args: { where: { die?: string; faceIndex?: number; OR?: Array<Record<string, unknown>> } }) => {
        const w = args.where
        state.dieRunes = state.dieRunes.filter((r) => {
          if (w.OR) return !w.OR.some((c) => (c.runeKey && c.runeKey === r.runeKey) || (c.die === r.die && c.faceIndex === r.faceIndex))
          return !(r.die === w.die && r.faceIndex === w.faceIndex)
        })
        return { count: 1 }
      }),
      create: vi.fn(async (args: { data: { die: string; faceIndex: number; runeKey: string } }) => {
        state.dieRunes.push(args.data)
        return args.data
      }),
    },
    $transaction: vi.fn(async (cb: (tx: unknown) => Promise<unknown>) => cb(prismaMock)),
    $queryRawUnsafe: vi.fn(async () => []),
  }
  return { state, prismaMock }
})

vi.mock('@/lib/auth', () => ({ getAuthUser: vi.fn(async () => ({ id: 'user-1' })) }))
vi.mock('@/lib/rate-limit', () => ({ rateLimit: vi.fn(async () => true) }))
vi.mock('@/lib/prisma', () => ({ prisma: prismaMock }))

import { POST as act } from '@/app/api/pvp/dice/act/route'
import { POST as resolve } from '@/app/api/pvp/dice/resolve/route'
import { POST as socket } from '@/app/api/dice/socket/route'
import { createDiceState, rollRound } from '@/lib/game/dice'
import { createSeededRng } from '@/lib/game/combat'

function freshMatch() {
  const dice = createDiceState(
    { id: 'char-1', name: 'P', maxHp: 500, hit: 60, agi: 30, atk: ['warrior.wrath', null, null, null, null, null] },
    { id: 'npc_warrior_1', name: 'Bot', maxHp: 500, hit: 60, agi: 10 },
  )
  rollRound(dice, createSeededRng(7))
  return {
    id: 'match-1', status: 'in_progress', player1Id: 'char-1', player2Id: null,
    opponentType: 'bot', interactiveTimeoutAt: new Date(Date.now() + 60_000),
    interactiveChoices: [], interactiveActives: { dice }, updatedAt: new Date(),
  }
}

const post = (fn: (r: never) => Promise<Response>, url: string, body: unknown) =>
  fn(makeNextRequest(url, { method: 'POST', body: JSON.stringify(body), headers: { 'content-type': 'application/json' } }) as never)
    .then(async (res) => ({ status: res.status, json: await res.json() }))

describe('POST /api/pvp/dice/act', () => {
  beforeEach(() => { vi.clearAllMocks(); state.writes = []; state.updateCount = 1; state.match = freshMatch() })

  it('rerolls a die once per round and spends Focus', async () => {
    const r = await post(act, 'http://localhost/api/pvp/dice/act', { match_id: 'match-1', round: 1, action: { type: 'reroll', die: 'a' } })
    expect(r.status).toBe(200)
    expect(r.json.face).toBeGreaterThanOrEqual(0)
    expect(r.json.dice.p.focus).toBe(0)
    expect(r.json.dice.acted).toEqual({ type: 'reroll', die: 'a' })
    // hidden AI action never leaks
    expect(JSON.stringify(r.json)).not.toMatch(/"o":\{"type"/)
    const saved = state.writes[0].interactiveActives as { dice: Record<string, unknown> }
    state.match = { ...freshMatch(), interactiveActives: saved }
    const again = await post(act, 'http://localhost/api/pvp/dice/act', { match_id: 'match-1', round: 1, action: { type: 'reroll', die: 'd' } })
    expect(again.status).toBe(409)
    expect(again.json.error).toBe('already_acted')
  })

  it('rejects a set-face it cannot afford and a stale round', async () => {
    const r = await post(act, 'http://localhost/api/pvp/dice/act', { match_id: 'match-1', round: 1, action: { type: 'set', die: 'a', face: 0 } })
    expect(r.status).toBe(409)
    expect(r.json.error).toBe('not_enough_focus')
    const stale = await post(act, 'http://localhost/api/pvp/dice/act', { match_id: 'match-1', round: 3, action: { type: 'reroll', die: 'a' } })
    expect(stale.status).toBe(409)
  })

  it('refuses a non-dice match', async () => {
    state.match = { ...freshMatch(), interactiveActives: { p1: [], p2: [] } }
    const r = await post(act, 'http://localhost/api/pvp/dice/act', { match_id: 'match-1', round: 1, action: { type: 'reroll', die: 'a' } })
    expect(r.status).toBe(409)
  })
})

describe('POST /api/pvp/dice/resolve', () => {
  beforeEach(() => { vi.clearAllMocks(); state.writes = []; state.updateCount = 1; state.match = freshMatch() })

  it('resolves the round, stores a complete-compatible record and rolls the next one', async () => {
    const r = await post(resolve, 'http://localhost/api/pvp/dice/resolve', { match_id: 'match-1', round: 1 })
    expect(r.status).toBe(200)
    expect(r.json.round).toBe(1)
    expect(r.json.events.some((e: { t: string }) => e.t === 'strike')).toBe(true)
    expect(r.json.dice.round).toBe(2)
    const w = state.writes[0]
    const rounds = w.interactiveChoices as Array<Record<string, unknown>>
    expect(rounds).toHaveLength(1)
    expect(rounds[0]).toMatchObject({ idx: 0, attacker_hp_after: expect.any(Number), defender_hp_after: expect.any(Number) })
    expect(['head', 'chest', 'legs']).toContain(rounds[0].player_atk)
    expect(w.interactiveStrikeIndex).toBe(1)
  })

  it('is deterministic for the same match + round', async () => {
    const a = await post(resolve, 'http://localhost/api/pvp/dice/resolve', { match_id: 'match-1', round: 1 })
    state.match = freshMatch()
    const b = await post(resolve, 'http://localhost/api/pvp/dice/resolve', { match_id: 'match-1', round: 1 })
    expect(a.json.events).toEqual(b.json.events)
  })

  it('returns 409 when a concurrent write wins', async () => {
    state.updateCount = 0
    const r = await post(resolve, 'http://localhost/api/pvp/dice/resolve', { match_id: 'match-1', round: 1 })
    expect(r.status).toBe(409)
  })
})

describe('POST /api/dice/socket', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    state.dieRunes = []
    state.liveMatch = null
    state.character = { id: 'char-1', userId: 'user-1', class: 'warrior', level: 25 }
    state.passives = [
      { node: { nodeKey: 'warrior.rune.wrath' } },
      { node: { nodeKey: 'warrior.ult.unleash' } },
      { node: { nodeKey: 'warrior.key.headsman' } },
      { node: { nodeKey: 'warrior.rune.mail' } },
    ]
  })

  const sock = (b: Record<string, unknown>) => post(socket, 'http://localhost/api/dice/socket', { character_id: 'char-1', ...b })

  it('sockets an owned rune and moves it when placed again', async () => {
    const a = await sock({ die: 'atk', face_index: 0, rune_key: 'warrior.wrath' })
    expect(a.status).toBe(200)
    expect(a.json.dice.atk.runes[0]).toBe('warrior.wrath')
    const b = await sock({ die: 'atk', face_index: 3, rune_key: 'warrior.wrath' })
    expect(b.json.dice.atk.runes[0]).toBeNull()
    expect(b.json.dice.atk.runes[3]).toBe('warrior.wrath')
  })

  it('refuses unowned runes, the wrong die, and a live match', async () => {
    expect((await sock({ die: 'atk', face_index: 0, rune_key: 'warrior.frenzy' })).status).toBe(403)
    expect((await sock({ die: 'grd', face_index: 0, rune_key: 'warrior.wrath' })).status).toBe(400)
    state.liveMatch = { id: 'm' }
    expect((await sock({ die: 'atk', face_index: 0, rune_key: 'warrior.wrath' })).status).toBe(409)
  })

  it('respects sockets by level', async () => {
    state.character = { id: 'char-1', userId: 'user-1', class: 'warrior', level: 2 }
    expect((await sock({ die: 'grd', face_index: 1, rune_key: 'warrior.mail' })).status).toBe(409) // L2: 0 guard sockets
    expect((await sock({ die: 'atk', face_index: 0, rune_key: 'warrior.wrath' })).status).toBe(200)
    expect((await sock({ die: 'atk', face_index: 2, rune_key: 'warrior.beast' })).status).toBe(409) // 1 atk socket, used
  })

  it('takes a rune off with rune_key null', async () => {
    await sock({ die: 'atk', face_index: 0, rune_key: 'warrior.wrath' })
    const r = await sock({ die: 'atk', face_index: 0, rune_key: null })
    expect(r.json.dice.atk.runes[0]).toBeNull()
  })
})
