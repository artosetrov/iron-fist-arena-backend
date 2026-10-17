import { describe, expect, it } from 'vitest'
import { DEPTHS, DESCENT } from '../../src/lib/game/descent/content'
import {
  DescentError, applyAction, createRun, findNode, genDepth, nextIds, resolvePendingLoot,
  type Action, type BagEntry, type DescentState, type Effect, type Rng,
} from '../../src/lib/game/descent/engine'
import { buildDescentView } from '../../src/lib/game/descent/view'

function mulberry32(seed: number): Rng {
  let a = seed >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

const SCALE = { gold: 0.3, price: 0.3, xp: 0.75 }

const fakeItem = (n: number): BagEntry => ({
  kind: 'item', catalogItemId: `item-${n}`, name: `Item ${n}`, itemType: 'weapon', rarity: 'rare',
  itemLevel: 10, baseStats: { str: 5 }, rolledStats: {}, imageKey: null, imageUrl: null, sellPrice: 10,
})

/** A simple policy that always picks a legal action — used to fuzz whole runs. */
function botAction(s: DescentState, rng: Rng): Action {
  const r = s.room
  switch (s.screen) {
    case 'depthCard': return { type: 'begin_depth' }
    case 'fork': {
      const opts = nextIds(s).map((id) => findNode(s, id)!).filter(Boolean)
      const dark = opts.find((o) => o.dark)
      if (dark && s.torches > 0 && rng() < 0.5) return { type: 'torch', nodeId: dark.id }
      if (s.hp < s.maxHp * 0.5 && s.potions > 0) return { type: 'drink' }
      return { type: 'move', nodeId: opts[Math.floor(rng() * opts.length)].id }
    }
    case 'combat': {
      const c = s.combat!
      if (c.windup) return { type: 'brace' }
      if (s.hp < s.maxHp * 0.33 && s.potions > 0) return { type: 'potion' }
      if (c.kind !== 'boss' && rng() < 0.03) return { type: 'flee' }
      return { type: 'strike' }
    }
    case 'spoils': return { type: 'take_loot' }
    case 'chest': {
      if (r?.t !== 'chest') throw new Error('bad chest')
      if (r.opened) return { type: 'take_loot' }
      if (!r.inspected && s.torches > 0 && rng() < 0.3) return { type: 'inspect' }
      return rng() < 0.05 ? { type: 'leave' } : { type: 'open_chest' }
    }
    case 'event': {
      if (r?.t !== 'event') throw new Error('bad event')
      if (r.done) return r.then === 'take_loot' ? { type: 'take_loot' } : r.then === 'fight_now' ? { type: 'fight_now' } : { type: 'continue' }
      const view = buildDescentView('run', s)
      const ok = view.event!.choices.filter((c) => !c.disabledReason)
      return { type: 'choose', i: ok[Math.floor(rng() * ok.length)].i }
    }
    case 'camp': {
      if (r?.t !== 'camp') throw new Error('bad camp')
      if (r.done) return rng() < 0.1 ? { type: 'escape' } : { type: 'continue' }
      if (s.bag.gold > 0 && rng() < 0.4) return { type: 'camp', k: 'stash' }
      return { type: 'camp', k: s.hp < s.maxHp * 0.7 ? 'rest' : 'sharpen' }
    }
    case 'merchant': {
      const view = buildDescentView('run', s)
      const ware = view.merchant!.wares.find((w) => w.available)
      if (ware && rng() < 0.5) return { type: 'buy', i: ware.i }
      return { type: 'continue' }
    }
    case 'relic': {
      if (r?.t !== 'relic') throw new Error('bad relic')
      return { type: 'take_relic', k: r.choices[0] ?? null }
    }
    case 'depthClear': return rng() < 0.15 ? { type: 'escape' } : { type: 'descend' }
    default: throw new Error(`no action for ${s.screen}`)
  }
}

async function playRun(seed: number): Promise<{ state: DescentState; effects: Effect[]; steps: number }> {
  const rng = mulberry32(seed)
  let s = createRun(SCALE, rng)
  const effects: Effect[] = []
  let steps = 0
  let n = 0
  while (s.screen !== 'result' && steps < 3000) {
    const res = applyAction(s, botAction(s, rng), rng)
    await resolvePendingLoot(res.state, async () => fakeItem(n++))
    expect(res.state.seq).toBe(s.seq + 1)
    expect(res.state.hp).toBeGreaterThanOrEqual(0)
    expect(res.state.hp).toBeLessThanOrEqual(res.state.maxHp)
    expect(res.state.potions).toBeLessThanOrEqual(DESCENT.MAX_POTIONS)
    expect(res.state.torches).toBeLessThanOrEqual(DESCENT.MAX_TORCHES)
    effects.push(...res.effects)
    s = res.state
    steps++
  }
  return { state: s, effects, steps }
}

describe('descent engine', () => {
  it('starts with the decided numbers', () => {
    const s = createRun(SCALE, mulberry32(1))
    expect(s.screen).toBe('depthCard')
    expect(s.hp).toBe(1000)
    expect(s.potions).toBe(3)
    expect(s.torches).toBe(2)
    expect(DEPTHS[2].bossHp).toBe(1035)
    expect(DEPTHS[2].bossDmg).toBe(100)
  })

  it('generates connected depths ending in a camp row and a guardian', () => {
    for (let seed = 1; seed <= 200; seed++) {
      const rng = mulberry32(seed)
      for (let d = 0; d < DEPTHS.length; d++) {
        const map = genDepth(d, rng)
        expect(map.rows.length).toBe(DEPTHS[d].rows + 1)
        const last = map.rows[map.rows.length - 2]
        expect(last.some((n) => n.type === 'camp')).toBe(true)
        expect(map.rows[map.rows.length - 1][0].type).toBe('boss')
        const ids = new Set(map.rows.flat().map((n) => n.id))
        for (const n of map.rows.flat()) for (const next of n.next) expect(ids.has(next)).toBe(true)
        // every node is reachable from the start
        const seen = new Set<string>(map.startNext)
        const queue = [...map.startNext]
        while (queue.length) {
          const id = queue.shift()!
          const node = map.rows.flat().find((x) => x.id === id)!
          for (const nx of node.next) if (!seen.has(nx)) { seen.add(nx); queue.push(nx) }
        }
        expect(seen.size).toBe(ids.size)
      }
    }
  })

  // ~2 s locally; CI runners are 2-3x slower than that, so give it room (5 s default timed out on CI).
  it('plays a couple of hundred random runs to a clean end', { timeout: 30_000 }, async () => {
    const outcomes: Record<string, number> = {}
    for (let seed = 1; seed <= 200; seed++) {
      const { state, effects, steps } = await playRun(seed)
      expect(steps).toBeLessThan(3000)
      expect(state.screen).toBe('result')
      expect(state.outcome).not.toBeNull()
      expect(effects.filter((e) => e.type === 'end')).toHaveLength(1)
      expect(effects[effects.length - 1].type === 'end' || effects.some((e) => e.type === 'end')).toBe(true)
      outcomes[state.outcome!] = (outcomes[state.outcome!] ?? 0) + 1
    }
    expect(Object.keys(outcomes).length).toBeGreaterThan(1)
  })

  it('death costs exactly half the bag', () => {
    const rng = mulberry32(7)
    let s = createRun(SCALE, rng)
    s = applyAction(s, { type: 'begin_depth' }, rng).state
    const combatNode = nextIds(s).map((id) => findNode(s, id)!).find((n) => n.type === 'combat')
      ?? findNode(s, nextIds(s)[0])!
    combatNode.type = 'combat'
    combatNode.dark = false
    s = applyAction(s, { type: 'move', nodeId: combatNode.id }, rng).state
    s.bag = { gold: 801, items: [fakeItem(1), fakeItem(2), fakeItem(3), fakeItem(4)] }
    s.hp = 1
    s.combat!.dmg = 10_000
    let res = applyAction(s, { type: 'brace' }, rng)
    // a block saves you; keep bracing until something lands
    while (res.state.screen !== 'result') res = applyAction(res.state, { type: 'brace' }, rng)
    expect(res.state.outcome).toBe('dead')
    expect(res.state.loss!.gold).toBe(401)
    expect(res.state.bag.gold).toBe(400)
    expect(res.state.loss!.items).toHaveLength(2)
    expect(res.state.bag.items).toHaveLength(2)
    const claim = res.effects.find((e) => e.type === 'claim')
    expect(claim && claim.type === 'claim' && claim.gold).toBe(400)
    expect(claim && claim.type === 'claim' && claim.reason).toBe('death')
  })

  it('stashing claims the bag immediately and empties it', () => {
    const rng = mulberry32(3)
    const s = createRun(SCALE, rng)
    s.screen = 'camp'
    s.room = { t: 'camp', done: false, text: null, k: null }
    s.bag = { gold: 120, items: [fakeItem(9)] }
    const res = applyAction(s, { type: 'camp', k: 'stash' }, rng)
    expect(res.state.bag.gold).toBe(0)
    expect(res.state.safe.gold).toBe(120)
    expect(res.effects).toEqual([{ type: 'claim', gold: 120, entries: [fakeItem(9)], reason: 'stash' }])
  })

  it('rejects actions that do not fit the screen', () => {
    const rng = mulberry32(5)
    const s = createRun(SCALE, rng)
    expect(() => applyAction(s, { type: 'strike' }, rng)).toThrow(DescentError)
    expect(() => applyAction(s, { type: 'move', nodeId: 'B' }, rng)).toThrow(DescentError)
  })

  it('never leaks hidden information in the view', () => {
    for (let seed = 1; seed <= 100; seed++) {
      const rng = mulberry32(seed)
      let s = createRun(SCALE, rng)
      s = applyAction(s, { type: 'begin_depth' }, rng).state
      for (const n of s.map.rows.flat()) if (n.type !== 'boss') n.dark = true
      const view = buildDescentView('run', s)
      for (const o of view.fork!.options) {
        expect(o.known).toBe(false)
        expect(o.type).toBeNull()
      }
      for (const n of view.map.rows.flat()) if (n.type !== null) expect(n.type).toBe('boss')
      expect(JSON.stringify(view)).not.toContain('mimic')
    }
    // closed chest hides its loot; rune trap hidden until studied
    const rng = mulberry32(11)
    const s = createRun(SCALE, rng)
    s.screen = 'chest'
    s.room = { t: 'chest', tier: 'gold', mimic: true, inspected: false, opened: false, loot: [{ kind: 'gold', n: 50 }] }
    const chest = buildDescentView('run', s)
    expect(chest.chest!.loot).toHaveLength(0)
    expect(JSON.stringify(chest)).not.toContain('"mimic":true')
    s.screen = 'event'
    s.room = { t: 'event', id: 'runes', done: false, text: null, loot: [], then: null, fight: null, studied: false, trap: 1, vault: 0 }
    const runes = buildDescentView('run', s)
    expect(runes.event!.runes!.every((r) => r.state === 'unknown')).toBe(true)
    expect(JSON.stringify(runes)).not.toContain('"trap":1')
  })
})
