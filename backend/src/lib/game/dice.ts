// =============================================================================
// dice.ts — dice combat engine (pure, deterministic given an RNG)
// Spec: docs/06_game_systems/DICE_RUNES_DESIGN.md, prototype "Hexbound Dice Duel"
// =============================================================================
//
// Round flow (server-authoritative; the routes only wire seeds + persistence):
//   1. rollRound   — four dice land (boss: telegraphed attack + phase-2 2nd die).
//                    The AI's simultaneous decision is taken here, on the
//                    pre-action roll, and kept server-side until the reveal.
//   2. applyAction — the player may spend Focus once: reroll a die (2) or set a
//                    face (4).
//   3. resolveRound — AI action lands, DoTs tick, on_land runes, stance/omen,
//                    both strikes by initiative, on_hit / on_block / on_take
//                    runes, statuses for next round, Focus +1, next roll.
//
// Faces are indices 0..5 into FACE_ZONES; a die's runes are a 6-slot array of
// rune keys (null = bare face).

import { DICE } from './balance'
import type { SeededRng } from './combat'
import { RUNE_PARAMS as RP, runeSlug } from './runes'

export type Zone = 'head' | 'chest' | 'legs'
export const FACE_ZONES: readonly Zone[] = ['head', 'head', 'chest', 'chest', 'legs', 'legs']
export const zoneOf = (face: number): Zone => FACE_ZONES[((face % 6) + 6) % 6]

export type DieId = 'a' | 'd'
export type SideId = 'p' | 'o'

export interface DiceConfig {
  HEAD_MULT: number
  CHEST_MULT: number
  LEGS_MULT: number
  FOCUS_START: number
  FOCUS_PER_ROUND: number
  FOCUS_MAX: number
  REROLL_COST: number
  SET_FACE_COST: number
  MAX_ROUNDS: number
  FATIGUE_START_ROUND: number
  FATIGUE_PER_ROUND: number
  DAMAGE_VARIANCE: number
  DAMAGE_SCALE: number
  WINDOW_MS: number
  BOSS_PHASE2_HP: number
  BOSS_SECOND_DIE_MULT: number
}
export const DEFAULT_DICE_CONFIG: DiceConfig = { ...DICE }

export interface Dot { kind: 'bleed' | 'poison' | 'burn'; dmg: number; rounds: number }

export interface DiceSide {
  id: string
  name: string
  hp: number
  maxHp: number
  focus: number
  /** One plain ×1 hit against this opponent (stats, passives, resists folded in). */
  hit: number
  /** Lifesteal %, from passives. */
  lifesteal: number
  agi: number
  /** Rune key per face, 6 slots each. */
  atk: (string | null)[]
  grd: (string | null)[]
  /** Rounds (including this one) the guard is broken by a sweep. */
  opened: number
  dots: Dot[]
  stunned: boolean
  frozen: boolean
  boss: boolean
  /** Focus spent this round (Time rune refunds it). */
  spent: number
  // effects scheduled for next round
  nextOpened: number
  nextStunned: boolean
  nextFrozen: boolean
  nextTaunt: Zone | null
}

export interface DiceRoll { a: number; d: number; a2?: number | null }

export type DiceAction =
  | { type: 'reroll'; die: DieId }
  | { type: 'set'; die: DieId; face: number }

export interface DiceState {
  v: 1
  round: number
  finished: boolean
  winner: SideId | null
  p: DiceSide
  o: DiceSide
  roll: { p: DiceRoll; o: DiceRoll }
  /** Actions taken this round. `o` is hidden from the client until resolve. */
  acted: { p: DiceAction | null; o: DiceAction | null }
  /** Boss telegraph: the face its attack die will show next round. */
  bossNext: number | null
  cfg: DiceConfig
}

export interface SideInit {
  id: string
  name: string
  maxHp: number
  hp?: number
  hit: number
  lifesteal?: number
  agi: number
  atk?: (string | null)[]
  grd?: (string | null)[]
  boss?: boolean
}

// --- events (what the client animates, in order) ------------------------------

export type StrikeOut = 'crit' | 'hit' | 'pierce' | 'blocked' | 'miss' | 'stunned'

