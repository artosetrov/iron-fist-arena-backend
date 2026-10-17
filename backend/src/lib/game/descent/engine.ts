// =============================================================================
// descent/engine.ts — pure game logic for Dungeon Rush v2 "The Descent"
//
// A run is a JSON state machine stored in DungeonRun.state (v: 2). Every player
// action goes through applyAction(): it validates the action against the
// current screen, mutates a copy of the state, and returns
//   • the new state,
//   • fx      — short-lived hints for client animation (damage numbers, …),
//   • effects — side effects the route must apply in the same transaction
//               (grant XP, claim bag loot, count kills, end the run).
//
// No I/O happens here. Randomness comes from the injected rng so tests can be
// deterministic. Real catalog items are resolved by the route: the engine
// only emits { kind: 'pending_item' } loot entries.
// =============================================================================

import {
  BOSS_CUE, CHESTS, CUES, DEPTHS, DESCENT, EVENT_IDS, EVENT_SCENE, MOBS, RELICS, RELIC_KEYS,
  TYPE_NAME, ZONES, ZONE_MULT,
  type ChestTier, type EventId, type MobKey, type NodeType, type RelicKey, type Zone,
} from './content'

export type Rng = () => number

// --- State types ---------------------------------------------------------------

export type Screen =
  | 'depthCard' | 'fork' | 'combat' | 'spoils' | 'chest' | 'event'
  | 'camp' | 'merchant' | 'relic' | 'depthClear' | 'result'

export type Outcome = 'victory' | 'escaped' | 'dead' | 'abandoned'
export type FightKind = 'combat' | 'elite' | 'boss'
export type LootSource = 'combat' | 'elite' | 'boss' | 'mimic' | 'chest' | 'troll'

export interface MapNode {
  id: string
  r: number
  lane: number
  type: NodeType
  dark: boolean
  mimic: boolean
  next: string[]
  visited: boolean
  cleared: boolean
  fled: boolean
  cue: string
}

export interface DescentMap {
  rows: MapNode[][]
  startNext: string[]
}

export interface BagItemEntry {
  kind: 'item'
  catalogItemId: string
  name: string
  itemType: string
  rarity: string
  itemLevel: number
  baseStats: Record<string, number>
  rolledStats: Record<string, number>
  imageKey: string | null
  imageUrl: string | null
  sellPrice: number
}

export interface BagShardEntry {
  kind: 'shard'
  tier: 'common' | 'rare' | 'epic' | 'legendary'
  amount: number
  rarity: string
}

export type BagEntry = BagItemEntry | BagShardEntry

export type LootEntry =
  | { kind: 'gold'; n: number }
  | { kind: 'xp'; n: number }
  | { kind: 'potion'; n: number }
  | { kind: 'torch'; n: number }
  | { kind: 'relic'; k: RelicKey }
  | { kind: 'pending_item'; source: LootSource }
  | { kind: 'bag'; entry: BagEntry }

export type LineTone = 'good' | 'bad' | 'info' | 'plain'
export interface Line { text: string; tone: LineTone }

export interface RoundResult {
  action: 'strike' | 'brace' | 'potion'
  pa: Zone
  pg: Zone
  ea: Zone
  eg: Zone
  pHit: boolean
  eBlock: boolean
  dodged: boolean
  crit: boolean
  dealt: number
  healed: number
  eHit: boolean
  pBlock: boolean
  taken: number
  crushing: boolean
  mended: number
}

export interface FightSpec {
  key: MobKey
  kind: FightKind
  firstStrike?: boolean
  ambush?: boolean
  bg?: string
}

export interface CombatState {
  key: MobKey
  name: string
  art: string
  traits: string[]
  kind: FightKind
  maxHp: number
  hp: number
  dmg: number
  level: number
  round: number
  windup: boolean
  enraged: boolean
  bg: string
  verdict: Line[]
  lastRound: RoundResult | null
}

export type CampChoice = 'rest' | 'sharpen' | 'stash'

export interface Ware {
  t: 'potion' | 'torch' | 'relic'
  k?: RelicKey
  price: number
  sold: boolean
}

export type EventThen = 'take_loot' | 'fight_now' | 'continue'

export type Room =
  | { t: 'spoils'; bg: string; loot: LootEntry[]; text: string }
  | { t: 'chest'; tier: ChestTier; mimic: boolean; inspected: boolean; opened: boolean; loot: LootEntry[] }
  | {
      t: 'event'; id: EventId | 'mimic'; done: boolean; text: string | null; loot: LootEntry[]
      then: EventThen | null; fight: FightSpec | null
      studied: boolean; trap: number; vault: number
    }
  | { t: 'camp'; done: boolean; text: string | null; k: CampChoice | null }
  | { t: 'merchant'; wares: Ware[] }
  | { t: 'relic'; loot: LootEntry[]; choices: RelicKey[]; text: string }

export interface RunScale {
  /** Multiplier from prototype gold to real gold for loot (level × CHA × premium × GOLD_SCALE). */
  gold: number
  /** Multiplier for merchant prices (level × GOLD_SCALE; no personal bonuses). */
  price: number
  /** Multiplier from prototype XP to real XP (level × XP_SCALE). */
  xp: number
}

export interface DescentState {
  v: 2
  seq: number
  screen: Screen
  depth: number
  map: DescentMap
  at: string
  prev: string | null
  hp: number
  maxHp: number
  potions: number
  torches: number
  dmgMult: number
  relics: RelicKey[]
  curse: number
  bag: { gold: number; items: BagEntry[] }
  safe: { gold: number; items: BagEntry[] }
  xp: number
  stats: { kills: number; rooms: number; chests: number }
  usedEvents: EventId[]
  room: Room | null
  combat: CombatState | null
  outcome: Outcome | null
  loss: { gold: number; items: BagEntry[] } | null
  revealed: string | null
  scale: RunScale
}

// --- Actions, fx, effects --------------------------------------------------------

export type Action =
  | { type: 'begin_depth' }
  | { type: 'torch'; nodeId: string }
  | { type: 'move'; nodeId: string }
  | { type: 'strike' }
  | { type: 'brace' }
  | { type: 'potion' }
  | { type: 'flee' }
  | { type: 'drink' }
  | { type: 'take_loot' }
  | { type: 'inspect' }
  | { type: 'open_chest' }
  | { type: 'leave' }
  | { type: 'choose'; i: number }
  | { type: 'continue' }
  | { type: 'fight_now' }
  | { type: 'camp'; k: CampChoice }
  | { type: 'buy'; i: number }
  | { type: 'take_relic'; k: RelicKey | null }
  | { type: 'descend' }
  | { type: 'escape' }
  | { type: 'abandon' }

