/**
 * Zone policies — Combat v2 (docs/06_game_systems/COMBAT_V2_DESIGN.md §4).
 *
 * The opponent in interactive combat used to roll zones uniformly; now it
 * plays a readable policy. These tests pin:
 *   - determinism given the rng (server-seeded in /pvp/strike)
 *   - each personality's tell is real but noisy
 *   - a ghost falls back to a personality until it has data, then follows it
 *   - the profile folds rounds in, decays, and survives a Json round-trip
 */
import { describe, expect, it, vi } from 'vitest'

// combat.ts (for createSeededRng) pulls in live-config → prisma; keep the DB out.
vi.mock('@/lib/prisma', () => ({ prisma: {} }))
import { createSeededRng } from '../../src/lib/game/combat'
import { ZONE_POLICY, type BodyZone } from '../../src/lib/game/balance'
import {
  describePolicy,
  emptyZoneProfile,
  ghostHasEnoughData,
  parseZoneProfile,
  personalityForKey,
  pickPersonalityZones,
  pickZones,
  policyForCharacter,
  profilePattern,
  updateZoneProfile,
  type ProfileRoundRecord,
  type ZoneRoundContext,
} from '../../src/lib/game/zone-policy'

const ctx0: ZoneRoundContext = { roundIndex: 0, myHpPct: 1, oppHpPct: 1 }

function count<T extends string>(xs: T[]): Record<string, number> {
  return xs.reduce((acc, x) => ({ ...acc, [x]: (acc[x] ?? 0) + 1 }), {} as Record<string, number>)
}

describe('personalityForKey', () => {
  it('is stable for a key and covers all three personalities', () => {
    expect(personalityForKey('npc_warrior_1')).toBe(personalityForKey('npc_warrior_1'))
    const seen = new Set<string>()
    for (let i = 0; i < 200; i++) seen.add(personalityForKey(`bot_${i}`))
    expect(seen.size).toBe(3)
  })
})

describe('personalities', () => {
  it('are deterministic given the rng', () => {
    const a = pickPersonalityZones('aggressor', ctx0, createSeededRng(42))
    const b = pickPersonalityZones('aggressor', ctx0, createSeededRng(42))
    expect(a).toEqual(b)
  })

  it('aggressor goes for the head most of the time', () => {
    const rng = createSeededRng(7)
    const atk = Array.from({ length: 2000 }, () => pickPersonalityZones('aggressor', ctx0, rng).attack)
    const c = count(atk)
    expect(c.head / atk.length).toBeGreaterThan(0.55)
    // noise keeps every zone alive
    expect(c.chest).toBeGreaterThan(0)
    expect(c.legs).toBeGreaterThan(0)
  })

  it('aggressor repeats its zone after landing a crit', () => {
    const rng = createSeededRng(3)
    const ctx: ZoneRoundContext = {
      roundIndex: 4, myHpPct: 1, oppHpPct: 0.6,
      last: { myAttack: 'legs', myBlock: 'chest', oppAttack: 'head', oppBlock: 'head', myStrikeBlocked: false, iTookCrit: false, iLandedCrit: true },
    }
    const atk = Array.from({ length: 1000 }, () => pickPersonalityZones('aggressor', ctx, rng).attack)
    expect(count(atk).legs / atk.length).toBeGreaterThan(0.8)
  })

  it('turtle blocks where it was hit last round and never leads with the head', () => {
    const rng = createSeededRng(11)
    const ctx: ZoneRoundContext = {
      roundIndex: 2, myHpPct: 0.8, oppHpPct: 0.9,
      last: { myAttack: 'chest', myBlock: 'head', oppAttack: 'legs', oppBlock: 'chest', myStrikeBlocked: false, iTookCrit: false, iLandedCrit: false },
    }
    const picks = Array.from({ length: 2000 }, () => pickPersonalityZones('turtle', ctx, rng))
    expect(count(picks.map((p) => p.block)).legs / picks.length).toBeGreaterThan(0.6)
    // head attacks only ever come from noise
    expect(count(picks.map((p) => p.attack)).head / picks.length).toBeLessThan(ZONE_POLICY.PERSONALITY_NOISE)
  })

  it('rhythm cycles attack head→chest→legs and block legs→head→chest (noise off)', () => {
    const rng = createSeededRng(1)
    const seq = [0, 1, 2, 3].map((i) => pickPersonalityZones('rhythm', { ...ctx0, roundIndex: i }, rng, 0))
    expect(seq.map((p) => p.attack)).toEqual(['head', 'chest', 'legs', 'head'])
    expect(seq.map((p) => p.block)).toEqual(['legs', 'head', 'chest', 'legs'])
  })
})