export type DiceEvent =
  | { t: 'dot'; side: SideId; kind: Dot['kind']; dmg: number; hp: HpSnap }
  | { t: 'omen'; hp: HpSnap }
  | { t: 'stance'; side: SideId; focus: number; hp: HpSnap }
  | { t: 'act'; side: SideId; action: DiceAction; face: number; focus: number; hp: HpSnap }
  | {
      t: 'strike'; from: SideId; die: 'a' | 'a2'; out: StrikeOut; dmg: number
      zone: Zone; guard: Zone; opens: boolean; halved: boolean
      runes: string[]; heal: number; hp: HpSnap
    }
  | { t: 'rune'; side: SideId; die: DieId; rune: string; fx: RuneFx; value: number; focus: number; hp: HpSnap }

export type RuneFx = 'focus' | 'heal' | 'counter' | 'reflect' | 'bleed' | 'poison' | 'burn' | 'stun' | 'freeze' | 'taunt'
export interface HpSnap { p: number; o: number }

// --- setup ---------------------------------------------------------------------

const six = (arr?: (string | null)[]): (string | null)[] =>
  Array.from({ length: 6 }, (_, i) => (arr && typeof arr[i] === 'string' ? arr[i] : null))

function makeSide(init: SideInit, cfg: DiceConfig): DiceSide {
  return {
    id: init.id,
    name: init.name,
    hp: Math.max(1, Math.round(init.hp ?? init.maxHp)),
    maxHp: Math.max(1, Math.round(init.maxHp)),
    focus: cfg.FOCUS_START,
    hit: Math.max(1, Math.round(init.hit)),
    lifesteal: Math.max(0, Math.min(50, init.lifesteal ?? 0)),
    agi: init.agi,
    atk: six(init.atk),
    grd: six(init.grd),
    opened: 0,
    dots: [],
    stunned: false,
    frozen: false,
    boss: init.boss === true,
    spent: 0,
    nextOpened: 0,
    nextStunned: false,
    nextFrozen: false,
    nextTaunt: null,
  }
}

export function createDiceState(p: SideInit, o: SideInit, cfg: DiceConfig = DEFAULT_DICE_CONFIG): DiceState {
  return {
    v: 1,
    round: 1,
    finished: false,
    winner: null,
    p: makeSide(p, cfg),
    o: makeSide(o, cfg),
    roll: { p: { a: 0, d: 0 }, o: { a: 0, d: 0 } },
    acted: { p: null, o: null },
    bossNext: null,
    cfg,
  }
}

const d6 = (rng: SeededRng) => Math.min(5, Math.floor(rng() * 6))

const firstFaceOf = (zone: Zone): number => FACE_ZONES.indexOf(zone)

export const bossPhase2 = (s: DiceState, side: DiceSide = s.o): boolean =>
  side.boss && side.hp <= side.maxHp * s.cfg.BOSS_PHASE2_HP

/** Roll the round's dice and take the AI's simultaneous decision on the raw roll. */
export function rollRound(s: DiceState, rng: SeededRng): void {
  const roll = (side: DiceSide, telegraph: number | null): DiceRoll => {
    let a = telegraph ?? d6(rng)
    const d = d6(rng)
    if (side.nextTaunt) { a = firstFaceOf(side.nextTaunt); side.nextTaunt = null }
    const r: DiceRoll = { a, d }
    if (side.boss && bossPhase2(s, side)) r.a2 = d6(rng)
    return r
  }
  s.roll = { p: roll(s.p, null), o: roll(s.o, s.o.boss ? s.bossNext : null) }
  // Boss telegraph: next round's attack face is decided now and shown to the player.
  s.bossNext = s.o.boss ? d6(rng) : null
  s.acted = { p: null, o: null }
  s.p.spent = 0
  s.o.spent = 0
  s.acted.o = s.o.boss ? null : aiDecide(s, 'o')
}

// --- actions ------------------------------------------------------------------

export type ActionError = 'finished' | 'already_acted' | 'not_enough_focus' | 'frozen' | 'bad_face' | 'same_face'

