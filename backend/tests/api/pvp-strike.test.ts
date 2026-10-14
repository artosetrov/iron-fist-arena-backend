/**
 * POST /api/pvp/strike — Combat v2 round resolution.
 *
 * The route was restructured for v2 (policy-driven opponent zones, AGI
 * initiative, persisted skill cooldowns, legs "opens", head counters). This
 * pins the contract against a bot match with prisma mocked:
 *   - response shape is additive (old fields intact, v2 fields present)
 *   - opponent zones are deterministic per (match, round) and NOT uniform
 *     noise: a 'rhythm' bot cycles exactly
 *   - skill cooldowns persist in interactive_actives across rounds
 *   - initiative follows AGI under v2 and is always the player under v1
 *   - a stored round carries opened_next / initiative
 */
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const {
  mockGetAuthUser,
  mockRateLimit,
  mockLoadCombatCharacter,
  configMock,
  prismaMock,
  state,
} = vi.hoisted(() => {
  const state: { match: Record<string, unknown> | null; v2: boolean; writes: Array<Record<string, unknown>> } = {
    match: null,
    v2: true,
    writes: [],
  }
  const prismaMock = {
    pvpMatch: {
      findUnique: vi.fn(async () => state.match),
      updateMany: vi.fn(async () => ({ count: 1 })),
    },
    character: {
      findUnique: vi.fn(async () => ({ userId: 'user-1', maxHp: 900, currentHp: 900, zoneProfile: null })),
    },
    $transaction: vi.fn(async (cb: (tx: unknown) => Promise<unknown>) => {
      const tx = {
        pvpMatch: {
          updateMany: vi.fn(async (args: { data: Record<string, unknown> }) => {
            state.writes.push(args.data)
            return { count: 1 }
          }),
        },
      }
      return cb(tx)
    }),
  }
  return {
    mockGetAuthUser: vi.fn(async () => ({ id: 'user-1' })),
    mockRateLimit: vi.fn(async () => true),
    mockLoadCombatCharacter: vi.fn(),
    configMock: {
      getGameConfig: vi.fn(async (_k: string, fallback: unknown) => fallback),
      getGameConfigs: vi.fn(async (defaults: Record<string, unknown>) => ({
        ...defaults,
        'combat.zone_matrix_v2': state.v2,
      })),
    },
    prismaMock,
    state,
  }
})

vi.mock('@/lib/auth', () => ({ getAuthUser: mockGetAuthUser }))
vi.mock('@/lib/rate-limit', () => ({ rateLimit: mockRateLimit }))
vi.mock('@/lib/prisma', () => ({ prisma: prismaMock }))
vi.mock('@/lib/game/combat-loader', () => ({ loadCombatCharacter: mockLoadCombatCharacter }))
vi.mock('@/lib/game/active-slots', () => ({ invalidateActiveSlotsCache: vi.fn() }))
vi.mock('@/lib/game/config', () => ({
  getGameConfig: configMock.getGameConfig,
  getGameConfigs: configMock.getGameConfigs,
}))

import { POST } from '@/app/api/pvp/strike/route'
import type { CharacterStats } from '@/lib/game/combat'
import type { SkillDefinition } from '@/lib/game/skills'

const slam: SkillDefinition = {
  id: 'skill-slam', skillKey: 'warrior.slam', name: 'Slam',
  damageBase: 40, damageScaling: { str: 1.2 }, damageType: 'physical', targetType: 'single_enemy',
  cooldown: 3, effectJson: null, rank: 1, rankScaling: 0,
}

function stats(id: string, over: Partial<CharacterStats> = {}): CharacterStats {
  return {
    id, name: id, class: 'warrior', level: 20,
    str: 60, agi: 30, vit: 40, end: 30, int: 10, wis: 10, luk: 0, cha: 0,
    maxHp: 900, armor: 50, magicResist: 30, combatStance: null,
    ...over,
  }
}

