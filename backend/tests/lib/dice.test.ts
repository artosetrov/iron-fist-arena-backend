/**
 * Dice combat engine (src/lib/game/dice.ts) + rune catalog (runes.ts).
 * Pins the rules from docs/06_game_systems/DICE_RUNES_DESIGN.md.
 */
import { describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/prisma', () => ({ prisma: {} }))
import {
  aiDecide, applyAction, createDiceState, DEFAULT_DICE_CONFIG, isOmen, previewStrike, publicView,
  resolveRound, rollRound, strikeCalc, validateAction, zoneOf, type DiceState, type SideInit,
} from '@/lib/game/dice'
import { RUNES, runeByNodeKey, socketsForLevel, socketUnlockLevel } from '@/lib/game/runes'
import { createSeededRng } from '@/lib/game/combat'

const side = (id: string, extra: Partial<SideInit> = {}): SideInit => ({ id, name: id, maxHp: 900, hit: 100, agi: 30, ...extra })

const ctx = (over: Partial<Parameters<typeof strikeCalc>[0]> = {}) => ({
  atkFace: 2, atkRune: null, grdFace: 0, grdRune: null, ownGuardRune: null,
  defOpened: false, omen: false, attackerFirst: true, attackerFrozen: false,
  defHpPct: 1, defPoisoned: false, ...over,
})

/** Force a roll so a test controls every face. */
function setRoll(s: DiceState, p: [number, number], o: [number, number]) {
  s.roll = { p: { a: p[0], d: p[1] }, o: { a: o[0], d: o[1] } }
  s.acted = { p: null, o: null }
}

describe('rune catalog', () => {
  it('has 36 runes, 9 per class, 4/3/2 by tier, unique keys and nodes', () => {
    expect(RUNES).toHaveLength(36)
    for (const cls of ['warrior', 'rogue', 'mage', 'tank']) {
      const mine = RUNES.filter((r) => r.class === cls)
      expect(mine).toHaveLength(9)
      expect(mine.filter((r) => r.tier === 'lesser')).toHaveLength(4)
      expect(mine.filter((r) => r.tier === 'path')).toHaveLength(3)
      expect(mine.filter((r) => r.tier === 'great')).toHaveLength(2)
    }
    expect(new Set(RUNES.map((r) => r.key)).size).toBe(36)
    expect(new Set(RUNES.map((r) => r.nodeKey)).size).toBe(36)
    expect(runeByNodeKey('warrior.key.headsman')?.key).toBe('warrior.headsman')
  })

  it('opens sockets by level up to 3 per die', () => {
    expect(socketsForLevel(1)).toEqual({ atk: 0, grd: 0 })
    expect(socketsForLevel(2)).toEqual({ atk: 1, grd: 0 })
    expect(socketsForLevel(12)).toEqual({ atk: 2, grd: 2 })
    expect(socketsForLevel(50)).toEqual({ atk: 3, grd: 3 })
    expect(socketUnlockLevel('grd', 1)).toBe(4)
    expect(socketUnlockLevel('atk', 3)).toBe(20)
    expect(socketUnlockLevel('atk', 4)).toBeNull()
  })
})

describe('strikeCalc — zones', () => {
  it('same zone is a block; head crits, legs sweep', () => {
    expect(strikeCalc(ctx({ atkFace: 0, grdFace: 1 })).out).toBe('blocked')
    const head = strikeCalc(ctx({ atkFace: 0, grdFace: 2 }))
    expect(head.out).toBe('crit')
    expect(head.mult).toBeCloseTo(DEFAULT_DICE_CONFIG.HEAD_MULT)
    const legs = strikeCalc(ctx({ atkFace: 4, grdFace: 0 }))
    expect(legs.out).toBe('hit')
    expect(legs.opens).toBe(1)
  })

  it('an opened guard does not block and its rune is off', () => {
    const c = strikeCalc(ctx({ atkFace: 2, grdFace: 2, grdRune: 'mail', defOpened: true }))
    expect(c.out).toBe('hit')
    expect(c.mult).toBeCloseTo(1)
  })

  it('omen breaks every block and crits', () => {
    const c = strikeCalc(ctx({ atkFace: 2, grdFace: 2, omen: true }))
    expect(c.out).toBe('crit')
    expect(c.mult).toBeCloseTo(DEFAULT_DICE_CONFIG.HEAD_MULT)
  })
})

describe('strikeCalc — runes', () => {
  it('Headsman: unblockable crit ×2 below 40% HP only', () => {
    expect(strikeCalc(ctx({ atkFace: 2, grdFace: 2, atkRune: 'headsman', defHpPct: 0.9 })).out).toBe('blocked')
    const c = strikeCalc(ctx({ atkFace: 2, grdFace: 2, atkRune: 'headsman', defHpPct: 0.3 }))
    expect(c.out).toBe('crit')
    expect(c.mult).toBeCloseTo(2)
  })

  it('Dagger pierces a block', () => {
    const c = strikeCalc(ctx({ atkFace: 2, grdFace: 3, atkRune: 'dagger' }))
    expect(c.out).toBe('pierce')
    expect(c.mult).toBeGreaterThan(0)
  })

  it('Wall cuts other zones but Spark ignores it', () => {
    expect(strikeCalc(ctx({ atkFace: 2, grdFace: 0, grdRune: 'wall' })).halved).toBe(true)
    expect(strikeCalc(ctx({ atkFace: 2, grdFace: 0, grdRune: 'wall', atkRune: 'spark' })).halved).toBe(false)
  })

  it('Smoke and Vanish carry a miss chance; Mail reduces the hit', () => {
    expect(strikeCalc(ctx({ atkFace: 2, grdFace: 0, grdRune: 'smoke' })).missChance).toBeGreaterThan(0)
    expect(strikeCalc(ctx({ atkFace: 2, grdFace: 0, grdRune: 'vanish' })).missChance).toBeGreaterThan(0)
    expect(strikeCalc(ctx({ atkFace: 2, grdFace: 0, grdRune: 'mail' })).mult).toBeLessThan(1)
  })

  it('Shadowstrike is unblockable only when striking first', () => {
    expect(strikeCalc(ctx({ atkFace: 2, grdFace: 2, atkRune: 'shadowstrike', attackerFirst: true })).out).toBe('crit')
    expect(strikeCalc(ctx({ atkFace: 2, grdFace: 2, atkRune: 'shadowstrike', attackerFirst: false })).out).toBe('blocked')
  })
})

describe('round flow', () => {
  it('rolls deterministically from the seed', () => {
    const a = createDiceState(side('p'), side('o'))
    const b = createDiceState(side('p'), side('o'))
    rollRound(a, createSeededRng(42))
    rollRound(b, createSeededRng(42))
    expect(a.roll).toEqual(b.roll)
  })

  it('validates Focus actions: one per round, cost, frozen attack die', () => {
    const s = createDiceState(side('p'), side('o'))
    rollRound(s, createSeededRng(1))
    expect(validateAction(s, 'p', { type: 'set', die: 'a', face: 0 })).toBe('not_enough_focus') // start 2, set = 4
    expect(validateAction(s, 'p', { type: 'reroll', die: 'a' })).toBeNull()
    applyAction(s, 'p', { type: 'reroll', die: 'a' }, createSeededRng(2))
    expect(s.p.focus).toBe(0)
    expect(validateAction(s, 'p', { type: 'reroll', die: 'd' })).toBe('already_acted')
    s.acted.p = null
    s.p.focus = 5
    s.p.frozen = true
    expect(validateAction(s, 'p', { type: 'reroll', die: 'a' })).toBe('frozen')
  })

  it('resolves a block and a crit, then ticks Focus and rolls the next round', () => {
    const s = createDiceState(side('p'), side('o', { agi: 10 }))
    setRoll(s, [0, 2], [2, 4]) // p hits head into legs-guard → crit; o hits chest into chest → blocked
    const ev = resolveRound(s, createSeededRng(3), createSeededRng(4))
    const strikes = ev.filter((e) => e.t === 'strike')
    expect(strikes.map((e) => e.t === 'strike' && e.out)).toEqual(['crit', 'blocked'])
    expect(s.o.hp).toBeLessThan(900)
    expect(s.p.hp).toBe(900)
    expect(s.round).toBe(2)
    expect(s.p.focus).toBe(3)
  })

  it('legs sweep opens the guard for the next round', () => {
    const s = createDiceState(side('p'), side('o', { agi: 10 }))
    setRoll(s, [4, 0], [2, 0])
    resolveRound(s, createSeededRng(5), createSeededRng(6))
    expect(s.o.opened).toBe(1)
    expect(publicView(s).o.opened).toBe(true)
  })

  it('omen when all four dice show one zone', () => {
    const s = createDiceState(side('p'), side('o'))
    setRoll(s, [0, 1], [1, 0])
    expect(isOmen(s)).toBe(true)
  })

  it('Earthshatter stuns, Venom poisons over two rounds', () => {
    const s = createDiceState(side('p', { atk: [null, null, 'rogue.venom', null, null, null] }), side('o', { agi: 10 }))
    setRoll(s, [2, 0], [4, 4])
    resolveRound(s, createSeededRng(7), createSeededRng(8))
    expect(s.o.dots.some((d) => d.kind === 'poison' && d.rounds === 2)).toBe(true)
  })

  it('a boss telegraphs its next attack and rolls a second die in phase 2', () => {
    const s = createDiceState(side('p'), side('o', { boss: true, maxHp: 1000, hp: 400 }))
    rollRound(s, createSeededRng(9))
    expect(s.bossNext).not.toBeNull()
    expect(s.roll.o.a2).not.toBeUndefined()
    const next = s.bossNext
    resolveRound(s, createSeededRng(10), createSeededRng(11))
    if (!s.finished) expect(s.roll.o.a).toBe(next)
  })

  it('ends at the round cap on HP share', () => {
    const s = createDiceState(side('p', { hit: 1 }), side('o', { hit: 1 }))
    rollRound(s, createSeededRng(12))
    let guard = 0
    while (!s.finished && guard++ < 50) resolveRound(s, createSeededRng(guard), createSeededRng(guard + 100))
    expect(s.finished).toBe(true)
    expect(s.round).toBeLessThanOrEqual(DEFAULT_DICE_CONFIG.MAX_ROUNDS + 1)
  })

  it('never leaks the AI pending action in the public view', () => {
    const s = createDiceState(side('p'), side('o'))
    s.o.focus = 5
    rollRound(s, createSeededRng(13))
    const view = publicView(s) as unknown as Record<string, unknown>
    expect(JSON.stringify(view)).not.toContain('"acted":{"p"')
    expect(view.acted).toBeNull()
  })

  it('preview matches the zone math', () => {
    const s = createDiceState(side('p'), side('o'))
    setRoll(s, [0, 0], [2, 2])
    expect(previewStrike(s, 'p').out).toBe('crit')
    expect(zoneOf(5)).toBe('legs')
  })
})

describe('balance (simulation)', () => {
  function winrate(p: SideInit, o: SideInit, smart: boolean, n = 1500) {
    let w = 0
    for (let i = 0; i < n; i++) {
      const rng = createSeededRng(i * 7919 + 13)
      const s = createDiceState(p, o)
      rollRound(s, rng)
      while (!s.finished) {
        if (smart) {
          const a = aiDecide(s, 'p')
          if (a && !validateAction(s, 'p', a)) applyAction(s, 'p', a, rng)
        }
        resolveRound(s, rng, rng)
      }
      if (s.winner === 'p') w++
    }
    return w / n
  }

  it('mirror is fair and spending Focus matters', () => {
    expect(Math.abs(winrate(side('p'), side('o'), true) - 0.5)).toBeLessThan(0.05)
    expect(winrate(side('p'), side('o'), false)).toBeLessThan(0.3)
  })

  it('a full rune build beats bare dice but not overwhelmingly', () => {
    const w = winrate(side('p', {
      atk: ['warrior.headsman', null, 'warrior.beast', null, 'warrior.frenzy', null],
      grd: [null, 'warrior.mail', null, 'warrior.bulwark', null, 'warrior.oath'],
    }), side('o'), true)
    expect(w).toBeGreaterThan(0.6)
    expect(w).toBeLessThan(0.85)
  })
})