export function actionCost(s: DiceState, a: DiceAction): number {
  return a.type === 'reroll' ? s.cfg.REROLL_COST : s.cfg.SET_FACE_COST
}

export function validateAction(s: DiceState, side: SideId, a: DiceAction): ActionError | null {
  if (s.finished) return 'finished'
  const me = s[side]
  if (side === 'p' && s.acted.p) return 'already_acted'
  if (me.focus < actionCost(s, a)) return 'not_enough_focus'
  if (a.die === 'a' && me.frozen) return 'frozen'
  if (a.type === 'set') {
    if (!Number.isInteger(a.face) || a.face < 0 || a.face > 5) return 'bad_face'
    if (s.roll[side][a.die] === a.face) return 'same_face'
  }
  return null
}

/** Apply one Focus action. Returns the face the die now shows. */
export function applyAction(s: DiceState, side: SideId, a: DiceAction, rng: SeededRng): number {
  const me = s[side]
  const cost = actionCost(s, a)
  me.focus -= cost
  me.spent += cost
  const face = a.type === 'reroll' ? d6(rng) : a.face
  s.roll[side][a.die] = face
  if (side === 'p') s.acted.p = a
  return face
}

// --- the strike -----------------------------------------------------------------

export interface StrikeCalc {
  out: 'crit' | 'hit' | 'pierce' | 'blocked' | 'miss'
  /** Multiplier on the attacker's hit (0 when blocked). */
  mult: number
  /** What the strike would have done unblocked — for Mirror/Bastion reflects. */
  rawMult: number
  opens: number
  missChance: number
  halved: boolean
  /** Rune slugs that shaped this strike (passive effects), attacker then defender. */
  firedA: string | null
  firedD: string | null
}

interface StrikeCtx {
  atkFace: number
  atkRune: string | null       // slug
  grdFace: number
  grdRune: string | null       // slug
  ownGuardRune: string | null  // attacker's own guard face — Oath buffs the strike
  defOpened: boolean
  omen: boolean
  attackerFirst: boolean
  attackerFrozen: boolean
  defHpPct: number
  defPoisoned: boolean
}