function rounds(n: number, attack: BodyZone, block: BodyZone): ProfileRoundRecord[] {
  return Array.from({ length: n }, () => ({ attack, block, hpPctBefore: 1, strikeBlocked: false, tookCrit: false }))
}

describe('ghost profile', () => {
  it('starts empty and is not trusted until GHOST_MIN_ROUNDS', () => {
    const p = updateZoneProfile(null, rounds(ZONE_POLICY.GHOST_MIN_ROUNDS - 1, 'head', 'chest'))
    expect(ghostHasEnoughData(p)).toBe(false)
    const policy = policyForCharacter('char-1', p)
    expect(policy.kind).toBe('ghost')
    // falls back to the character's personality → same picks as that personality
    const rngA = createSeededRng(5)
    const rngB = createSeededRng(5)
    expect(pickZones(policy, ctx0, rngA)).toEqual(
      pickPersonalityZones(personalityForKey('char-1'), ctx0, rngB),
    )
    expect(describePolicy(policy).kind).toBe('bot')
  })

  it('follows the recorded habit once it has data', () => {
    const p = updateZoneProfile(null, rounds(12, 'legs', 'head'))
    expect(ghostHasEnoughData(p)).toBe(true)
    const policy = policyForCharacter('char-2', p)
    const rng = createSeededRng(9)
    const picks = Array.from({ length: 1000 }, () => pickZones(policy, ctx0, rng))
    expect(count(picks.map((x) => x.attack)).legs / picks.length).toBeGreaterThan(0.8)
    expect(count(picks.map((x) => x.block)).head / picks.length).toBeGreaterThan(0.8)
    const read = describePolicy(policy)
    expect(read.kind).toBe('ghost')
    expect(read.pattern.length).toBe(ZONE_POLICY.PATTERN_TAIL)
    expect(read.pattern.every((z) => z === 'legs')).toBe(true)
  })

  it('uses the conditional habit after its strike was blocked', () => {
    // Base habit: head. After a blocked strike this player switches to chest.
    const recs: ProfileRoundRecord[] = []
    for (let i = 0; i < 12; i++) {
      recs.push({ attack: 'head', block: 'chest', hpPctBefore: 1, strikeBlocked: true, tookCrit: false })
      recs.push({ attack: 'chest', block: 'chest', hpPctBefore: 1, strikeBlocked: false, tookCrit: false })
    }
    const p = updateZoneProfile(null, recs)
    const policy = policyForCharacter('char-3', p)
    const rng = createSeededRng(13)
    const ctxBlocked: ZoneRoundContext = {
      roundIndex: 3, myHpPct: 1, oppHpPct: 1,
      last: { myAttack: 'head', myBlock: 'chest', oppAttack: 'legs', oppBlock: 'head', myStrikeBlocked: true, iTookCrit: false, iLandedCrit: false },
    }
    const after = Array.from({ length: 1000 }, () => pickZones(policy, ctxBlocked, rng).attack)
    expect(count(after).chest / after.length).toBeGreaterThan(0.8)
  })

  it('decays old habits so a changed style is re-learned', () => {
    let p = updateZoneProfile(null, rounds(10, 'head', 'head'))
    for (let m = 0; m < 6; m++) p = updateZoneProfile(p, rounds(10, 'legs', 'legs'))
    expect(p.attack.legs).toBeGreaterThan(p.attack.head * 5)
    expect(profilePattern(p)).toEqual(Array(ZONE_POLICY.PATTERN_TAIL).fill('legs'))
  })

  it('survives a Json round-trip and rejects garbage', () => {
    const p = updateZoneProfile(emptyZoneProfile(), rounds(8, 'chest', 'legs'))
    expect(parseZoneProfile(JSON.parse(JSON.stringify(p)))).toEqual(p)
    expect(parseZoneProfile(null)).toBeNull()
    expect(parseZoneProfile({ v: 2 })).toBeNull()
    expect(parseZoneProfile({ v: 1, n: 3, attack: { head: -1, chest: 0, legs: 0 } })).toBeNull()
    expect(parseZoneProfile('nope')).toBeNull()
  })
})