export const ACTION_TYPES: ReadonlyArray<Action['type']> = [
  'begin_depth', 'torch', 'move', 'strike', 'brace', 'potion', 'flee', 'drink', 'take_loot', 'inspect',
  'open_chest', 'leave', 'choose', 'continue', 'fight_now', 'camp', 'buy', 'take_relic', 'descend', 'escape', 'abandon',
]

export interface Fx {
  target: 'hero' | 'enemy' | 'scene'
  kind: 'dmg' | 'crit' | 'hurt' | 'heal' | 'info' | 'reveal' | 'chest_open' | 'mimic' | 'slain' | 'coins'
  value?: number
  text?: string
}

export type Effect =
  | { type: 'xp'; amount: number }
  | { type: 'claim'; gold: number; entries: BagEntry[]; reason: 'stash' | 'escape' | 'victory' | 'death' | 'abandon' }
  | { type: 'kill'; kind: FightKind; mob: MobKey }
  | { type: 'end' }

export interface ApplyResult {
  state: DescentState
  fx: Fx[]
  effects: Effect[]
}

export class DescentError extends Error {
  constructor(public readonly code: 'INVALID_ACTION' | 'BAD_STATE', message: string) {
    super(message)
    this.name = 'DescentError'
  }
}

// --- RNG helpers ---------------------------------------------------------------

function chance(rng: Rng, p: number): boolean {
  return rng() < p
}
function pick<T>(rng: Rng, arr: readonly T[]): T {
  return arr[Math.floor(rng() * arr.length)]
}
function shuffle<T>(rng: Rng, arr: readonly T[]): T[] {
  const a = [...arr]
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1))
    ;[a[i], a[j]] = [a[j], a[i]]
  }
  return a
}
function rnd(rng: Rng, lo: number, hi: number): number {
  return lo + Math.floor(rng() * (hi - lo + 1))
}
function weighted<K>(rng: Rng, table: ReadonlyArray<readonly [K, number]>): K {
  const total = table.reduce((s, [, w]) => s + w, 0)
  let x = rng() * total
  for (const [k, w] of table) {
    if ((x -= w) < 0) return k
  }
  return table[0][0]
}
const clamp = (v: number, a: number, b: number) => Math.max(a, Math.min(b, v))

// --- Map generation ------------------------------------------------------------

export function genDepth(d: number, rng: Rng): DescentMap {
  const D = DEPTHS[d]
  const R = D.rows
  const rows: MapNode[][] = []
  for (let r = 0; r < R; r++) {
    let lanes: number[]
    if (r === 0) lanes = chance(rng, 0.5) ? [0, 2] : [0, 1, 2]
    else if (r === R - 1) lanes = chance(rng, 0.6) ? [0, 2] : [0, 1, 2]
    else lanes = chance(rng, 0.55) ? [0, 1, 2] : pick(rng, [[0, 1], [1, 2], [0, 2]])
    rows.push(lanes.map((l) => ({
      id: `${r}-${l}`, r, lane: l, type: 'combat' as NodeType, dark: false, mimic: false,
      next: [], visited: false, cleared: false, fled: false, cue: '',
    })))
  }
  const firstTypes = shuffle(rng, ['combat', 'combat', 'event'] as NodeType[])
  rows[0].forEach((n, i) => { n.type = firstTypes[i] ?? 'combat' })
  for (let r = 1; r < R - 1; r++) {
    for (const n of rows[r]) {
      n.type = weighted<NodeType>(rng, [
        ['combat', 34], ['event', 24], ['treasure', 18],
        ['elite', d === 0 && r === 1 ? 0 : 12],
        ['merchant', r >= 2 ? 6 : 0], ['camp', r >= 2 ? 6 : 0],
      ])
    }
  }
  const last = rows[R - 1]
  const lastTypes = shuffle(rng, ['camp', 'merchant', 'treasure'] as NodeType[])
  last.forEach((n, i) => { n.type = lastTypes[i] })
  if (!last.some((n) => n.type === 'camp')) last[0].type = 'camp'
  const mid = rows.slice(1, R - 1).flat()
  if (!rows.slice(0, R - 1).flat().some((n) => n.type === 'treasure') && mid.length) pick(rng, mid).type = 'treasure'
  if (d > 0 && mid.length && !mid.some((n) => n.type === 'elite')) {
    const combats = mid.filter((n) => n.type === 'combat')
    pick(rng, combats.length ? combats : mid).type = 'elite'
  }
  for (let r = 0; r < R - 1; r++) {
    const nxt = rows[r + 1]
    for (const n of rows[r]) {
      n.next = nxt.filter((m) => Math.abs(m.lane - n.lane) <= 1).map((m) => m.id)
      if (!n.next.length) {
        n.next = [nxt.reduce((a, m) => (Math.abs(m.lane - n.lane) < Math.abs(a.lane - n.lane) ? m : a)).id]
      }
    }
    for (const m of nxt) {
      if (!rows[r].some((n) => n.next.includes(m.id))) {
        const near = rows[r].reduce((a, n) => (Math.abs(n.lane - m.lane) < Math.abs(a.lane - m.lane) ? n : a))
        near.next.push(m.id)
      }
    }
  }
  const boss: MapNode = {
    id: 'B', r: R, lane: 1, type: 'boss', dark: false, mimic: false, next: [],
    visited: false, cleared: false, fled: false, cue: BOSS_CUE,
  }
  for (const n of last) n.next = ['B']
  rows.push([boss])
  for (const n of rows.flat()) {
    if (n.type === 'boss') continue
    n.cue = pick(rng, CUES[n.type][d])
    if (n.type !== 'camp' && n.type !== 'merchant') n.dark = chance(rng, D.dark)
    if (n.type === 'treasure') n.mimic = chance(rng, 0.16 + 0.07 * d)
  }
  return { rows, startNext: rows[0].map((n) => n.id) }
}

// --- Run creation ----------------------------------------------------------------

export function createRun(scale: RunScale, rng: Rng): DescentState {
  return {
    v: 2,
    seq: 0,
    screen: 'depthCard',
    depth: 0,
    map: genDepth(0, rng),
    at: 'S',
    prev: null,
    hp: DESCENT.HERO_HP,
    maxHp: DESCENT.HERO_HP,
    potions: DESCENT.START_POTIONS,
    torches: DESCENT.START_TORCHES,
    dmgMult: 1,
    relics: [],
    curse: 0,
    bag: { gold: 0, items: [] },
    safe: { gold: 0, items: [] },
    xp: 0,
    stats: { kills: 0, rooms: 0, chests: 0 },
    usedEvents: [],
    room: null,
    combat: null,
    outcome: null,
    loss: null,
    revealed: null,
    scale,
  }
}

