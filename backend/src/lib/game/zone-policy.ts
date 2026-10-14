// =============================================================================
// zone-policy.ts — Who the opponent *is* when it picks zones.
//
// Combat v2 (docs/06_game_systems/COMBAT_V2_DESIGN.md §4). Before this module
// the opponent's attack/block zones in interactive combat came from a uniform
// seeded roll, so there was nothing to read and head/chest was the best reply
// every round. Now every non-human side plays a POLICY:
//
//   * a bot personality (aggressor / turtle / rhythm) — readable tells + noise
//   * a ghost — the real zone habits of a live player, recorded from their own
//     interactive rounds (`characters.zone_profile`), with a personality as
//     fallback until enough rounds exist
//
// Everything is deterministic given the rng the caller passes (seeded with the
// server secret in /pvp/strike), so a modified client still cannot predict it.
// Pure module: no DB, no config reads. Unit-tested in tests/lib/zone-policy.test.ts.
// =============================================================================

import { ZONE_POLICY, type BodyZone } from './balance'

export const ZONES: readonly BodyZone[] = ['head', 'chest', 'legs']

export type ZonePersonality = 'aggressor' | 'turtle' | 'rhythm'
export const PERSONALITIES: readonly ZonePersonality[] = ['aggressor', 'turtle', 'rhythm']

export interface ZonePick {
  attack: BodyZone
  block: BodyZone
}

/** Per-zone weights/counts. Not required to sum to 1. */
export type ZoneCounts = Record<BodyZone, number>

/**
 * Recorded zone habits of a player — the data a ghost plays from.
 * Stored on `characters.zone_profile` (Json). Counts decay after every match
 * (ZONE_POLICY.GHOST_DECAY) so recent habits dominate; `n` is the decayed
 * round count and gates whether the ghost is trusted at all.
 */
export interface ZoneProfile {
  v: 1
  n: number
  attack: ZoneCounts
  block: ZoneCounts
  /** What they attack after their own strike was blocked. */
  afterBlocked: { attack: ZoneCounts }
  /** Where they block after taking a crit. */
  afterTookCrit: { block: ZoneCounts }
  /** What they attack below 35% HP. */
  lowHp: { attack: ZoneCounts }
  /** Most recent rounds, oldest first — exposed to the client as the read-strip. */
  lastRounds: Array<{ a: BodyZone; b: BodyZone }>
}

export type ZonePolicy =
  | { kind: 'personality'; personality: ZonePersonality }
  | { kind: 'ghost'; profile: ZoneProfile; fallback: ZonePersonality }

/** What the policy may look at when picking. All optional — round 0 has nothing. */
export interface ZoneRoundContext {
  /** 0-based round index. */
  roundIndex: number
  /** The policy owner's HP fraction (0..1). */
  myHpPct: number
  /** The opponent's HP fraction (0..1). */
  oppHpPct: number
  last?: {
    myAttack: BodyZone
    myBlock: BodyZone
    oppAttack: BodyZone
    oppBlock: BodyZone
    /** My strike last round was blocked (or landed for reduced damage into a block). */
    myStrikeBlocked: boolean
    /** I took a crit last round. */
    iTookCrit: boolean
    /** My last strike was a crit. */
    iLandedCrit: boolean
  }
}

// --- helpers -----------------------------------------------------------------

export function zeroCounts(): ZoneCounts {
  return { head: 0, chest: 0, legs: 0 }
}

export function emptyZoneProfile(): ZoneProfile {
  return {
    v: 1,
    n: 0,
    attack: zeroCounts(),
    block: zeroCounts(),
    afterBlocked: { attack: zeroCounts() },
    afterTookCrit: { block: zeroCounts() },
    lowHp: { attack: zeroCounts() },
    lastRounds: [],
  }
}

export function isZone(v: unknown): v is BodyZone {
  return typeof v === 'string' && (ZONES as readonly string[]).includes(v)
}

function sampleWeighted(weights: ZoneCounts, rng: () => number): BodyZone {
  const total = weights.head + weights.chest + weights.legs
  if (!(total > 0)) return ZONES[Math.floor(rng() * 3) % 3]
  let r = rng() * total
  for (const z of ZONES) {
    r -= weights[z]
    if (r < 0) return z
  }
  return 'legs'
}

function uniform(rng: () => number): BodyZone {
  return ZONES[Math.min(2, Math.floor(rng() * 3))]
}

function withNoise(pick: BodyZone, noise: number, rng: () => number): BodyZone {
  return rng() < noise ? uniform(rng) : pick
}

function nextInCycle(z: BodyZone): BodyZone {
  return ZONES[(ZONES.indexOf(z) + 1) % 3]
}

/** FNV-1a over the key → stable personality for a bot / boss / fallback. */
export function personalityForKey(key: string): ZonePersonality {
  let h = 2166136261 | 0
  for (let i = 0; i < key.length; i++) {
    h ^= key.charCodeAt(i)
    h = Math.imul(h, 16777619)
  }
  return PERSONALITIES[(h >>> 0) % PERSONALITIES.length]
}

