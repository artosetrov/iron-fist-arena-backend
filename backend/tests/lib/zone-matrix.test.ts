/**
 * Zone matrix v2 + interactive cooldowns (Combat v2, COMBAT_V2_DESIGN.md §3, D4).
 *
 * Runs the real engine with config mocked to balance.ts defaults and the
 * `combat.zone_matrix_v2` flag toggled per test. Pins:
 *   - the pure matrix cells
 *   - v1 (flag off) emits no v2 fields — old clients and old matches are untouched
 *   - v2 turns carry `outcome`; head into a block never crits and counters;
 *     legs into the open opens the defender; the opened block is ignored
 *   - resolveSingleStrike honours a persisted cooldown state (D4)
 */
import { beforeEach, describe, expect, it, vi } from 'vitest'

const configMock = vi.hoisted(() => ({
  getGameConfig: vi.fn(),
  getGameConfigs: vi.fn(),
}))
vi.mock('@/lib/prisma', () => ({ prisma: {} }))
vi.mock('../../src/lib/game/config', () => ({
  getGameConfig: configMock.getGameConfig,
  getGameConfigs: configMock.getGameConfigs,
}))

import {
  createSeededRng,
  resolveSingleStrike,
  runCombat,
  zoneMatrixEffect,
  type CharacterStats,
  type Turn,
} from '../../src/lib/game/combat'
import { ZONE_MATRIX } from '../../src/lib/game/balance'
import type { SkillCooldownState, SkillDefinition } from '../../src/lib/game/skills'

function fighter(id: string, over: Partial<CharacterStats> = {}): CharacterStats {
  return {
    id, name: id, class: 'warrior', level: 20,
    str: 60, agi: 30, vit: 40, end: 30, int: 10, wis: 10, luk: 10, cha: 0,
    maxHp: 900, armor: 50, magicResist: 30,
    combatStance: { attack: 'chest', defense: 'chest' },
    zonePolicy: { kind: 'personality', personality: 'rhythm' },
    ...over,
  }
}

function useV2(on: boolean) {
  configMock.getGameConfig.mockImplementation(async (_k: string, fallback: unknown) => fallback)
  configMock.getGameConfigs.mockImplementation(async (defaults: Record<string, unknown>) => ({
    ...defaults,
    'combat.zone_matrix_v2': on,
  }))
}

describe('zoneMatrixEffect', () => {
  it('encodes the design table', () => {
    expect(zoneMatrixEffect('head', false, ZONE_MATRIX)).toEqual({ mult: ZONE_MATRIX.HEAD_CRIT_MULT, forcedCrit: true, counterMult: 0, opens: false })
    expect(zoneMatrixEffect('head', true, ZONE_MATRIX)).toEqual({ mult: ZONE_MATRIX.HEAD_BLOCKED_MULT, forcedCrit: false, counterMult: ZONE_MATRIX.HEAD_COUNTER_MULT, opens: false })
    expect(zoneMatrixEffect('chest', false, ZONE_MATRIX)).toEqual({ mult: 1, forcedCrit: false, counterMult: 0, opens: false })
    expect(zoneMatrixEffect('chest', true, ZONE_MATRIX)).toEqual({ mult: ZONE_MATRIX.CHEST_BLOCKED_MULT, forcedCrit: false, counterMult: 0, opens: false })
    expect(zoneMatrixEffect('legs', false, ZONE_MATRIX)).toEqual({ mult: ZONE_MATRIX.LEGS_OPEN_MULT, forcedCrit: false, counterMult: 0, opens: true })
    expect(zoneMatrixEffect('legs', true, ZONE_MATRIX)).toEqual({ mult: ZONE_MATRIX.LEGS_BLOCKED_MULT, forcedCrit: false, counterMult: 0, opens: false })
  })

  it('has no option that is best against every block (no dominant attack)', () => {
    // Expected multiplier vs each of the three blocks; "best" must change with the block.
    const best = (['head', 'chest', 'legs'] as const).map((block) =>
      (['head', 'chest', 'legs'] as const)
        .map((atk) => ({ atk, v: zoneMatrixEffect(atk, atk === block, ZONE_MATRIX).mult - zoneMatrixEffect(atk, atk === block, ZONE_MATRIX).counterMult }))
        .sort((a, b) => b.v - a.v)[0].atk,
    )
    expect(new Set(best).size).toBeGreaterThan(1)
  })
})

describe('runCombat under v1 (flag off)', () => {
  beforeEach(() => { vi.clearAllMocks(); useV2(false) })

  it('emits no v2 fields and keeps the legacy stance rotation', async () => {
    const r = await runCombat(fighter('a'), fighter('b'), 123)
    expect(r.turns.length).toBeGreaterThan(0)
    for (const t of r.turns) {
      expect(t.outcome).toBeUndefined()
      expect(t.counterDamage).toBeUndefined()
      expect(t.opensDefender).toBeUndefined()
    }
  })
})