export function isDescentState(value: unknown): value is DescentState {
  if (!value || typeof value !== 'object') return false
  const s = value as Partial<DescentState>
  return s.v === 2 && typeof s.screen === 'string' && !!s.map && Array.isArray(s.map.rows)
}

// --- Lookups ---------------------------------------------------------------------

export function findNode(state: DescentState, id: string): MapNode | null {
  for (const row of state.map.rows) for (const n of row) if (n.id === id) return n
  return null
}

/** Ids of the passages open from the current position. */
export function nextIds(state: DescentState): string[] {
  if (state.at === 'S') return state.map.startNext
  return findNode(state, state.at)?.next ?? []
}

export function currentRow(state: DescentState): number {
  if (state.at === 'S') return -1
  return findNode(state, state.at)?.r ?? -1
}

export const has = (state: DescentState, k: RelicKey) => state.relics.includes(k)

export function potionHeal(state: DescentState): number {
  return Math.round(state.maxHp * (has(state, 'alchemist') ? DESCENT.ALCHEMIST_POTION_HEAL : DESCENT.POTION_HEAL))
}

export function bgKey(state: DescentState, kind: 'hall' | 'elite' | 'arena'): string {
  return `rush2-bg-${DEPTHS[state.depth].key}-${kind}`
}

// --- Engine ------------------------------------------------------------------------

class Ctx {
  fx: Fx[] = []
  effects: Effect[] = []
  constructor(public s: DescentState, public rng: Rng) {}

  goldN(base: number): number {
    return Math.max(1, Math.round(base * this.s.scale.gold * (has(this.s, 'goldweave') ? 1.5 : 1)))
  }
  xpN(base: number): number {
    return Math.max(1, Math.round(base * this.s.scale.xp))
  }
  price(base: number): number {
    return Math.max(1, Math.round(base * this.s.scale.price))
  }

  heal(amount: number, target: Fx['target'] = 'hero'): number {
    const before = this.s.hp
    this.s.hp = clamp(Math.round(this.s.hp + amount), 0, this.s.maxHp)
    const got = this.s.hp - before
    if (got > 0) this.fx.push({ target, kind: 'heal', value: got })
    return got
  }

  hurt(amount: number): number {
    const a = Math.round(amount * (has(this.s, 'ironheart') ? 0.88 : 1))
    this.s.hp = clamp(this.s.hp - a, 0, this.s.maxHp)
    this.fx.push({ target: 'hero', kind: 'hurt', value: a })
    return a
  }

  addRelic(k?: RelicKey): RelicKey | null {
    let key: RelicKey | undefined = k
    if (!key) {
      const pool = RELIC_KEYS.filter((x) => !has(this.s, x))
      if (!pool.length) return null
      key = pick(this.rng, pool)
    }
    if (has(this.s, key)) return null
    this.s.relics.push(key)
    if (key === 'giantsbelt') {
      this.s.maxHp += 200
      this.s.hp += 200
    }
    return key
  }

  grantLoot(loot: LootEntry[]): void {
    for (const l of loot) {
      switch (l.kind) {
        case 'gold': this.s.bag.gold += l.n; break
        case 'potion': this.s.potions = Math.min(DESCENT.MAX_POTIONS, this.s.potions + l.n); break
        case 'torch': this.s.torches = Math.min(DESCENT.MAX_TORCHES, this.s.torches + l.n); break
        case 'relic': this.addRelic(l.k); break
        case 'bag': this.s.bag.items.push(l.entry); break
        case 'xp': break // already granted when the fight was won
        case 'pending_item': break // unresolved — dropped (route resolves before saving)
      }
    }
  }
}

function expect(cond: unknown, message: string): asserts cond {
  if (!cond) throw new DescentError('INVALID_ACTION', message)
}

function finishNode(c: Ctx): void {
  const n = findNode(c.s, c.s.at)
  if (n) n.cleared = true
  c.s.room = null
  c.s.combat = null
  c.s.screen = 'fork'
  c.s.revealed = null
}

function makeEnemy(c: Ctx, key: MobKey, kind: FightKind): CombatState {
  const D = DEPTHS[c.s.depth]
  const m = MOBS[key]
  let hp: number
  let dmg: number
  if (kind === 'boss') {
    hp = D.bossHp
    dmg = D.bossDmg
  } else {
    hp = Math.round(D.hp * (0.88 + c.rng() * 0.24))
    dmg = D.dmg
    if (kind === 'elite') {
      hp = Math.round(hp * 1.5)
      dmg = Math.round(dmg * 1.2)
    }
  }
  if (key === 'mimic') {
    hp = Math.round(D.hp * 1.45)
    dmg = Math.round(D.dmg * 1.2)
  }
  const here = currentRow(c.s) < 0 ? 0 : currentRow(c.s)
  return {
    key, name: m.name, art: m.art, traits: [...m.traits], kind,
    maxHp: hp, hp, dmg,
    level: 2 + c.s.depth * 5 + here + (kind === 'elite' ? 2 : 0),
    round: 0, windup: false, enraged: false,
    bg: bgKey(c.s, kind === 'boss' ? 'arena' : kind === 'elite' ? 'elite' : 'hall'),
    verdict: [], lastRound: null,
  }
}

function startFight(c: Ctx, spec: FightSpec): void {
  const e = makeEnemy(c, spec.key, spec.kind)
  if (spec.bg) e.bg = spec.bg
  if (spec.firstStrike) {
    e.hp = Math.round(e.hp * 0.7)
    e.verdict = [{ text: 'You strike first: it starts at 70% health.', tone: 'good' }]
  }
  if (spec.ambush) e.verdict = [{ text: 'Ambush! It bit you before you could react.', tone: 'bad' }]
  c.s.combat = e
  c.s.room = null
  c.s.screen = 'combat'
}

function rollPendingItem(source: LootSource): LootEntry {
  return { kind: 'pending_item', source }
}