/** Short, player-facing description of the tell. Shown at match start. */
export function personalityHint(p: ZonePersonality): string {
  switch (p) {
    case 'aggressor': return 'Goes for the head. Greedy after a crit.'
    case 'turtle': return 'Blocks where you last hit. Rarely attacks high.'
    case 'rhythm': return 'Fights in a rhythm. Watch three rounds.'
  }
}

// --- personalities -----------------------------------------------------------

function pickAggressor(ctx: ZoneRoundContext, rng: () => number): ZonePick {
  // 70% head; after landing a crit, repeats the same attack zone (greed).
  let attack: BodyZone
  if (ctx.last?.iLandedCrit) attack = ctx.last.myAttack
  else attack = rng() < 0.7 ? 'head' : (rng() < 0.5 ? 'chest' : 'legs')
  const block: BodyZone = rng() < 0.6 ? 'chest' : (rng() < 0.5 ? 'head' : 'legs')
  return { attack, block }
}

function pickTurtle(ctx: ZoneRoundContext, rng: () => number): ZonePick {
  // Blocks where it was hit last round (70%); never attacks head.
  const block: BodyZone = ctx.last && rng() < 0.7 ? ctx.last.oppAttack : uniform(rng)
  const attack: BodyZone = rng() < 0.65 ? 'chest' : 'legs'
  return { attack, block }
}

function pickRhythm(ctx: ZoneRoundContext): ZonePick {
  // attack head→chest→legs, block legs→head→chest. Three rounds and it's solved.
  const i = ctx.roundIndex % 3
  return { attack: ZONES[i], block: ZONES[(i + 2) % 3] }
}

export function pickPersonalityZones(
  personality: ZonePersonality,
  ctx: ZoneRoundContext,
  rng: () => number,
  noise: number = ZONE_POLICY.PERSONALITY_NOISE,
): ZonePick {
  const base =
    personality === 'aggressor' ? pickAggressor(ctx, rng)
    : personality === 'turtle' ? pickTurtle(ctx, rng)
    : pickRhythm(ctx)
  return {
    attack: withNoise(base.attack, noise, rng),
    block: withNoise(base.block, noise, rng),
  }
}

// --- ghost -------------------------------------------------------------------

export function ghostHasEnoughData(profile: ZoneProfile | null | undefined): profile is ZoneProfile {
  return !!profile && profile.v === 1 && profile.n >= ZONE_POLICY.GHOST_MIN_ROUNDS
}

function hasMass(c: ZoneCounts, min = 2): boolean {
  return c.head + c.chest + c.legs >= min
}

export function pickGhostZones(
  profile: ZoneProfile,
  ctx: ZoneRoundContext,
  rng: () => number,
  noise: number = ZONE_POLICY.GHOST_NOISE,
): ZonePick {
  // Context priority: lowHp → afterBlocked → base (attack); afterTookCrit → base (block).
  let attackWeights = profile.attack
  if (ctx.myHpPct <= 0.35 && hasMass(profile.lowHp.attack)) attackWeights = profile.lowHp.attack
  else if (ctx.last?.myStrikeBlocked && hasMass(profile.afterBlocked.attack)) attackWeights = profile.afterBlocked.attack

  let blockWeights = profile.block
  if (ctx.last?.iTookCrit && hasMass(profile.afterTookCrit.block)) blockWeights = profile.afterTookCrit.block

  return {
    attack: withNoise(sampleWeighted(attackWeights, rng), noise, rng),
    block: withNoise(sampleWeighted(blockWeights, rng), noise, rng),
  }
}

// --- entry point -------------------------------------------------------------

export function pickZones(policy: ZonePolicy, ctx: ZoneRoundContext, rng: () => number): ZonePick {
  if (policy.kind === 'ghost' && ghostHasEnoughData(policy.profile)) {
    return pickGhostZones(policy.profile, ctx, rng)
  }
  const personality = policy.kind === 'ghost' ? policy.fallback : policy.personality
  return pickPersonalityZones(personality, ctx, rng)
}

/** Build the policy for a character row: ghost when data exists, else a stable personality. */
export function policyForCharacter(
  characterId: string,
  zoneProfile: unknown,
): ZonePolicy {
  const profile = parseZoneProfile(zoneProfile)
  const fallback = personalityForKey(characterId)
  return profile ? { kind: 'ghost', profile, fallback } : { kind: 'personality', personality: fallback }
}

/** Human-readable kind for the client: what is the player actually reading? */
export function describePolicy(policy: ZonePolicy): {
  kind: 'ghost' | 'bot'
  personality: ZonePersonality | null
  hint: string
  pattern: BodyZone[]
} {
  if (policy.kind === 'ghost' && ghostHasEnoughData(policy.profile)) {
    return {
      kind: 'ghost',
      personality: null,
      hint: 'Plays like its owner. Study the strip.',
      pattern: profilePattern(policy.profile),
    }
  }
  const personality = policy.kind === 'ghost' ? policy.fallback : policy.personality
  return { kind: 'bot', personality, hint: personalityHint(personality), pattern: [] }
}