export function strikeCalc(c: StrikeCtx, cfg: DiceConfig = DEFAULT_DICE_CONFIG): StrikeCalc {
  const zone = zoneOf(c.atkFace)
  const gZone = zoneOf(c.grdFace)
  const ar = c.atkRune
  const guardActive = !c.defOpened
  const gr = guardActive ? c.grdRune : null

  let mult = zone === 'head' ? cfg.HEAD_MULT : zone === 'legs' ? cfg.LEGS_MULT : cfg.CHEST_MULT
  let crit = zone === 'head'
  let opens = zone === 'legs' ? 1 : 0
  let unblockable = false
  let ignoresWall = false
  let firedA: string | null = null
  let firedD: string | null = null

  switch (ar) {
    case 'blade': mult *= RP.blade.mult; firedA = ar; break
    case 'spark': mult *= RP.spark.mult; ignoresWall = true; firedA = ar; break
    case 'ram': mult *= RP.ram.mult; if (zone === 'legs') opens = RP.ram.sweepRounds; firedA = ar; break
    case 'flame': ignoresWall = true; break
    case 'beast': mult = Math.max(mult, RP.beast.mult); crit = true; firedA = ar; break
    case 'meteor': mult = Math.max(mult, RP.meteor.mult); crit = true; unblockable = true; firedA = ar; break
    case 'reaper': mult = Math.max(mult, RP.reaper.mult); crit = true; firedA = ar; if (c.defPoisoned) unblockable = true; break
    case 'headsman':
      if (c.defHpPct < RP.headsman.hpBelow) { mult = Math.max(mult, RP.headsman.mult); crit = true; unblockable = true; firedA = ar }
      break
    case 'shadowstrike':
      if (c.attackerFirst) { mult = Math.max(mult, RP.shadowstrike.mult); crit = true; unblockable = true; firedA = ar }
      break
    case 'challenge': mult *= RP.challenge.mult; firedA = ar; break
    default: break
  }
  if (c.ownGuardRune === 'oath') mult *= RP.oath.strikeBonus
  if (c.attackerFrozen) mult *= RP.frost.strikeMult
  if (c.omen) { mult = Math.max(mult, cfg.HEAD_MULT); crit = true }
  const rawMult = mult

  const base = { rawMult, opens: 0, halved: false }
  const blocked = !c.omen && !unblockable && guardActive && gZone === zone
  if (blocked) {
    if (ar === 'dagger') {
      // The pierce goes through the block, not through the armour runes:
      // Mail/Barrier/Stone/Unbreakable reduce what the holder takes on an
      // open face, so they must reduce the pierce too. Returning before that
      // block made a blocked Dagger (×0.8) hit harder than an unblocked one
      // into Stone (×0.6) — blocking was the wrong call (2026-10-16 audit).
      let pierce = mult * RP.dagger.pierce
      let armourRune: string | null = null
      if (gr === 'mail') { pierce *= RP.mail.take; armourRune = gr }
      if (gr === 'barrier') { pierce *= RP.barrier.take; armourRune = gr }
      if (gr === 'stone') { pierce *= RP.stone.take; armourRune = gr }
      if (gr === 'unbreakable') { pierce *= RP.unbreakable.take; armourRune = gr }
      return { ...base, out: 'pierce', mult: pierce, missChance: 0, firedA: ar, firedD: armourRune }
    }
    return { ...base, out: 'blocked', mult: 0, missChance: 0, firedA, firedD: gr }
  }

  let missChance = 0
  let halved = false
  if (gr && !c.omen) {
    if (gr === 'smoke') { missChance = RP.smoke.missChance; firedD = gr }
    if (gr === 'vanish') { missChance = RP.vanish.missChance; firedD = gr }
    const otherZone = gr === 'wall' ? RP.wall.otherZone : gr === 'oath' ? RP.oath.otherZone : gr === 'bastion' ? RP.bastion.otherZone : 1
    if (otherZone < 1 && !(gr === 'wall' && ignoresWall)) { mult *= otherZone; halved = true; firedD = gr }
  }
  if (gr === 'mail') { mult *= RP.mail.take; firedD = gr }
  if (gr === 'barrier') { mult *= RP.barrier.take; firedD = gr }
  if (gr === 'stone') { mult *= RP.stone.take; firedD = gr }
  if (gr === 'unbreakable') { mult *= RP.unbreakable.take; firedD = gr }
  if (ar === 'frenzy') { mult *= 1 + RP.frenzy.extra; firedA = ar }

  return { out: crit ? 'crit' : 'hit', mult, rawMult, opens, missChance, halved, firedA, firedD }
}

const other = (side: SideId): SideId => (side === 'p' ? 'o' : 'p')

export function playerStrikesFirst(s: DiceState): boolean {
  return s.p.agi > s.o.agi || (s.p.agi === s.o.agi && s.round % 2 === 1)
}

export function isOmen(s: DiceState): boolean {
  const z = [s.roll.p.a, s.roll.p.d, s.roll.o.a, s.roll.o.d].map(zoneOf)
  return z.every((x) => x === z[0])
}

function ctxFor(s: DiceState, from: SideId, atkFace: number, omen: boolean): StrikeCtx {
  const me = s[from]
  const foe = s[other(from)]
  const grdFace = s.roll[other(from)].d
  return {
    atkFace,
    atkRune: runeSlug(me.atk[atkFace]),
    grdFace,
    grdRune: runeSlug(foe.grd[grdFace]),
    ownGuardRune: runeSlug(me.grd[s.roll[from].d]),
    defOpened: foe.opened > 0,
    omen,
    attackerFirst: (from === 'p') === playerStrikesFirst(s),
    attackerFrozen: me.frozen,
    defHpPct: foe.hp / foe.maxHp,
    defPoisoned: foe.dots.some((d) => d.kind === 'poison'),
  }
}

/** Deterministic preview of `from`'s main strike on the current roll (UI chips + AI). */
export function previewStrike(s: DiceState, from: SideId): StrikeCalc & { expected: number } {
  const omen = isOmen(s)
  const calc = strikeCalc(ctxFor(s, from, s.roll[from].a, omen), s.cfg)
  const stunned = s[from].stunned
  const expected = stunned ? 0 : Math.round(s[from].hit * s.cfg.DAMAGE_SCALE * calc.mult * (1 - calc.missChance))
  return { ...calc, expected }
}