describe('runCombat under v2', () => {
  beforeEach(() => { vi.clearAllMocks(); useV2(true) })

  async function manyTurns(n: number): Promise<Turn[]> {
    const turns: Turn[] = []
    for (let i = 0; i < n; i++) {
      // aggressor vs turtle: lots of head-into-block and legs-into-open
      const r = await runCombat(
        fighter('a', { zonePolicy: { kind: 'personality', personality: 'aggressor' } }),
        fighter('b', { zonePolicy: { kind: 'personality', personality: 'turtle' } }),
        1000 + i,
      )
      turns.push(...r.turns)
    }
    return turns
  }

  it('tags every landed strike with an outcome', async () => {
    const turns = await manyTurns(20)
    for (const t of turns) {
      expect(['crit', 'hit', 'blocked', 'miss', 'dodge']).toContain(t.outcome)
    }
  })

  it('head into the open is always a crit; head into a block never is and draws a counter', async () => {
    const turns = await manyTurns(40)
    const headOpen = turns.filter((t) => t.targetZone === 'head' && t.outcome !== 'blocked' && t.damage > 0)
    const headBlocked = turns.filter((t) => t.targetZone === 'head' && t.outcome === 'blocked')
    expect(headOpen.length).toBeGreaterThan(10)
    expect(headBlocked.length).toBeGreaterThan(10)
    expect(headOpen.every((t) => t.isCrit)).toBe(true)
    expect(headBlocked.every((t) => !t.isCrit && (t.counterDamage ?? 0) > 0)).toBe(true)
    // the forced crit is bigger than the blocked hit by construction
    const avg = (xs: Turn[]) => xs.reduce((s, t) => s + t.damage, 0) / xs.length
    expect(avg(headOpen)).toBeGreaterThan(avg(headBlocked) * 3)
  })

  it('legs into the open opens the defender; a blocked strike into an opened defender is not blocked', async () => {
    let legsOpen = 0
    let checked = 0
    for (let i = 0; i < 40; i++) {
      const r = await runCombat(
        fighter('a', { zonePolicy: { kind: 'personality', personality: 'aggressor' } }),
        fighter('b', { zonePolicy: { kind: 'personality', personality: 'turtle' } }),
        1000 + i,
      )
      const turns = r.turns
      for (let j = 0; j < turns.length; j++) {
        const t = turns[j]
        if (t.targetZone === 'legs' && t.outcome !== 'blocked' && t.damage > 0) {
          legsOpen++
          expect(t.opensDefender).toBe(true)
        }
        if (!t.opensDefender) continue
        // same fight: the opener's next swing cannot be blocked, zones be damned
        const next = turns.slice(j + 1).find((u) => u.attackerId === t.attackerId && u.turnNumber === t.turnNumber + 1)
        if (!next) continue
        checked++
        expect(next.outcome).not.toBe('blocked')
      }
    }
    expect(legsOpen).toBeGreaterThan(5)
    expect(checked).toBeGreaterThan(3)
  })

  it('still ends in a kill within the round cap for a mirror', async () => {
    let kills = 0
    for (let i = 0; i < 30; i++) {
      const r = await runCombat(fighter('a'), fighter('b'), 5000 + i)
      if (r.finalHp.a === 0 || r.finalHp.b === 0) kills++
    }
    expect(kills / 30).toBeGreaterThan(0.8)
  })
})

describe('resolveSingleStrike — persisted skill cooldowns (D4)', () => {
  beforeEach(() => { vi.clearAllMocks(); useV2(true) })

  const slam: SkillDefinition = {
    id: 'skill-slam', skillKey: 'warrior.slam', name: 'Slam',
    damageBase: 40, damageScaling: { str: 1.2 }, damageType: 'physical', targetType: 'single_enemy',
    cooldown: 2, effectJson: null, rank: 1, rankScaling: 0,
  }

  async function strike(cd: SkillCooldownState, seed: number) {
    return resolveSingleStrike({
      attacker: fighter('a', { equippedSkills: [slam], cha: 0, agi: 0, luk: 0 }),
      defender: fighter('b', { cha: 0, agi: 0, luk: 0 }),
      attackerZone: 'chest', defenderZone: 'head', defenderHp: 900, seed, turn: 1,
      cooldownState: cd,
    })
  }

  it('fires the skill once, then auto-attacks until the cooldown ticks down', async () => {
    const cd: SkillCooldownState = {}
    const first = await strike(cd, 1)
    expect(first.turn.skillKey).toBe('warrior.slam')
    expect(cd['skill-slam']).toBe(2)

    // Same persisted state, no tick yet → the skill is NOT available again.
    const second = await strike(cd, 2)
    expect(second.turn.skillKey).toBeUndefined()

    // Legacy behaviour (no state passed) would have fired it every strike.
    const legacy = await strike({}, 3)
    expect(legacy.turn.skillKey).toBe('warrior.slam')
  })

  it('counter damage is reported for head into block and the turn is tagged blocked', async () => {
    const r = await resolveSingleStrike({
      attacker: fighter('a', { cha: 0, agi: 0, luk: 0 }),
      defender: fighter('b', { cha: 0, agi: 0, luk: 0 }),
      attackerZone: 'head', defenderZone: 'head', defenderHp: 900, seed: 77, turn: 1,
    })
    expect(r.turn.outcome).toBe('blocked')
    expect(r.turn.isCrit).toBe(false)
    expect(r.counterDamage).toBeGreaterThan(0)
    expect(r.turn.counterDamage).toBe(r.counterDamage)
  })

  it('an opened defender does not block', async () => {
    const r = await resolveSingleStrike({
      attacker: fighter('a', { cha: 0, agi: 0, luk: 0 }),
      defender: fighter('b', { cha: 0, agi: 0, luk: 0 }),
      attackerZone: 'head', defenderZone: 'head', defenderHp: 900, seed: 77, turn: 1,
      defenderOpened: true,
    })
    expect(r.turn.outcome).toBe('crit')
    expect(r.counterDamage).toBe(0)
  })

  it('is deterministic for a seed', async () => {
    const a = await strike({}, 99)
    const b = await strike({}, 99)
    expect(a.turn).toEqual(b.turn)
    void createSeededRng
  })
})
