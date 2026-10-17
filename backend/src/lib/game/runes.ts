// =============================================================================
// runes.ts — the 36-rune catalog for dice combat
// Spec: docs/06_game_systems/DICE_RUNES_DESIGN.md §2–§3
// =============================================================================
//
// A rune sits on one face of one die and fires when that face lands. Owning a
// rune = having its talent node unlocked (CharacterPassive.currentRank ≥ 1);
// there is no separate ownership table. Placement lives in character_die_runes.
//
// Numbers are starting values; the dice engine (dice.ts) reads them from
// RUNE_PARAMS so a balance pass touches one table.

import type { CharacterClassType } from './combat'

export type RuneDie = 'atk' | 'grd'
export type RuneTier = 'lesser' | 'path' | 'great'

export interface RuneDef {
  /** `<class>.<slug>`, e.g. `warrior.headsman` — stored in character_die_runes.rune_key. */
  key: string
  slug: string
  class: CharacterClassType
  tier: RuneTier
  die: RuneDie
  /** Talent node that unlocks the rune. Lesser runes get new `<class>.rune.<slug>` nodes. */
  nodeKey: string
  name: string
  /** One line, player-facing. */
  desc: string
  /** Assets.xcassets imageset name. */
  asset: string
}

type Row = [slug: string, tier: RuneTier, die: RuneDie, nodeKey: string, name: string, desc: string]

const TABLE: Record<CharacterClassType, Row[]> = {
  warrior: [
    ['wrath', 'lesser', 'atk', 'warrior.rune.wrath', 'Wrath', 'On hit: +1 Focus'],
    ['blade', 'lesser', 'atk', 'warrior.rune.blade', 'Blade', 'This face hits 15% harder'],
    ['mail', 'lesser', 'grd', 'warrior.rune.mail', 'Mail', 'Hits taken −40%'],
    ['endurance', 'lesser', 'grd', 'warrior.rune.endurance', 'Endurance', 'On block: heal 20% HP'],
    ['frenzy', 'path', 'atk', 'warrior.key.frenzy', 'Frenzy', 'On hit: a second strike at 40%'],
    ['bulwark', 'path', 'grd', 'warrior.key.bulwark', 'Bulwark', 'On block: heal 20% HP and +1 Focus'],
    ['headsman', 'path', 'atk', 'warrior.key.headsman', 'Headsman', 'Enemy under 40% HP: crit ×2, can’t be blocked'],
    ['beast', 'great', 'atk', 'warrior.ult.unleash', 'Beast', '×1.8 to any zone; you take +15% this round'],
    ['oath', 'great', 'grd', 'warrior.ult.champion', 'Oath', 'Other zones −30%; your strike +20%'],
  ],
  rogue: [
    ['dagger', 'lesser', 'atk', 'rogue.rune.dagger', 'Dagger', 'If blocked: 60% still lands'],
    ['bloodletting', 'lesser', 'atk', 'rogue.rune.bloodletting', 'Bloodletting', 'On hit: bleed 25% next round'],
    ['evasion', 'lesser', 'grd', 'rogue.rune.evasion', 'Evasion', 'On block: +3 Focus'],
    ['smoke', 'lesser', 'grd', 'rogue.rune.smoke', 'Smoke', '20%: a strike at another zone misses'],
    ['shadowstrike', 'path', 'atk', 'rogue.key.shadowstrike', 'Shadowstrike', 'Striking first: crits and can’t be blocked'],
    ['riposte', 'path', 'grd', 'rogue.key.riposte_master', 'Riposte', 'On block: counter for 140% of your hit'],
    ['venom', 'path', 'atk', 'rogue.key.envenom', 'Venom', 'On hit: poison 20% for 2 rounds'],
    ['vanish', 'great', 'grd', 'rogue.ult.vanish', 'Vanish', '35%: a strike at you misses, +1 Focus'],
    ['reaper', 'great', 'atk', 'rogue.ult.shadow_reaper', 'Reaper', 'Crit ×1.5; unblockable on a poisoned foe'],
  ],
  mage: [
    ['spark', 'lesser', 'atk', 'mage.rune.spark', 'Spark', '+15% damage, ignores Wall'],
    ['mana', 'lesser', 'atk', 'mage.rune.mana', 'Mana', 'On land: +1 Focus'],
    ['barrier', 'lesser', 'grd', 'mage.rune.barrier', 'Barrier', 'Hits taken −30%'],
    ['mirror', 'lesser', 'grd', 'mage.rune.mirror', 'Mirror', 'On block: reflect 60% back'],
    ['flame', 'path', 'atk', 'mage.key.ignite', 'Flame', 'Ignores Wall; on hit: burn 20% for 2 rounds'],
    ['flow', 'path', 'grd', 'mage.key.manaflow', 'Flow', 'On land: +2 Focus'],
    ['frost', 'path', 'grd', 'mage.key.frostbite', 'Frost', 'Struck here: freeze — their attack die locks, −30%'],
    ['meteor', 'great', 'atk', 'mage.ult.meteor', 'Meteor', 'At least ×1.2 and can’t be blocked'],
    ['time', 'great', 'grd', 'mage.ult.timewarp', 'Time', 'On land: +1 Focus, and refunds an attack-die action'],
  ],
  tank: [
    ['ram', 'lesser', 'atk', 'tank.rune.ram', 'Ram', '+15% damage; on legs the sweep lasts 2 rounds'],
    ['stone', 'lesser', 'grd', 'tank.rune.stone', 'Stone', 'Hits taken −30%'],
    ['thorns', 'lesser', 'grd', 'tank.rune.thorns', 'Thorns', 'On take: 25% goes back to the attacker'],
    ['fortify', 'lesser', 'grd', 'tank.rune.fortify', 'Fortify', 'On block: heal 20% HP'],
    ['challenge', 'path', 'atk', 'tank.key.taunt', 'Challenge', '+20% damage; on hit: their next attack lands on your guard'],
    ['wall', 'path', 'grd', 'tank.key.aegis_wall', 'Wall', 'Other zones −40%'],
    ['unbreakable', 'path', 'grd', 'tank.key.unstoppable', 'Unbreakable', 'Hits −25%; under 50% HP a hit takes ≤ 10% HP'],
    ['bastion', 'great', 'grd', 'tank.ult.fortress', 'Bastion', 'Other zones −30%; reflects 30% of every hit'],
    ['earthshatter', 'great', 'atk', 'tank.ult.earthshatter', 'Earthshatter', 'On hit: 50% stun — they skip their next strike'],
  ],
}

