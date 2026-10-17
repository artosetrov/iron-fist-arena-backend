// =============================================================================
// descent/view.ts — the client-facing snapshot of a Descent run
//
// The full DescentState holds information the player must not see yet (the
// type behind a dark passage, a mimic, where the rune trap is, what a closed
// chest holds, nodes further than one row ahead). buildDescentView() is the
// only thing that leaves the server, and it strips all of that.
// =============================================================================

import {
  CHESTS, CUE_DARK, CUE_FLED, DEPTHS, DEPTH_OPENINGS, DESCENT, FORK_LINES, MOBS, RELICS, TRAITS, TYPE_NAME,
  type NodeType, type RelicKey, type TraitKey,
} from './content'
import {
  EVENTS, currentRow, eventScene, findNode, has, nextIds, potionHeal,
  type BagEntry, type DescentState, type EventRoom, type Fx, type Line, type LootEntry, type MapNode, type RoundResult,
} from './engine'

export interface BagItemView {
  kind: 'item' | 'shard'
  name: string
  rarity: string
  itemType: string | null
  itemLevel: number | null
  imageKey: string | null
  imageUrl: string | null
  shardTier: string | null
  amount: number
}

export interface RelicView { key: RelicKey; name: string; desc: string; icon: string }

export interface LootView {
  kind: 'gold' | 'xp' | 'potion' | 'torch' | 'relic' | 'item'
  amount: number
  relic: RelicView | null
  item: BagItemView | null
}

export interface ForkOptionView {
  id: string
  lane: number
  side: 'Ahead' | 'Left' | 'Middle' | 'Right'
  known: boolean
  type: NodeType | null
  typeName: string | null
  cue: string
  fled: boolean
  revealed: boolean
}

export interface MapNodeView {
  id: string
  r: number
  lane: number
  next: string[]
  /** Null while the room is unknown (dark, or more than one row ahead). */
  type: NodeType | null
  visited: boolean
  cleared: boolean
  reachable: boolean
  current: boolean
}

export interface CombatView {
  key: string
  name: string
  art: string
  size: 'small' | 'big' | null
  kind: 'combat' | 'elite' | 'boss'
  level: number
  hp: number
  maxHp: number
  traits: Array<{ key: string; label: string }>
  windup: boolean
  enraged: boolean
  bg: string
  verdict: Line[]
  lastRound: RoundResult | null
  canFlee: boolean
}

export interface EventChoiceView {
  i: number
  label: string
  hint: string
  icon: string | null
  disabledReason: string | null
}

export interface DescentView {
  runId: string
  seq: number
  screen: DescentState['screen']
  depth: number
  depthKey: string
  depthName: string
  depthBlurb: string
  guardianName: string
  hero: {
    hp: number
    maxHp: number
    potions: number
    maxPotions: number
    torches: number
    maxTorches: number
    potionHeal: number
    dmgBonusPct: number
    cursedFights: number
  }
  relics: RelicView[]
  bag: { gold: number; items: BagItemView[] }
  safe: { gold: number; items: BagItemView[] }
  xpEarned: number
  stats: { kills: number; rooms: number; chests: number }
  progress: { total: number; current: number; currentCleared: boolean }
  tale: string | null
  fork: { lead: string; isBossGate: boolean; options: ForkOptionView[] } | null
  combat: CombatView | null
  spoils: { bg: string; loot: LootView[] } | null
  chest: { tier: string; name: string; inspected: boolean; opened: boolean; loot: LootView[] } | null
  event: {
    id: string
    scene: string
    text: string
    done: boolean
    resultText: string | null
    loot: LootView[]
    then: 'take_loot' | 'fight_now' | 'continue' | null
    choices: EventChoiceView[]
    runes: Array<{ i: number; state: 'unknown' | 'safe' | 'trap' }> | null
  } | null
  camp: { done: boolean; choice: string | null; canStash: boolean; stashGold: number; stashItems: number } | null
  merchant: {
    wares: Array<{ i: number; kind: 'potion' | 'torch' | 'relic'; name: string; desc: string; icon: string; price: number; sold: boolean; available: boolean }>
  } | null
  relicChoice: { loot: LootView[]; choices: RelicView[] } | null
  depthClear: { nextDepthName: string; bonusText: string } | null
  result: {
    outcome: NonNullable<DescentState['outcome']>
    keptGold: number
    keptItems: BagItemView[]
    lostGold: number
    lostItems: BagItemView[]
    xp: number
    depthReached: number
    rooms: number
    kills: number
  } | null
  map: { rows: MapNodeView[][]; startNext: string[] }
  fx: Fx[]
}