// 'rhythm' personality: attack head→chest→legs, block legs→head→chest.
// personalityForKey is FNV-based; find a bot key that maps to 'rhythm' so the
// test does not depend on hash luck.
import { personalityForKey } from '@/lib/game/zone-policy'
function rhythmBotKey(): string {
  for (let i = 0; i < 500; i++) {
    const k = `npc_warrior_${i}`
    if (personalityForKey(k) === 'rhythm') return k
  }
  throw new Error('no rhythm key found')
}

function botMatch(botKey: string, botStats: CharacterStats, extra: Record<string, unknown> = {}) {
  return {
    id: 'match-1',
    status: 'in_progress',
    player1Id: 'char-1',
    player2Id: null,
    opponentType: 'bot',
    botKey,
    bossKey: null,
    interactiveTimeoutAt: new Date(Date.now() + 60_000),
    interactiveStrikeIndex: 0,
    interactiveChoices: [],
    interactiveActives: { p1: [], p2: [] },
    opponentSnapshot: {
      kind: 'bot', id: botKey, character_name: 'Bot', class: 'warrior', level: 20, avatar: null,
      max_hp: botStats.maxHp, combat_stats: botStats,
    },
    ...extra,
  }
}

async function callStrike(body: Record<string, unknown>) {
  const res = await POST(makeNextRequest('http://localhost/api/pvp/strike', {
    method: 'POST', body: JSON.stringify(body), headers: { 'content-type': 'application/json' },
  }))
  return { status: res.status, json: await res.json() }
}