// --- AI -------------------------------------------------------------------------

const mean = (xs: number[]) => xs.reduce((t, x) => t + x, 0) / xs.length

/** Greedy one-step EV (prototype `decide`). Returns null when spending isn't worth it. */
export function aiDecide(s: DiceState, side: SideId): DiceAction | null {
  const me = s[side]
  const foe = s[other(side)]
  if (me.stunned) return null
  const omen = isOmen(s)
  const outV = (face: number) => {
    const c = strikeCalc(ctxFor(s, side, face, omen), s.cfg)
    return c.mult * (1 - c.missChance)
  }
  const inV = (guardFace: number) => {
    const saved = s.roll[side].d
    s.roll[side].d = guardFace
    const c = strikeCalc(ctxFor(s, other(side), s.roll[other(side)].a, omen), s.cfg)
    s.roll[side].d = saved
    return foe.stunned ? 0 : c.mult * (1 - c.missChance)
  }
  const out0 = outV(s.roll[side].a)
  const in0 = inV(s.roll[side].d)
  const faces = [0, 1, 2, 3, 4, 5]
  let best: DiceAction | null = null
  let bestGain = 0.15
  const consider = (a: DiceAction, gain: number) => { if (gain > bestGain) { best = a; bestGain = gain } }
  if (me.focus >= s.cfg.REROLL_COST) {
    if (!me.frozen) consider({ type: 'reroll', die: 'a' }, (mean(faces.map(outV)) - out0) * me.hit / s.cfg.REROLL_COST)
    consider({ type: 'reroll', die: 'd' }, (in0 - mean(faces.map(inV))) * foe.hit / s.cfg.REROLL_COST)
  }
  if (me.focus >= s.cfg.SET_FACE_COST) {
    if (!me.frozen) {
      const bA = faces.reduce((b, f) => (outV(f) > outV(b) ? f : b), 0)
      if (bA !== s.roll[side].a) consider({ type: 'set', die: 'a', face: bA }, (outV(bA) - out0) * me.hit / s.cfg.SET_FACE_COST)
    }
    const bD = faces.reduce((b, f) => (inV(f) < inV(b) ? f : b), 0)
    if (bD !== s.roll[side].d) consider({ type: 'set', die: 'd', face: bD }, (in0 - inV(bD)) * foe.hit / s.cfg.SET_FACE_COST)
  }
  return best
}

// --- resolve ----------------------------------------------------------------------

function finish(s: DiceState, winner: SideId) {
  s.finished = true
  s.winner = winner
}

/**
 * Resolve the current round. `rng` drives the AI's reroll, misses and variance;
 * `nextRng` rolls the next round (pass separate seeded streams so a reroll in
 * this round can't shift next round's dice).
 */