export function relicView(k: RelicKey): RelicView {
  return { key: k, name: RELICS[k].name, desc: RELICS[k].desc, icon: `rush2-relic-${k}` }
}

export function bagItemView(e: BagEntry): BagItemView {
  if (e.kind === 'shard') {
    const name = `${e.tier.charAt(0).toUpperCase()}${e.tier.slice(1)} Shard`
    return { kind: 'shard', name, rarity: e.tier, itemType: null, itemLevel: null, imageKey: null, imageUrl: null, shardTier: e.tier, amount: e.amount }
  }
  return {
    kind: 'item', name: e.name, rarity: e.rarity, itemType: e.itemType, itemLevel: e.itemLevel,
    imageKey: e.imageKey, imageUrl: e.imageUrl, shardTier: null, amount: 1,
  }
}

function lootView(list: LootEntry[]): LootView[] {
  const out: LootView[] = []
  for (const l of list) {
    switch (l.kind) {
      case 'gold': out.push({ kind: 'gold', amount: l.n, relic: null, item: null }); break
      case 'xp': out.push({ kind: 'xp', amount: l.n, relic: null, item: null }); break
      case 'potion': out.push({ kind: 'potion', amount: l.n, relic: null, item: null }); break
      case 'torch': out.push({ kind: 'torch', amount: l.n, relic: null, item: null }); break
      case 'relic': out.push({ kind: 'relic', amount: 1, relic: relicView(l.k), item: null }); break
      case 'bag': out.push({ kind: 'item', amount: 1, relic: null, item: bagItemView(l.entry) }); break
      case 'pending_item': break
    }
  }
  return out
}

function sideName(i: number, n: number): ForkOptionView['side'] {
  if (n === 1) return 'Ahead'
  if (n === 2) return i === 0 ? 'Left' : 'Right'
  return (['Left', 'Middle', 'Right'] as const)[i] ?? 'Ahead'
}

function nodeKnownOnMap(s: DescentState, n: MapNode, reachable: Set<string>, curR: number): boolean {
  if (n.type === 'boss' || n.visited) return true
  if (n.dark) return false
  if (reachable.has(n.id)) return true
  if (n.type === 'camp' || n.type === 'merchant') return true
  return n.r <= curR + 1
}

function forkView(s: DescentState): DescentView['fork'] {
  const opts = nextIds(s)
    .map((id) => findNode(s, id))
    .filter((n): n is MapNode => !!n)
    .sort((a, b) => a.lane - b.lane)
  const isBossGate = opts.length === 1 && opts[0].type === 'boss'
  const lead = s.at === 'S'
    ? `${DEPTH_OPENINGS[s.depth] ?? ''} ${FORK_LINES[opts.length] ?? ''}`.trim()
    : isBossGate ? 'The tunnels join at a great sealed gate.' : FORK_LINES[opts.length] ?? ''
  return {
    lead,
    isBossGate,
    options: opts.map((n, i) => {
      const known = !n.dark
      return {
        id: n.id,
        lane: n.lane,
        side: sideName(i, opts.length),
        known,
        type: known ? n.type : null,
        typeName: known ? TYPE_NAME[n.type] : null,
        cue: n.fled ? CUE_FLED : known ? n.cue : CUE_DARK,
        fled: n.fled,
        revealed: s.revealed === n.id,
      }
    }),
  }
}