function enterNode(c: Ctx, n: MapNode): void {
  const D = DEPTHS[c.s.depth]
  const d = c.s.depth
  switch (n.type) {
    case 'combat': return startFight(c, { key: pick(c.rng, D.mobs), kind: 'combat' })
    case 'elite': return startFight(c, { key: D.elite, kind: 'elite' })
    case 'boss': return startFight(c, { key: D.boss, kind: 'boss' })
    case 'treasure': {
      const tier = weighted<ChestTier>(c.rng, D.chests)
      const T = CHESTS[tier]
      const loot: LootEntry[] = [{ kind: 'gold', n: c.goldN((70 + 45 * d) * T.goldMult * (0.9 + c.rng() * 0.3)) }]
      if (chance(c.rng, 0.5)) loot.push({ kind: 'potion', n: 1 })
      if (chance(c.rng, 0.35)) loot.push({ kind: 'torch', n: 1 })
      if (chance(c.rng, 0.45 + T.itemBoost)) loot.push(rollPendingItem('chest'))
      if (chance(c.rng, 0.1 + 0.08 * d + T.itemBoost * 0.4)) {
        const pool = RELIC_KEYS.filter((k) => !has(c.s, k))
        if (pool.length) loot.push({ kind: 'relic', k: pick(c.rng, pool) })
      }
      c.s.room = { t: 'chest', tier, mimic: n.mimic, inspected: false, opened: false, loot }
      c.s.screen = 'chest'
      return
    }
    case 'event': {
      const pool = EVENT_IDS.filter((k) => !c.s.usedEvents.includes(k))
      const id = pick(c.rng, pool.length ? pool : EVENT_IDS)
      c.s.usedEvents.push(id)
      const order = shuffle(c.rng, [0, 1, 2])
      c.s.room = {
        t: 'event', id, done: false, text: null, loot: [], then: null, fight: null,
        studied: false, trap: order[0], vault: order[1],
      }
      c.s.screen = 'event'
      return
    }
    case 'camp':
      c.s.room = { t: 'camp', done: false, text: null, k: null }
      c.s.screen = 'camp'
      return
    case 'merchant': {
      const rel = shuffle(c.rng, RELIC_KEYS.filter((k) => !has(c.s, k))).slice(0, 2)
      const wares: Ware[] = [
        { t: 'potion', price: c.price(100), sold: false },
        { t: 'torch', price: c.price(45), sold: false },
        ...rel.map((k) => ({ t: 'relic' as const, k, price: c.price(240 + 40 * d), sold: false })),
      ]
      c.s.room = { t: 'merchant', wares }
      c.s.screen = 'merchant'
      return
    }
  }
}

// --- Death / claims ------------------------------------------------------------------

function claimBag(c: Ctx, reason: 'escape' | 'victory'): void {
  c.effects.push({ type: 'claim', gold: c.s.bag.gold, entries: [...c.s.bag.items], reason })
}

function endRun(c: Ctx, outcome: Outcome): void {
  c.s.outcome = outcome
  c.s.screen = 'result'
  c.s.combat = null
  c.s.room = null
  c.effects.push({ type: 'end' })
}

/** Death (or abandoning) costs half the bag: half the gold, half the items (an odd item out is a coin flip). */
function loseHalf(c: Ctx, outcome: 'dead' | 'abandoned'): void {
  const lostGold = Math.round(c.s.bag.gold * DESCENT.DEATH_LOSS_SHARE)
  const items = shuffle(c.rng, c.s.bag.items)
  const cut = Math.floor(items.length / 2) + (items.length % 2 === 1 && chance(c.rng, 0.5) ? 1 : 0)
  c.s.loss = { gold: lostGold, items: items.slice(0, cut) }
  c.s.bag = { gold: c.s.bag.gold - lostGold, items: items.slice(cut) }
  c.effects.push({
    type: 'claim', gold: c.s.bag.gold, entries: [...c.s.bag.items],
    reason: outcome === 'dead' ? 'death' : 'abandon',
  })
  endRun(c, outcome)
}

function die(c: Ctx): void {
  loseHalf(c, 'dead')
}

// --- Combat ------------------------------------------------------------------------

function combatRound(c: Ctx, action: 'strike' | 'brace' | 'potion'): void {
  const e = c.s.combat
  if (!e) throw new DescentError('BAD_STATE', 'No combat')
  if (action === 'potion') expect(c.s.potions > 0 && c.s.hp < c.s.maxHp, 'You cannot drink right now.')
  e.round++
  const pa = pick(c.rng, ZONES)
  const pg = pick(c.rng, ZONES)
  const ea = pick(c.rng, ZONES)
  const eg = pick(c.rng, ZONES)
  const r: RoundResult = {
    action, pa, pg, ea, eg, pHit: false, eBlock: false, dodged: false, crit: false, dealt: 0, healed: 0,
    eHit: false, pBlock: false, taken: 0, crushing: e.windup, mended: 0,
  }
  const lines: Line[] = []

  if (action === 'strike') {
    if (pa === eg) {
      r.eBlock = true
      lines.push({ text: `Your ${pa} strike — blocked.`, tone: 'info' })
      c.fx.push({ target: 'enemy', kind: 'info', text: 'Blocked' })
    } else if (e.traits.includes('dodge') && chance(c.rng, e.kind === 'boss' ? 0.2 : 0.16)) {
      r.dodged = true
      lines.push({ text: 'It slips aside.', tone: 'info' })
      c.fx.push({ target: 'enemy', kind: 'info', text: 'Dodged' })
    } else {
      const crit = chance(c.rng, 0.12 + (has(c.s, 'eagleeye') ? 0.1 : 0))
      let dmg = rnd(c.rng, 100, 140) * c.s.dmgMult * ZONE_MULT[pa]
        * (crit ? 1.6 + (has(c.s, 'razorfang') ? 0.4 : 0) : 1)
        * (e.traits.includes('armor') ? 0.82 : 1)
      dmg = Math.round(dmg)
      e.hp = Math.max(0, e.hp - dmg)
      r.pHit = true
      r.crit = crit
      r.dealt = dmg
      lines.push({ text: `${crit ? 'CRITICAL! ' : ''}You hit the ${pa} for ${dmg}.`, tone: 'good' })
      c.fx.push({ target: 'enemy', kind: crit ? 'crit' : 'dmg', value: dmg })
      if (has(c.s, 'bloodstone')) r.healed += c.heal(dmg * 0.1)
    }
  } else if (action === 'brace') {
    lines.push({ text: 'You raise your guard and brace.', tone: 'info' })
  } else {
    c.s.potions--
    r.healed += c.heal(potionHeal(c.s))
    lines.push({ text: 'You gulp a potion.', tone: 'good' })
  }

  if (e.hp <= 0) {
    e.lastRound = r
    e.verdict = lines
    winFight(c)
    return
  }

  // Its move
  const mult = (e.windup ? 2 : 1) * (e.enraged ? 1.4 : 1) * (c.s.curse > 0 ? 1.2 : 1)
  if (ea === pg) {
    r.pBlock = true
    lines.push({ text: `Its ${ea} attack meets your guard.`, tone: 'info' })
    c.fx.push({ target: 'hero', kind: 'info', text: 'Blocked' })
  } else {
    const dmg = e.dmg * (0.85 + c.rng() * 0.3) * ZONE_MULT[ea] * mult * (action === 'brace' ? DESCENT.BRACE_DAMAGE_TAKEN : 1)
    const taken = c.hurt(dmg)
    r.eHit = true
    r.taken = taken
    lines.push({ text: `${e.windup ? 'CRUSHING BLOW! ' : ''}It hits your ${ea} for ${taken}.`, tone: 'bad' })
  }
  e.windup = false
  if (e.traits.includes('heavy') && e.round % 3 === 2) {
    e.windup = true
    lines.push({ text: 'It winds up a crushing blow. Brace!', tone: 'bad' })
  }
  if (e.traits.includes('regen') && e.round % 3 === 0 && e.hp > 0) {
    const g = Math.round(e.maxHp * 0.08)
    const before = e.hp
    e.hp = Math.min(e.maxHp, e.hp + g)
    r.mended = e.hp - before
    c.fx.push({ target: 'enemy', kind: 'heal', value: r.mended })
    lines.push({ text: `It mends itself (+${r.mended}).`, tone: 'info' })
  }
  if (e.traits.includes('enrage') && !e.enraged && e.hp < e.maxHp * 0.35) {
    e.enraged = true
    lines.push({ text: 'It flies into a frenzy!', tone: 'bad' })
  }
  e.lastRound = r
  e.verdict = lines
  if (c.s.hp <= 0) die(c)
}