export function resolveRound(s: DiceState, rng: SeededRng, nextRng: SeededRng): DiceEvent[] {
  if (s.finished) return []
  const ev: DiceEvent[] = []
  const hp = (): HpSnap => ({ p: s.p.hp, o: s.o.hp })
  const cfg = s.cfg

  // 0. the opponent's simultaneous action lands
  const oAct = s.acted.o
  if (oAct && !validateAction(s, 'o', oAct)) {
    const face = applyAction(s, 'o', oAct, rng)
    ev.push({ t: 'act', side: 'o', action: oAct, face, focus: s.o.focus, hp: hp() })
  }

  // 1. damage over time from last round
  for (const id of ['p', 'o'] as SideId[]) {
    const me = s[id]
    for (const dot of me.dots) {
      me.hp = Math.max(0, me.hp - dot.dmg)
      dot.rounds -= 1
      ev.push({ t: 'dot', side: id, kind: dot.kind, dmg: dot.dmg, hp: hp() })
    }
    me.dots = me.dots.filter((d) => d.rounds > 0)
    if (me.hp <= 0) { finish(s, other(id)); return ev }
  }

  // 2. omen / stance / on_land
  const omen = isOmen(s)
  if (omen) ev.push({ t: 'omen', hp: hp() })
  const gainFocus = (id: SideId, n: number) => { s[id].focus = Math.min(cfg.FOCUS_MAX, s[id].focus + n) }
  for (const id of ['p', 'o'] as SideId[]) {
    const r = s.roll[id]
    if (!omen && zoneOf(r.a) === zoneOf(r.d)) {
      gainFocus(id, 1)
      ev.push({ t: 'stance', side: id, focus: s[id].focus, hp: hp() })
    }
    const ar = runeSlug(s[id].atk[r.a])
    const gr = runeSlug(s[id].grd[r.d])
    if (ar === 'mana') { gainFocus(id, RP.mana.focus); ev.push({ t: 'rune', side: id, die: 'a', rune: ar, fx: 'focus', value: RP.mana.focus, focus: s[id].focus, hp: hp() }) }
    if (gr === 'flow') { gainFocus(id, RP.flow.focus); ev.push({ t: 'rune', side: id, die: 'd', rune: gr, fx: 'focus', value: RP.flow.focus, focus: s[id].focus, hp: hp() }) }
    if (gr === 'time') {
      // Refunds Focus spent on the attack die only — setting the guard onto
      // Time itself must not be free.
      const refund = s.acted[id]?.die === 'a' ? s[id].spent : 0
      const n = refund + RP.time.bonus
      gainFocus(id, n)
      ev.push({ t: 'rune', side: id, die: 'd', rune: gr, fx: 'focus', value: n, focus: s[id].focus, hp: hp() })
    }
  }

  // 3. strikes by initiative (boss phase 2 adds a second, weaker strike)
  const fatigue = 1 + Math.max(0, s.round - cfg.FATIGUE_START_ROUND) * cfg.FATIGUE_PER_ROUND
  const pFirst = playerStrikesFirst(s)
  const order: Array<{ from: SideId; die: 'a' | 'a2' }> = pFirst
    ? [{ from: 'p', die: 'a' }, { from: 'o', die: 'a' }]
    : [{ from: 'o', die: 'a' }, { from: 'p', die: 'a' }]
  if (s.roll.o.a2 != null) order.push({ from: 'o', die: 'a2' })

  for (const step of order) {
    const from = step.from
    const to = other(from)
    const A = s[from]
    const D = s[to]
    if (A.hp <= 0 || D.hp <= 0) continue
    const atkFace = step.die === 'a2' ? (s.roll[from].a2 as number) : s.roll[from].a
    const guardFace = s.roll[to].d
    const base = { from, die: step.die, zone: zoneOf(atkFace), guard: zoneOf(guardFace), halved: false, heal: 0 }

    if (A.stunned) {
      ev.push({ t: 'strike', ...base, out: 'stunned', dmg: 0, opens: false, runes: [], hp: hp() })
      continue
    }

    const c = strikeCalc(ctxFor(s, from, atkFace, omen), cfg)
    const runes = [c.firedA, c.firedD].filter((x): x is string => !!x)
    const missed = c.out === 'miss' || (c.missChance > 0 && rng() < c.missChance)
    if (missed) {
      ev.push({ t: 'strike', ...base, out: 'miss', dmg: 0, opens: false, runes, hp: hp() })
      const gr = runeSlug(D.grd[guardFace])
      if (gr === 'vanish') {
        gainFocus(to, RP.vanish.focus)
        ev.push({ t: 'rune', side: to, die: 'd', rune: gr, fx: 'focus', value: RP.vanish.focus, focus: D.focus, hp: hp() })
      }
      continue
    }

    const gr = D.opened > 0 ? null : runeSlug(D.grd[guardFace])
    const scale = step.die === 'a2' ? cfg.BOSS_SECOND_DIE_MULT : 1
    const vuln = runeSlug(D.atk[s.roll[to].a]) === 'beast' ? RP.beast.selfVuln : 1
    const variance = 1 - cfg.DAMAGE_VARIANCE + rng() * cfg.DAMAGE_VARIANCE * 2
    const unit = A.hit * cfg.DAMAGE_SCALE * fatigue * scale
    const freeze = (rune: string) => {
      A.nextFrozen = true
      ev.push({ t: 'rune', side: to, die: 'd', rune, fx: 'freeze', value: 1, focus: D.focus, hp: hp() })
    }

    if (c.out === 'blocked') {
      ev.push({ t: 'strike', ...base, out: 'blocked', dmg: 0, opens: false, runes, hp: hp() })
      // on_block — the defender's guard rune answers
      const onBlockFocus = (rune: string, n: number) => {
        gainFocus(to, n)
        ev.push({ t: 'rune', side: to, die: 'd', rune, fx: 'focus', value: n, focus: D.focus, hp: hp() })
      }
      const heal = (rune: string, pct: number) => {
        const h = Math.max(1, Math.round(D.maxHp * pct))
        D.hp = Math.min(D.maxHp, D.hp + h)
        ev.push({ t: 'rune', side: to, die: 'd', rune, fx: 'heal', value: h, focus: D.focus, hp: hp() })
      }
      const hurtAttacker = (rune: string, fx: RuneFx, dmg: number) => {
        const d = Math.max(1, Math.round(dmg))
        A.hp = Math.max(0, A.hp - d)
        ev.push({ t: 'rune', side: to, die: 'd', rune, fx, value: d, focus: D.focus, hp: hp() })
      }
      if (gr === 'frost') freeze(gr)
      switch (gr) {
        case 'endurance': heal(gr, RP.endurance.healPct); break
        case 'fortify': heal(gr, RP.fortify.healPct); break
        case 'bulwark': heal(gr, RP.bulwark.healPct); onBlockFocus(gr, RP.bulwark.focus); break
        case 'evasion': onBlockFocus(gr, RP.evasion.focus); break
        case 'riposte': hurtAttacker(gr, 'counter', D.hit * cfg.DAMAGE_SCALE * fatigue * RP.riposte.counter); break
        case 'mirror': hurtAttacker(gr, 'reflect', unit * c.rawMult * RP.mirror.reflect); break
        case 'bastion': hurtAttacker(gr, 'reflect', unit * c.rawMult * RP.bastion.reflect); break
        default: break
      }
      if (A.hp <= 0) { finish(s, to); break }
      continue
    }

    // a hit (or a Dagger pierce)
    let dmg = Math.max(1, Math.round(unit * c.mult * vuln * variance))
    if (gr === 'unbreakable' && D.hp < D.maxHp * RP.unbreakable.hpBelow) {
      const cap = Math.max(1, Math.round(D.maxHp * RP.unbreakable.capPct))
      if (dmg > cap) { dmg = cap; runes.push('unbreakable') }
    }
    D.hp = Math.max(0, D.hp - dmg)
    let healed = 0
    if (A.lifesteal > 0) {
      healed = Math.floor((dmg * A.lifesteal) / 100)
      if (healed > 0) A.hp = Math.min(A.maxHp, A.hp + healed)
    }
    const opens = c.opens > 0 && D.hp > 0
    if (opens) D.nextOpened = Math.max(D.nextOpened, c.opens)
    ev.push({ t: 'strike', ...base, out: c.out, dmg, opens, halved: c.halved, runes, heal: healed, hp: hp() })
    if (D.hp <= 0) { finish(s, from); break }

    // on_take — Frost, Bastion, Thorns
    if (gr === 'frost') freeze(gr)
    if (gr === 'bastion') {
      const back = Math.max(1, Math.round(unit * c.rawMult * RP.bastion.reflect))
      A.hp = Math.max(0, A.hp - back)
      ev.push({ t: 'rune', side: to, die: 'd', rune: gr, fx: 'reflect', value: back, focus: D.focus, hp: hp() })
      if (A.hp <= 0) { finish(s, to); break }
    }
    if (gr === 'thorns') {
      const back = Math.max(1, Math.round(dmg * RP.thorns.reflect))
      A.hp = Math.max(0, A.hp - back)
      ev.push({ t: 'rune', side: to, die: 'd', rune: gr, fx: 'reflect', value: back, focus: D.focus, hp: hp() })
      if (A.hp <= 0) { finish(s, to); break }
    }

    // on_hit — the attacker's rune
    const ar = runeSlug(A.atk[atkFace])
    const dot = (rune: 'bloodletting' | 'venom' | 'flame', kind: Dot['kind']) => {
      const p = RP[rune]
      const tick = Math.max(1, Math.round(dmg * p.pct))
      D.dots.push({ kind, dmg: tick, rounds: p.rounds })
      ev.push({ t: 'rune', side: from, die: 'a', rune, fx: kind, value: tick, focus: A.focus, hp: hp() })
    }
    switch (ar) {
      case 'wrath':
        gainFocus(from, RP.wrath.focus)
        ev.push({ t: 'rune', side: from, die: 'a', rune: ar, fx: 'focus', value: RP.wrath.focus, focus: A.focus, hp: hp() })
        break
      case 'bloodletting': dot('bloodletting', 'bleed'); break
      case 'venom': dot('venom', 'poison'); break
      case 'flame': dot('flame', 'burn'); break
      case 'challenge':
        D.nextTaunt = zoneOf(s.roll[from].d)
        ev.push({ t: 'rune', side: from, die: 'a', rune: ar, fx: 'taunt', value: 1, focus: A.focus, hp: hp() })
        break
      case 'earthshatter':
        if (rng() >= RP.earthshatter.stunChance) break
        D.nextStunned = true
        ev.push({ t: 'rune', side: from, die: 'a', rune: ar, fx: 'stun', value: 1, focus: A.focus, hp: hp() })
        break
      default: break
    }
  }

  // 4. end of round: statuses roll forward, Focus ticks, next dice
  for (const id of ['p', 'o'] as SideId[]) {
    const me = s[id]
    me.opened = Math.max(me.opened - 1, me.nextOpened)
    me.nextOpened = 0
    me.stunned = me.nextStunned
    me.nextStunned = false
    me.frozen = me.nextFrozen
    me.nextFrozen = false
  }
  if (!s.finished) {
    gainFocus('p', cfg.FOCUS_PER_ROUND)
    gainFocus('o', cfg.FOCUS_PER_ROUND)
    s.round += 1
    if (s.round > cfg.MAX_ROUNDS) {
      finish(s, s.p.hp / s.p.maxHp >= s.o.hp / s.o.maxHp ? 'p' : 'o')
    } else {
      rollRound(s, nextRng)
    }
  }
  return ev
}