// --- profile maintenance -----------------------------------------------------

/** Defensive parse of the Json column. Anything malformed → null (fresh profile). */
export function parseZoneProfile(raw: unknown): ZoneProfile | null {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return null
  const r = raw as Record<string, unknown>
  if (r.v !== 1 || typeof r.n !== 'number') return null
  const counts = (v: unknown): ZoneCounts | null => {
    if (!v || typeof v !== 'object') return null
    const c = v as Record<string, unknown>
    const out = zeroCounts()
    for (const z of ZONES) {
      const x = c[z]
      if (typeof x !== 'number' || !Number.isFinite(x) || x < 0) return null
      out[z] = x
    }
    return out
  }
  const nested = (v: unknown, key: 'attack' | 'block'): ZoneCounts | null => {
    if (!v || typeof v !== 'object') return null
    return counts((v as Record<string, unknown>)[key])
  }
  const attack = counts(r.attack)
  const block = counts(r.block)
  const afterBlocked = nested(r.afterBlocked, 'attack')
  const afterTookCrit = nested(r.afterTookCrit, 'block')
  const lowHp = nested(r.lowHp, 'attack')
  if (!attack || !block || !afterBlocked || !afterTookCrit || !lowHp) return null
  const lastRounds = Array.isArray(r.lastRounds)
    ? r.lastRounds
        .filter((x): x is { a: BodyZone; b: BodyZone } =>
          !!x && typeof x === 'object' && isZone((x as Record<string, unknown>).a) && isZone((x as Record<string, unknown>).b))
        .map((x) => ({ a: x.a, b: x.b }))
    : []
  return {
    v: 1,
    n: r.n,
    attack,
    block,
    afterBlocked: { attack: afterBlocked },
    afterTookCrit: { block: afterTookCrit },
    lowHp: { attack: lowHp },
    lastRounds,
  }
}

/** One round as the profile owner experienced it. */
export interface ProfileRoundRecord {
  attack: BodyZone
  block: BodyZone
  /** Owner HP fraction at the START of the round. */
  hpPctBefore: number
  /** Owner's strike this round went into the opponent's block. */
  strikeBlocked: boolean
  /** Owner took a crit this round. */
  tookCrit: boolean
}

function decay(c: ZoneCounts, f: number): ZoneCounts {
  return { head: c.head * f, chest: c.chest * f, legs: c.legs * f }
}

/**
 * Fold one match's rounds into the profile. Pure; returns a new profile.
 * Old counts decay first, so ~30 rounds of history matter and a player who
 * changes style is re-learned within a few matches.
 */
export function updateZoneProfile(
  existing: ZoneProfile | null | undefined,
  rounds: ProfileRoundRecord[],
  decayFactor: number = ZONE_POLICY.GHOST_DECAY,
): ZoneProfile {
  const base = existing ?? emptyZoneProfile()
  if (rounds.length === 0) return base
  const p: ZoneProfile = {
    v: 1,
    n: base.n * decayFactor,
    attack: decay(base.attack, decayFactor),
    block: decay(base.block, decayFactor),
    afterBlocked: { attack: decay(base.afterBlocked.attack, decayFactor) },
    afterTookCrit: { block: decay(base.afterTookCrit.block, decayFactor) },
    lowHp: { attack: decay(base.lowHp.attack, decayFactor) },
    lastRounds: [...base.lastRounds],
  }
  let prev: ProfileRoundRecord | null = null
  for (const r of rounds) {
    p.n += 1
    p.attack[r.attack] += 1
    p.block[r.block] += 1
    if (prev?.strikeBlocked) p.afterBlocked.attack[r.attack] += 1
    if (prev?.tookCrit) p.afterTookCrit.block[r.block] += 1
    if (r.hpPctBefore <= 0.35) p.lowHp.attack[r.attack] += 1
    p.lastRounds.push({ a: r.attack, b: r.block })
    prev = r
  }
  if (p.lastRounds.length > ZONE_POLICY.PATTERN_TAIL) {
    p.lastRounds = p.lastRounds.slice(-ZONE_POLICY.PATTERN_TAIL)
  }
  // Round to keep the Json compact and the decay from producing 1e-17 dust.
  const r3 = (c: ZoneCounts): ZoneCounts => ({
    head: Math.round(c.head * 1000) / 1000,
    chest: Math.round(c.chest * 1000) / 1000,
    legs: Math.round(c.legs * 1000) / 1000,
  })
  p.n = Math.round(p.n * 1000) / 1000
  p.attack = r3(p.attack); p.block = r3(p.block)
  p.afterBlocked.attack = r3(p.afterBlocked.attack)
  p.afterTookCrit.block = r3(p.afterTookCrit.block)
  p.lowHp.attack = r3(p.lowHp.attack)
  return p
}

/** Attack zones of the recent rounds, oldest first — the client's read-strip. */
export function profilePattern(profile: ZoneProfile): BodyZone[] {
  return profile.lastRounds.map((r) => r.a)
}