function eventView(s: DescentState, r: EventRoom): NonNullable<DescentView['event']> {
  const def = EVENTS[r.id]
  return {
    id: r.id,
    scene: eventScene(r.id),
    text: def.text,
    done: r.done,
    resultText: r.text,
    loot: lootView(r.loot),
    then: r.then,
    choices: r.done ? [] : def.choices.map((ch, i) => ({
      i,
      label: ch.label,
      hint: ch.hint(s, r),
      icon: ch.icon,
      disabledReason: ch.req ? ch.req(s, r) : null,
    })),
    runes: r.id === 'runes' && !r.done
      ? [0, 1, 2].map((i) => ({ i, state: !r.studied ? 'unknown' as const : i === r.trap ? 'trap' as const : 'safe' as const }))
      : null,
  }
}

function taleFor(s: DescentState, fork: DescentView['fork']): string | null {
  const D = DEPTHS[s.depth]
  switch (s.screen) {
    case 'depthCard': {
      const bonus = s.depth > 0 && has(s, 'lantern') ? ' Your lantern flares: **+1 torch**.' : ''
      const lead = s.depth === 0
        ? 'You step past the last lamp of the city. The stairs end in a crypt.'
        : 'The stair spirals down for a long time.'
      return `${lead} Guardian ahead: **${MOBS[D.boss].name}**.${bonus}`
    }
    case 'fork': return fork?.lead ?? null
    case 'spoils': return s.room?.t === 'spoils' ? s.room.text : null
    case 'chest': {
      if (s.room?.t !== 'chest') return null
      const r = s.room
      if (r.opened) {
        return r.tier === 'gold' ? 'The lid swings up and gold light floods the room.'
          : r.tier === 'iron' ? 'The lock gives with a clank. The box is full.'
            : 'The lid falls open. Gold spills over the edge.'
      }
      if (r.inspected) return 'The light shows plain wood and iron. No teeth. It is just a chest.'
      return r.tier === 'gold' ? 'A gilded coffer, far too fine for a place like this. Lions glare from the lock.'
        : r.tier === 'iron' ? 'An iron-bound strongbox, wrapped in chains. Someone wanted this kept shut.'
          : 'An old oak chest sits alone in the room, too clean for this place.'
    }
    case 'event': {
      if (s.room?.t !== 'event') return null
      return s.room.done ? s.room.text : EVENTS[s.room.id].text
    }
    case 'camp': {
      if (s.room?.t !== 'camp') return null
      return s.room.done ? s.room.text : 'A ring of stones, still warm. You can do one thing before the fire dies.'
    }
    case 'merchant':
      return `"Coin from your bag, friend. You won't need it if you're dead." You have **${s.bag.gold}** gold.`
    case 'relic': return s.room?.t === 'relic' ? s.room.text : null
    case 'depthClear':
      return 'The guardian\'s death warms your blood: **+12% damage** and you catch your breath. Go deeper for bigger treasure, or climb out now with everything you carry.'
    default: return null
  }
}