// --- client view ----------------------------------------------------------------

/** What the client may see: everything except the AI's hidden pending action. */
export function publicView(s: DiceState) {
  const side = (x: DiceSide) => ({
    id: x.id,
    hp: x.hp,
    max_hp: x.maxHp,
    focus: x.focus,
    atk: x.atk,
    grd: x.grd,
    opened: x.opened > 0,
    stunned: x.stunned,
    frozen: x.frozen,
    dots: x.dots.map((d) => ({ kind: d.kind, dmg: d.dmg, rounds: d.rounds })),
    boss: x.boss,
  })
  const pPrev = s.finished ? null : previewStrike(s, 'p')
  const oPrev = s.finished ? null : previewStrike(s, 'o')
  const chip = (c: ReturnType<typeof previewStrike> | null) =>
    c ? { out: c.out, expected: c.expected, miss_chance: c.missChance, opens: c.opens > 0, halved: c.halved } : null
  return {
    round: s.round,
    max_rounds: s.cfg.MAX_ROUNDS,
    finished: s.finished,
    winner: s.winner,
    player_first: playerStrikesFirst(s),
    omen: !s.finished && isOmen(s),
    roll: {
      p: { a: s.roll.p.a, d: s.roll.p.d },
      o: { a: s.roll.o.a, d: s.roll.o.d, a2: s.roll.o.a2 ?? null },
    },
    acted: s.acted.p,
    boss_next: s.bossNext,
    p: side(s.p),
    o: side(s.o),
    preview: { p: chip(pPrev), o: chip(oPrev) },
    rules: {
      reroll_cost: s.cfg.REROLL_COST,
      set_face_cost: s.cfg.SET_FACE_COST,
      focus_max: s.cfg.FOCUS_MAX,
      window_ms: s.cfg.WINDOW_MS,
    },
  }
}