export const RUNES: readonly RuneDef[] = (Object.keys(TABLE) as CharacterClassType[]).flatMap((cls) =>
  TABLE[cls].map(([slug, tier, die, nodeKey, name, desc]) => ({
    key: `${cls}.${slug}`,
    slug,
    class: cls,
    tier,
    die,
    nodeKey,
    name,
    desc,
    asset: `rune-${cls}-${slug}`,
  })),
)

const BY_KEY = new Map(RUNES.map((r) => [r.key, r]))
const BY_NODE = new Map(RUNES.map((r) => [r.nodeKey, r]))

export function runeByKey(key: string | null | undefined): RuneDef | null {
  return key ? BY_KEY.get(key) ?? null : null
}
export function runeByNodeKey(nodeKey: string): RuneDef | null {
  return BY_NODE.get(nodeKey) ?? null
}
export function runesForClass(cls: string): RuneDef[] {
  return RUNES.filter((r) => r.class === cls)
}

/** Rune slug ('headsman') from a key ('warrior.headsman'); the engine switches on slugs. */
export function runeSlug(key: string | null | undefined): string | null {
  return runeByKey(key)?.slug ?? null
}

// --- Sockets ------------------------------------------------------------------

/** §2.2 — sockets per die by level. Max 3 per die keeps half the faces bare. */
export const SOCKET_TABLE: ReadonlyArray<{ level: number; atk: number; grd: number }> = [
  { level: 2, atk: 1, grd: 0 },
  { level: 4, atk: 1, grd: 1 },
  { level: 8, atk: 2, grd: 1 },
  { level: 12, atk: 2, grd: 2 },
  { level: 20, atk: 3, grd: 2 },
  { level: 25, atk: 3, grd: 3 },
]

export const MAX_RUNES_PER_DIE = 3
export const MAX_GREAT_PER_DIE = 1

export function socketsForLevel(level: number): { atk: number; grd: number } {
  let atk = 0
  let grd = 0
  for (const row of SOCKET_TABLE) {
    if (level >= row.level) { atk = row.atk; grd = row.grd }
  }
  return { atk, grd }
}

/** Level at which the n-th (1-based) socket of a die opens, or null if never. */
export function socketUnlockLevel(die: RuneDie, n: number): number | null {
  for (const row of SOCKET_TABLE) {
    if ((die === 'atk' ? row.atk : row.grd) >= n) return row.level
  }
  return null
}

// --- Effect numbers -----------------------------------------------------------

export const RUNE_PARAMS = {
  blade: { mult: 1.15 },
  spark: { mult: 1.15 },
  ram: { mult: 1.15, sweepRounds: 2 },
  challenge: { mult: 1.2 },
  frenzy: { extra: 0.4 },
  headsman: { hpBelow: 0.4, mult: 2.0 },
  shadowstrike: { mult: 1.3 },
  beast: { mult: 1.8, selfVuln: 1.15 },
  oath: { strikeBonus: 1.2, otherZone: 0.7 },
  meteor: { mult: 1.2 },
  reaper: { mult: 1.5 },
  dagger: { pierce: 0.6 },
  smoke: { missChance: 0.2 },
  vanish: { missChance: 0.35, focus: 1 },
  mail: { take: 0.6 },
  barrier: { take: 0.7 },
  stone: { take: 0.7 },
  wall: { otherZone: 0.6 },
  unbreakable: { take: 0.75, hpBelow: 0.5, capPct: 0.1 },
  thorns: { reflect: 0.25 },
  mirror: { reflect: 0.6 },
  bastion: { reflect: 0.3, otherZone: 0.7 },
  riposte: { counter: 1.4 },
  endurance: { healPct: 0.2 },
  fortify: { healPct: 0.2 },
  bulwark: { healPct: 0.2, focus: 1 },
  evasion: { focus: 3 },
  wrath: { focus: 1 },
  mana: { focus: 1 },
  flow: { focus: 2 },
  time: { bonus: 1 },
  bloodletting: { pct: 0.25, rounds: 1 },
  venom: { pct: 0.2, rounds: 2 },
  flame: { pct: 0.2, rounds: 2 },
  frost: { strikeMult: 0.7 },
  earthshatter: { stunChance: 0.5 },
} as const