function winFight(c: Ctx): void {
  const e = c.s.combat
  if (!e) throw new DescentError('BAD_STATE', 'No combat')
  const D = DEPTHS[c.s.depth]
  c.s.stats.kills++
  if (c.s.curse > 0) c.s.curse--
  c.fx.push({ target: 'enemy', kind: 'slain' })
  if (has(c.s, 'siphon')) c.heal(c.s.maxHp * 0.12)
  const isMimic = e.key === 'mimic'
  const mult = e.kind === 'boss' ? 3.2 : isMimic ? 2.6 : e.kind === 'elite' ? 1.8 : 1
  const gold = c.goldN(D.gold * mult * (0.9 + c.rng() * 0.2))
  const xp = c.xpN(D.xp * mult)
  const loot: LootEntry[] = [{ kind: 'gold', n: gold }, { kind: 'xp', n: xp }]
  c.s.xp += xp
  c.effects.push({ type: 'xp', amount: xp })
  c.effects.push({ type: 'kill', kind: e.kind, mob: e.key })
  if (isMimic) loot.push(rollPendingItem('mimic'), { kind: 'potion', n: 1 })
  else if (e.kind === 'elite' && chance(c.rng, 0.6)) loot.push(rollPendingItem('elite'))
  else if (e.kind === 'combat' && chance(c.rng, 0.15)) loot.push(rollPendingItem('combat'))
  if (e.kind !== 'boss' && chance(c.rng, 0.18)) loot.push({ kind: 'torch', n: 1 })
  c.fx.push({ target: 'scene', kind: 'coins', value: e.kind === 'boss' ? 34 : 16 })

  if (e.kind === 'boss') {
    loot.push(rollPendingItem('boss'))
    const choices = shuffle(c.rng, RELIC_KEYS.filter((k) => !has(c.s, k))).slice(0, 3)
    c.s.room = { t: 'relic', loot, choices, text: `${e.name} falls, and the gate behind it groans open.` }
    c.s.combat = null
    c.s.screen = 'relic'
    return
  }
  const bg = e.bg
  c.s.room = {
    t: 'spoils', bg, loot,
    text: pick(c.rng, ['It drops, and does not get up.', 'Silence again. You catch your breath.', 'You wipe your blade and check its pockets.']),
  }
  c.s.combat = null
  c.s.screen = 'spoils'
}

// --- Events ------------------------------------------------------------------------

interface EventChoiceDef {
  label: string
  /** iOS asset name for the choice icon (rush2-*). */
  icon: string | null
  hint: (s: DescentState, room: EventRoom) => string
  req?: (s: DescentState, room: EventRoom) => string | null
  run: (c: Ctx, room: EventRoom) => EventOutcome
}
interface EventOutcome {
  text?: string
  loot?: LootEntry[]
  fight?: FightSpec
  stay?: boolean
  relicGot?: RelicKey | null
}
export type EventRoom = Extract<Room, { t: 'event' }>

interface EventDef {
  text: string
  choices: EventChoiceDef[]
}

const ICON = {
  potion: 'rush2-icon-potion',
  gold: 'rush2-icon-goldpouch',
  torch: 'rush2-icon-torch',
  relic: 'rush2-relic-bloodstone',
  strength: 'rush2-relic-shadowblade',
  combat: 'rush2-node-combat',
  elite: 'rush2-node-elite',
}

const fixed = (t: string) => () => t

function runeHint(s: DescentState, r: EventRoom, i: number): string {
  if (!r.studied) return 'Trust your luck.'
  return i === r.trap ? '{-This one is the trap.-}' : '{+No trap here.+}'
}
function runeResult(c: Ctx, r: EventRoom, i: number): EventOutcome {
  const d = c.s.depth
  if (i === r.trap) {
    c.hurt(c.s.maxHp * 0.2)
    return { text: 'The rune flares red. Fire licks out of the door.' }
  }
  if (i === r.vault) {
    const k = c.addRelic()
    return {
      text: 'The door grinds open onto a tiny vault.',
      loot: [{ kind: 'gold', n: c.goldN(120 + 40 * d) }, ...(k ? [] : [{ kind: 'potion' as const, n: 1 }])],
      relicGot: k,
    }
  }
  return { text: 'The rune hums and the door opens a crack. A pouch is wedged in the gap.', loot: [{ kind: 'gold', n: c.goldN(90 + 30 * d) }] }
}