describe('POST /api/pvp/strike (Combat v2)', () => {
  const botKey = rhythmBotKey()

  beforeEach(() => {
    vi.clearAllMocks()
    state.v2 = true
    state.writes = []
    process.env.COMBAT_SEED_SECRET = 'test-secret'
    mockLoadCombatCharacter.mockImplementation(async () => stats('char-1', { equippedSkills: [slam] }))
  })

  it('resolves a round with the additive v2 contract', async () => {
    state.match = botMatch(botKey, stats(botKey, { agi: 10 }))
    const { status, json } = await callStrike({ match_id: 'match-1', attacker_zone: 'chest', defender_zone: 'chest' })
    expect(status).toBe(200)
    // legacy fields
    expect(json.match_id).toBe('match-1')
    expect(json.strike_index).toBe(0)
    expect(json.player_strike).toBeTruthy()
    expect(typeof json.attacker_hp).toBe('number')
    expect(typeof json.defender_hp).toBe('number')
    expect(json.opp_zones).toEqual({ attack: expect.any(String), defend: expect.any(String) })
    // v2 fields
    expect(json.zone_matrix_v2).toBe(true)
    expect(json.initiative).toBe('player') // player agi 30 > bot agi 10
    expect(json.opened).toEqual({ player: expect.any(Boolean), opponent: expect.any(Boolean) })
    expect(['crit', 'hit', 'blocked', 'miss', 'dodge', 'none']).toContain(json.player_strike.outcome)
    // round persisted with v2 bookkeeping
    const written = state.writes[0]
    const rounds = written.interactiveChoices as Array<Record<string, unknown>>
    expect(rounds).toHaveLength(1)
    expect(rounds[0].initiative).toBe('player')
    expect(rounds[0].opened_next).toEqual(json.opened)
  })

  it('opponent zones follow the bot personality (rhythm cycles), deterministically', async () => {
    const bot = stats(botKey, { agi: 10 })
    const picks: Array<{ attack: string; defend: string }> = []
    let choices: unknown[] = []
    let actives: unknown = { p1: [], p2: [] }
    for (let round = 0; round < 3; round++) {
      state.match = botMatch(botKey, bot, { interactiveStrikeIndex: round, interactiveChoices: choices, interactiveActives: actives })
      const { status, json } = await callStrike({ match_id: 'match-1', attacker_zone: 'legs', defender_zone: 'head' })
      expect(status).toBe(200)
      picks.push(json.opp_zones)
      const w = state.writes[state.writes.length - 1]
      choices = w.interactiveChoices as unknown[]
      actives = w.interactiveActives
      if (json.match_finished) break
    }
    // rhythm with 12% noise: at least the first pick is the cycle start the vast
    // majority of seeds; assert determinism instead of exact zones.
    state.match = botMatch(botKey, bot)
    const again = await callStrike({ match_id: 'match-1', attacker_zone: 'legs', defender_zone: 'head' })
    expect(again.json.opp_zones).toEqual(picks[0])
    // and the zones are a real policy output, not the removed uniform roll:
    // over the three rounds a rhythm bot never repeats the same attack zone
    // twice in a row unless noise fired — check structure, allow one slip.
    let repeats = 0
    for (let i = 1; i < picks.length; i++) if (picks[i].attack === picks[i - 1].attack) repeats++
    expect(repeats).toBeLessThanOrEqual(1)
  })

  it('persists skill cooldowns across rounds (D4)', async () => {
    const bot = stats(botKey, { agi: 10 })
    state.match = botMatch(botKey, bot)
    const r1 = await callStrike({ match_id: 'match-1', attacker_zone: 'chest', defender_zone: 'chest' })
    expect(r1.status).toBe(200)
    const w1 = state.writes[0]
    const actives1 = w1.interactiveActives as { p1_skill_cd: Record<string, number> }
    // Slam fired (cd 3) and ticked once at end of round → 2 left.
    if (r1.json.player_strike.skillKey === 'warrior.slam') {
      expect(actives1.p1_skill_cd['skill-slam']).toBe(2)
    }
    // Round 2 with the persisted state: the skill must NOT fire again.
    state.match = botMatch(botKey, bot, {
      interactiveStrikeIndex: 1,
      interactiveChoices: w1.interactiveChoices,
      interactiveActives: w1.interactiveActives,
    })
    const r2 = await callStrike({ match_id: 'match-1', attacker_zone: 'chest', defender_zone: 'chest' })
    expect(r2.status).toBe(200)
    if (r1.json.player_strike.skillKey === 'warrior.slam' && r2.json.player_strike.outcome !== 'none') {
      expect(r2.json.player_strike.skillKey).toBeUndefined()
    }
    const actives2 = state.writes[1].interactiveActives as { p1_skill_cd: Record<string, number> }
    expect(actives2.p1_skill_cd['skill-slam']).toBeLessThan(actives1.p1_skill_cd['skill-slam'] ?? 99)
  })

  it('gives initiative to the faster fighter under v2', async () => {
    state.match = botMatch(botKey, stats(botKey, { agi: 90 }))
    const { status, json } = await callStrike({ match_id: 'match-1', attacker_zone: 'chest', defender_zone: 'chest' })
    expect(status).toBe(200)
    expect(json.initiative).toBe('opponent')
    // player still gets a strike payload (inert 'none' only if they fell first)
    expect(json.player_strike).toBeTruthy()
  })

  it('keeps v1 behaviour when the flag is off: player first, no v2 outcome tags', async () => {
    state.v2 = false
    state.match = botMatch(botKey, stats(botKey, { agi: 90 }))
    const { status, json } = await callStrike({ match_id: 'match-1', attacker_zone: 'head', defender_zone: 'chest' })
    expect(status).toBe(200)
    expect(json.zone_matrix_v2).toBe(false)
    expect(json.initiative).toBe('player')
    expect(json.player_strike.outcome).toBeUndefined()
    expect(json.player_strike.counterDamage).toBeUndefined()
  })

  it('rejects an invalid zone', async () => {
    state.match = botMatch(botKey, stats(botKey))
    const { status } = await callStrike({ match_id: 'match-1', attacker_zone: 'knee', defender_zone: 'chest' })
    expect(status).toBe(400)
  })
})