export function buildDescentView(runId: string, s: DescentState, fx: Fx[] = []): DescentView {
  const D = DEPTHS[s.depth]
  const curR = currentRow(s)
  const reachable = new Set(s.screen === 'result' ? [] : nextIds(s))
  const fork = s.screen === 'fork' ? forkView(s) : null
  const total = s.map.rows.length
  const cur = findNode(s, s.at)

  const combat: CombatView | null = s.combat ? {
    key: s.combat.key,
    name: s.combat.name,
    art: s.combat.art,
    size: MOBS[s.combat.key].size ?? null,
    kind: s.combat.kind,
    level: s.combat.level,
    hp: s.combat.hp,
    maxHp: s.combat.maxHp,
    traits: s.combat.traits.map((t) => ({ key: t, label: TRAITS[t as TraitKey] ?? t })),
    windup: s.combat.windup,
    enraged: s.combat.enraged,
    bg: s.combat.bg,
    verdict: s.combat.verdict,
    lastRound: s.combat.lastRound,
    canFlee: s.combat.kind !== 'boss',
  } : null

  const r = s.room
  return {
    runId,
    seq: s.seq,
    screen: s.screen,
    depth: s.depth,
    depthKey: D.key,
    depthName: D.name,
    depthBlurb: D.blurb,
    guardianName: MOBS[D.boss].name,
    hero: {
      hp: s.hp,
      maxHp: s.maxHp,
      potions: s.potions,
      maxPotions: DESCENT.MAX_POTIONS,
      torches: s.torches,
      maxTorches: DESCENT.MAX_TORCHES,
      potionHeal: potionHeal(s),
      dmgBonusPct: Math.round((s.dmgMult - 1) * 100),
      cursedFights: s.curse,
    },
    relics: s.relics.map(relicView),
    bag: { gold: s.bag.gold, items: s.bag.items.map(bagItemView) },
    safe: { gold: s.safe.gold, items: s.safe.items.map(bagItemView) },
    xpEarned: s.xp,
    stats: { ...s.stats },
    progress: { total, current: curR, currentCleared: !!cur?.cleared },
    tale: taleFor(s, fork),
    fork,
    combat,
    spoils: r?.t === 'spoils' ? { bg: r.bg, loot: lootView(r.loot) } : null,
    chest: r?.t === 'chest' ? {
      tier: r.tier, name: CHESTS[r.tier].name, inspected: r.inspected, opened: r.opened,
      loot: r.opened ? lootView(r.loot) : [],
    } : null,
    event: r?.t === 'event' ? eventView(s, r) : null,
    camp: r?.t === 'camp' ? {
      done: r.done, choice: r.k, canStash: s.bag.gold > 0 || s.bag.items.length > 0,
      stashGold: s.bag.gold, stashItems: s.bag.items.length,
    } : null,
    merchant: r?.t === 'merchant' ? {
      wares: r.wares.map((w, i) => {
        if (w.t === 'potion') {
          return {
            i, kind: 'potion' as const, name: 'Health potion',
            desc: `Heals ${has(s, 'alchemist') ? 50 : 35}% HP. Up to ${DESCENT.MAX_POTIONS} on your belt.`,
            icon: 'rush2-icon-potion', price: w.price, sold: w.sold,
            available: !w.sold && s.potions < DESCENT.MAX_POTIONS && s.bag.gold >= w.price,
          }
        }
        if (w.t === 'torch') {
          return {
            i, kind: 'torch' as const, name: 'Torch', desc: 'Light one dark passage or inspect a chest.',
            icon: 'rush2-icon-torch', price: w.price, sold: w.sold,
            available: !w.sold && s.torches < DESCENT.MAX_TORCHES && s.bag.gold >= w.price,
          }
        }
        const k = w.k as RelicKey
        return {
          i, kind: 'relic' as const, name: RELICS[k].name, desc: RELICS[k].desc,
          icon: `rush2-relic-${k}`, price: w.price, sold: w.sold,
          available: !w.sold && !has(s, k) && s.bag.gold >= w.price,
        }
      }),
    } : null,
    relicChoice: r?.t === 'relic' ? { loot: lootView(r.loot), choices: r.choices.map(relicView) } : null,
    depthClear: s.screen === 'depthClear' && DEPTHS[s.depth + 1] ? {
      nextDepthName: DEPTHS[s.depth + 1].name,
      bonusText: '+12% damage, 25% HP restored',
    } : null,
    result: s.screen === 'result' && s.outcome ? {
      outcome: s.outcome,
      keptGold: s.safe.gold + s.bag.gold,
      keptItems: [...s.safe.items, ...s.bag.items].map(bagItemView),
      lostGold: s.loss?.gold ?? 0,
      lostItems: (s.loss?.items ?? []).map(bagItemView),
      xp: s.xp,
      depthReached: s.depth + 1,
      rooms: s.stats.rooms,
      kills: s.stats.kills,
    } : null,
    map: {
      startNext: s.map.startNext,
      rows: s.map.rows.map((row) => row.map((n) => ({
        id: n.id,
        r: n.r,
        lane: n.lane,
        next: n.next,
        type: nodeKnownOnMap(s, n, reachable, curR) ? n.type : null,
        visited: n.visited,
        cleared: n.cleared,
        reachable: reachable.has(n.id),
        current: n.id === s.at,
      }))),
    },
    fx,
  }
}