export const EVENTS: Record<EventId | 'mimic', EventDef> = {
  explorer: {
    text: 'A wounded explorer is slumped against the wall, clutching a torn map. "Water... or a potion. Please."',
    choices: [
      {
        label: 'Give him a potion', icon: ICON.potion, hint: fixed('{-−1 potion.-} He might repay you.'),
        req: (s) => (s.potions ? null : 'You have no potions.'),
        run: (c) => {
          c.s.potions--
          const g = c.goldN(110 + 40 * c.s.depth)
          for (const n of c.s.map.rows.flat()) n.dark = false
          return {
            text: 'He drinks, breathes, and presses his map into your hands. "Every tunnel on this level is marked. Go." **All dark passages on this depth are revealed.**',
            loot: [{ kind: 'gold', n: g }],
          }
        },
      },
      {
        label: 'Take his pack', icon: ICON.gold, hint: fixed('{+Gold+}, but he curses you as you go.'),
        run: (c) => {
          c.s.curse = 2
          return {
            text: 'You take the pack. His curse follows you down the tunnel: **your next two fights hit you 20% harder.**',
            loot: [{ kind: 'gold', n: c.goldN(220 + 60 * c.s.depth) }],
          }
        },
      },
      { label: 'Walk away', icon: null, hint: fixed('Not your problem.'), run: () => ({ text: 'His breathing fades behind you.' }) },
    ],
  },
  altar: {
    text: 'A stone altar, stained dark. A voice in your head: "Blood for power. A fair trade."',
    choices: [
      {
        label: 'Offer your blood', icon: ICON.relic, hint: fixed('{-−20% HP-} for a random relic.'),
        req: (s) => (s.hp > s.maxHp * 0.22 ? null : 'Too weak to bleed.'),
        run: (c) => {
          c.hurt(c.s.maxHp * 0.2)
          const k = c.addRelic()
          return {
            text: k ? `The altar drinks. Something cold settles around your neck: **${RELICS[k].name}**.` : 'The altar drinks, but has nothing left to give.',
            loot: [],
          }
        },
      },
      {
        label: 'Smash the altar', icon: ICON.gold, hint: fixed('Maybe gold inside. Maybe not.'),
        run: (c) => {
          if (chance(c.rng, 0.55)) return { text: 'The stone cracks. Old offerings spill out.', loot: [{ kind: 'gold', n: c.goldN(150 + 50 * c.s.depth) }] }
          c.hurt(c.s.maxHp * 0.14)
          return { text: 'Dark fire bursts from the cracks and burns your hands.' }
        },
      },
      { label: 'Leave it', icon: null, hint: fixed('Some deals are bad deals.'), run: () => ({ text: 'The voice laughs as you go.' }) },
    ],
  },
  fountain: {
    text: 'A lion-headed fountain pours clear, glowing water into a cracked basin.',
    choices: [
      {
        label: 'Drink deeply', icon: ICON.potion, hint: fixed('{++30% HP+} now.'),
        run: (c) => { c.heal(c.s.maxHp * 0.3); return { text: 'Cold and sweet. Your wounds close.' } },
      },
      {
        label: 'Fill a flask', icon: ICON.potion, hint: fixed('{++1 potion+} for later.'),
        req: (s) => (s.potions < DESCENT.MAX_POTIONS ? null : 'Your belt is full.'),
        run: () => ({ text: 'You cork the flask. It glows faintly at your hip.', loot: [{ kind: 'potion', n: 1 }] }),
      },
    ],
  },
  bridge: {
    text: 'A rope bridge sways over a chasm. A satchel hangs from a broken plank halfway across.',
    choices: [
      {
        label: 'Run for it', icon: ICON.gold, hint: fixed('Grab the satchel. The planks are rotten.'),
        run: (c) => {
          if (chance(c.rng, 0.65)) {
            return { text: 'You snatch the satchel and make it across, laughing.', loot: [{ kind: 'gold', n: c.goldN(140 + 50 * c.s.depth) }, { kind: 'torch', n: 1 }] }
          }
          c.hurt(c.s.maxHp * 0.22)
          return { text: 'A plank snaps. You catch the rope, but the rocks catch you first.' }
        },
      },
      {
        label: 'Light the way', icon: ICON.torch, hint: fixed('{-−1 torch.-} Slow and safe.'),
        req: (s) => (s.torches ? null : 'You have no torches.'),
        run: (c) => {
          c.s.torches--
          return { text: 'By torchlight you pick the solid planks and reach the satchel.', loot: [{ kind: 'gold', n: c.goldN(90 + 30 * c.s.depth) }] }
        },
      },
      { label: 'Go around', icon: null, hint: fixed('A long way, but on solid stone.'), run: () => ({ text: 'You find another way across. The satchel stays where it is.' }) },
    ],
  },
  troll: {
    text: 'A cave troll snores on a heap of stolen loot. One eye twitches.',
    choices: [
      {
        label: 'Sneak to the hoard', icon: ICON.gold, hint: fixed('Steal while he sleeps. Quietly.'),
        run: (c) => {
          if (chance(c.rng, 0.55)) {
            return { text: 'You fill your bag and tiptoe out. He never stirs.', loot: [{ kind: 'gold', n: c.goldN(240 + 80 * c.s.depth) }, rollPendingItem('troll')] }
          }
          return { text: 'A coin slips. Clink. The troll opens both eyes.', fight: { key: 'troll', kind: 'elite' } }
        },
      },
      {
        label: 'Strike while he sleeps', icon: ICON.combat, hint: fixed('A fight, but you land the first blow.'),
        run: () => ({ text: 'You bring your blade down on the sleeping troll.', fight: { key: 'troll', kind: 'elite', firstStrike: true } }),
      },
      { label: 'Back away', icon: null, hint: fixed('Let sleeping trolls lie.'), run: () => ({ text: 'You leave him to his dreams.' }) },
    ],
  },
  angel: {
    text: 'A weeping stone angel, untouched by the rot around it. Its palms are open, waiting.',
    choices: [
      {
        label: 'Pray for strength', icon: ICON.strength, hint: fixed('{++15% damage+} for the rest of the run.'),
        run: (c) => { c.s.dmgMult += 0.15; return { text: 'Warmth runs down your sword arm.' } },
      },
      {
        label: 'Pray for vigor', icon: ICON.potion, hint: fixed('{++150 max HP+} and heal 150.'),
        run: (c) => { c.s.maxHp += 150; c.heal(150); return { text: 'Your heart beats slow and strong.' } },
      },
    ],
  },
  cache: {
    text: 'One stone in the wall is loose. Behind it, something glints.',
    choices: [
      {
        label: 'Reach in', icon: ICON.gold, hint: fixed('Probably gold. Probably.'),
        run: (c) => {
          if (chance(c.rng, 0.7)) return { text: 'A forgotten stash. Someone hid this a long time ago.', loot: [{ kind: 'gold', n: c.goldN(170 + 60 * c.s.depth) }] }
          c.hurt(c.s.maxHp * 0.1)
          return { text: 'Something with too many legs bites your hand. You pull back empty.' }
        },
      },
      {
        label: 'Light it first', icon: ICON.torch, hint: fixed('{-−1 torch.-} See what is inside.'),
        req: (s) => (s.torches ? null : 'You have no torches.'),
        run: (c) => {
          c.s.torches--
          return {
            text: 'You burn out a nest of spiders and take the stash at leisure.',
            loot: [{ kind: 'gold', n: c.goldN(170 + 60 * c.s.depth) }, { kind: 'potion', n: 1 }],
          }
        },
      },
    ],
  },
  runes: {
    text: 'A sealed door with three glowing runes. One opens the vault. One is a trap. The third... who knows.',
    choices: [
      { label: 'Touch the first rune', icon: null, hint: (s, r) => runeHint(s, r, 0), run: (c, r) => runeResult(c, r, 0) },
      { label: 'Touch the second rune', icon: null, hint: (s, r) => runeHint(s, r, 1), run: (c, r) => runeResult(c, r, 1) },
      { label: 'Touch the third rune', icon: null, hint: (s, r) => runeHint(s, r, 2), run: (c, r) => runeResult(c, r, 2) },
      {
        label: 'Study them by torchlight', icon: ICON.torch, hint: fixed('{-−1 torch.-} Find the trap.'),
        req: (s, r) => (r.studied ? 'Already studied.' : s.torches ? null : 'You have no torches.'),
        run: (c, r) => { c.s.torches--; r.studied = true; return { stay: true } },
      },
    ],
  },
  mimic: {
    text: 'The light catches a row of teeth under the lid. The chest is breathing.',
    choices: [
      {
        label: 'Fight it', icon: ICON.elite, hint: fixed('Mimics swallow treasure. It is all still inside.'),
        run: () => ({ text: 'You kick the lid before it can open. It howls.', fight: { key: 'mimic', kind: 'elite', firstStrike: true, bg: 'rush2-bg-treasure' } }),
      },
      { label: 'Back away slowly', icon: null, hint: fixed('Keep all your fingers.'), run: () => ({ text: 'You back out of the room. The chest snaps at the air.' }) },
    ],
  },
}

export function eventScene(id: EventId | 'mimic'): string {
  return EVENT_SCENE[id]
}

// --- Action dispatcher -------------------------------------------------------------

function room<T extends Room['t']>(c: Ctx, t: T): Extract<Room, { t: T }> {
  const r = c.s.room
  expect(r && r.t === t, `No ${t} here.`)
  return r as Extract<Room, { t: T }>
}

export function applyAction(input: DescentState, action: Action, rng: Rng): ApplyResult {
  const s: DescentState = JSON.parse(JSON.stringify(input))
  const c = new Ctx(s, rng)
  expect(s.screen !== 'result', 'The descent is over.')

  switch (action.type) {
    case 'begin_depth': {
      expect(s.screen === 'depthCard', 'Not at the stairs.')
      if (s.depth > 0 && has(s, 'lantern')) s.torches = Math.min(DESCENT.MAX_TORCHES, s.torches + 1)
      s.screen = 'fork'
      s.at = 'S'
      s.prev = null
      break
    }
    case 'torch': {
      expect(s.screen === 'fork', 'No passage to light.')
      expect(s.torches > 0, 'You have no torches.')
      expect(nextIds(s).includes(action.nodeId), 'That passage is not here.')
      const n = findNode(s, action.nodeId)
      expect(n && n.dark, 'That passage is already lit.')
      s.torches--
      n.dark = false
      s.revealed = n.id
      c.fx.push({ target: 'scene', kind: 'reveal', text: TYPE_NAME[n.type] })
      break
    }
    case 'move': {
      expect(s.screen === 'fork', 'You cannot leave now.')
      expect(nextIds(s).includes(action.nodeId), 'That passage is not here.')
      const n = findNode(s, action.nodeId)
      expect(n, 'That passage is not here.')
      s.prev = s.at
      s.at = n.id
      n.visited = true
      n.dark = false
      s.revealed = null
      s.stats.rooms++
      enterNode(c, n)
      break
    }
    case 'strike':
    case 'brace':
    case 'potion': {
      expect(s.screen === 'combat' && s.combat, 'There is nothing to fight.')
      combatRound(c, action.type)
      break
    }
    case 'flee': {
      expect(s.screen === 'combat' && s.combat, 'There is nothing to flee from.')
      expect(s.combat.kind !== 'boss', 'There is no escape from a guardian.')
      const n = findNode(s, s.at)
      if (n) {
        n.fled = true
        n.visited = false
      }
      s.combat = null
      c.hurt(s.maxHp * DESCENT.FLEE_HP_COST)
      if (s.hp <= 0) {
        die(c)
        break
      }
      s.at = s.prev ?? 'S'
      s.screen = 'fork'
      break
    }
    case 'drink': {
      expect(s.screen !== 'combat', 'Use the potion button in a fight.')
      expect(s.potions > 0 && s.hp < s.maxHp, 'You cannot drink right now.')
      s.potions--
      c.heal(potionHeal(s))
      break
    }
    case 'take_loot': {
      if (s.screen === 'spoils') {
        const r = room(c, 'spoils')
        c.grantLoot(r.loot)
        finishNode(c)
      } else if (s.screen === 'chest') {
        const r = room(c, 'chest')
        expect(r.opened, 'The chest is still closed.')
        c.grantLoot(r.loot)
        s.stats.chests++
        finishNode(c)
      } else if (s.screen === 'event') {
        const r = room(c, 'event')
        expect(r.done && r.then === 'take_loot', 'Nothing to take.')
        c.grantLoot(r.loot)
        finishNode(c)
      } else {
        expect(false, 'Nothing to take.')
      }
      break
    }
    case 'inspect': {
      expect(s.screen === 'chest', 'No chest here.')
      const r = room(c, 'chest')
      expect(!r.opened && !r.inspected, 'You already looked.')
      expect(s.torches > 0, 'You have no torches.')
      s.torches--
      r.inspected = true
      if (r.mimic) {
        s.room = { t: 'event', id: 'mimic', done: false, text: null, loot: [], then: null, fight: null, studied: false, trap: -1, vault: -1 }
        s.screen = 'event'
        c.fx.push({ target: 'scene', kind: 'mimic' })
      }
      break
    }
    case 'open_chest': {
      expect(s.screen === 'chest', 'No chest here.')
      const r = room(c, 'chest')
      expect(!r.opened, 'It is already open.')
      if (r.mimic && !r.inspected) {
        c.fx.push({ target: 'scene', kind: 'mimic' })
        c.hurt(s.maxHp * DESCENT.MIMIC_BITE)
        if (s.hp <= 0) {
          die(c)
          break
        }
        startFight(c, { key: 'mimic', kind: 'elite', ambush: true, bg: 'rush2-bg-treasure' })
        break
      }
      r.opened = true
      c.fx.push({ target: 'scene', kind: 'chest_open', text: r.tier })
      break
    }
    case 'leave': {
      expect(s.screen === 'chest', 'Nothing to leave.')
      const r = room(c, 'chest')
      expect(!r.opened, 'Take your loot first.')
      finishNode(c)
      break
    }
    case 'choose': {
      expect(s.screen === 'event', 'Nothing to choose.')
      const r = room(c, 'event')
      expect(!r.done, 'You already chose.')
      const def = EVENTS[r.id]
      const ch = def.choices[action.i]
      expect(ch, 'No such choice.')
      const why = ch.req ? ch.req(s, r) : null
      expect(!why, why ?? 'Not possible.')
      const res = ch.run(c, r)
      if (res.stay) break
      r.done = true
      r.text = res.text ?? null
      r.loot = res.loot ?? []
      if (res.fight) {
        r.fight = res.fight
        r.then = 'fight_now'
        break
      }
      if (res.relicGot) r.text = `${r.text ?? ''} You find **${RELICS[res.relicGot].name}**.`.trim()
      r.then = r.loot.length ? 'take_loot' : 'continue'
      if (r.loot.length) c.fx.push({ target: 'scene', kind: 'coins', value: 14 })
      if (s.hp <= 0) die(c)
      break
    }
    case 'continue': {
      if (s.screen === 'event') {
        const r = room(c, 'event')
        expect(r.done && r.then === 'continue', 'Choose first.')
        finishNode(c)
      } else if (s.screen === 'camp') {
        const r = room(c, 'camp')
        expect(r.done, 'Choose first.')
        finishNode(c)
      } else if (s.screen === 'merchant') {
        finishNode(c)
      } else {
        expect(false, 'Nothing to continue.')
      }
      break
    }
    case 'fight_now': {
      expect(s.screen === 'event', 'Nothing to fight.')
      const r = room(c, 'event')
      expect(r.done && r.then === 'fight_now' && r.fight, 'Nothing to fight.')
      startFight(c, r.fight)
      break
    }
    case 'camp': {
      expect(s.screen === 'camp', 'No campfire here.')
      const r = room(c, 'camp')
      expect(!r.done, 'The fire is already dying.')
      if (action.k === 'rest') {
        c.heal(s.maxHp * DESCENT.CAMP_REST_HEAL)
        r.text = 'You sleep by the fire. When you wake, the ache is gone.'
      } else if (action.k === 'sharpen') {
        s.dmgMult += DESCENT.CAMP_SHARPEN
        r.text = 'Stone on steel until the edge sings. **+12% damage.**'
      } else {
        expect(s.bag.gold > 0 || s.bag.items.length > 0, 'Your bag is empty.')
        const gold = s.bag.gold
        const items = [...s.bag.items]
        c.effects.push({ type: 'claim', gold, entries: items, reason: 'stash' })
        s.safe.gold += gold
        s.safe.items.push(...items)
        r.text = `You lock **${gold}** gold${items.length ? ' and your finds' : ''} in the camp chest. Whatever happens below, that is yours.`
        s.bag = { gold: 0, items: [] }
      }
      r.k = action.k
      r.done = true
      break
    }
    case 'buy': {
      expect(s.screen === 'merchant', 'No merchant here.')
      const r = room(c, 'merchant')
      const w = r.wares[action.i]
      expect(w, 'No such ware.')
      expect(!w.sold, 'Sold out.')
      expect(s.bag.gold >= w.price, 'Not enough gold in your bag.')
      if (w.t === 'potion') expect(s.potions < DESCENT.MAX_POTIONS, 'Your belt is full.')
      if (w.t === 'torch') expect(s.torches < DESCENT.MAX_TORCHES, 'You cannot carry more torches.')
      if (w.t === 'relic') expect(w.k && !has(s, w.k), 'You already have it.')
      s.bag.gold -= w.price
      if (w.t === 'potion') s.potions++
      else if (w.t === 'torch') s.torches++
      else if (w.k) {
        c.addRelic(w.k)
        w.sold = true
      }
      break
    }
    case 'take_relic': {
      expect(s.screen === 'relic', 'No relics here.')
      const r = room(c, 'relic')
      if (r.choices.length) expect(action.k && r.choices.includes(action.k), 'Pick one of the relics.')
      if (action.k && r.choices.includes(action.k)) c.addRelic(action.k)
      c.grantLoot(r.loot)
      s.dmgMult += DESCENT.GUARDIAN_DMG_BONUS
      c.heal(s.maxHp * DESCENT.GUARDIAN_HEAL)
      const bossNode = findNode(s, s.at)
      if (bossNode) bossNode.cleared = true
      s.room = null
      if (s.depth >= DEPTHS.length - 1) {
        claimBag(c, 'victory')
        endRun(c, 'victory')
      } else {
        s.screen = 'depthClear'
      }
      break
    }
    case 'descend': {
      expect(s.screen === 'depthClear', 'The way down is not open.')
      s.depth++
      s.map = genDepth(s.depth, rng)
      s.at = 'S'
      s.prev = null
      s.revealed = null
      s.screen = 'depthCard'
      break
    }
    case 'escape': {
      const fromCamp = s.screen === 'camp' && s.room?.t === 'camp' && s.room.done
      expect(fromCamp || s.screen === 'depthClear', 'You can only climb out at a campfire or after a guardian.')
      claimBag(c, 'escape')
      endRun(c, 'escaped')
      break
    }
    case 'abandon': {
      loseHalf(c, 'abandoned')
      break
    }
  }

  s.seq += 1
  return { state: s, fx: c.fx, effects: c.effects }
}

/** Replace pending_item loot entries using the resolver (real catalog items). */
export async function resolvePendingLoot(
  state: DescentState,
  resolve: (source: LootSource) => Promise<BagEntry | null>,
): Promise<number> {
  const lists: LootEntry[][] = []
  const r = state.room
  if (r && (r.t === 'spoils' || r.t === 'chest' || r.t === 'event' || r.t === 'relic')) lists.push(r.loot)
  let resolved = 0
  for (const list of lists) {
    for (let i = 0; i < list.length; i++) {
      const l = list[i]
      if (l.kind !== 'pending_item') continue
      const entry = await resolve(l.source)
      if (entry) {
        list[i] = { kind: 'bag', entry }
        resolved++
      } else {
        list.splice(i, 1)
        i--
      }
    }
  }
  return resolved
}

