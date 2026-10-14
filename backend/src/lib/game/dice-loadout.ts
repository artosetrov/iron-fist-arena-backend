// =============================================================================
// dice-loadout.ts — which runes sit on which faces, for players and bots
// Spec: docs/06_game_systems/DICE_RUNES_DESIGN.md §2, §5, §6
// =============================================================================

import { prisma } from '@/lib/prisma'
import {
  MAX_GREAT_PER_DIE, MAX_RUNES_PER_DIE, RUNES, runeByKey, runeByNodeKey, runesForClass,
  socketsForLevel, socketUnlockLevel, type RuneDef, type RuneDie,
} from './runes'

export interface DiceLoadout {
  atk: (string | null)[]
  grd: (string | null)[]
}

export const emptyLoadout = (): DiceLoadout => ({ atk: Array(6).fill(null), grd: Array(6).fill(null) })

/** Rune keys a character owns = rune nodes unlocked in the talent tree. */
export async function ownedRuneKeys(characterId: string): Promise<Set<string>> {
  const nodeKeys = RUNES.map((r) => r.nodeKey)
  const rows = await prisma.characterPassive.findMany({
    where: { characterId, currentRank: { gte: 1 }, node: { nodeKey: { in: nodeKeys } } },
    select: { node: { select: { nodeKey: true } } },
  })
  const owned = new Set<string>()
  for (const r of rows) {
    const rune = runeByNodeKey(r.node.nodeKey)
    if (rune) owned.add(rune.key)
  }
  return owned
}

/**
 * The character's socketed runes as two 6-slot arrays, keeping only what is
 * still legal right now (rune owned, right class + die, socket open by level,
 * caps respected). Combat trusts this, not the raw table.
 */
export async function loadDiceLoadout(
  characterId: string,
  cls: string,
  level: number,
): Promise<DiceLoadout> {
  const [rows, owned] = await Promise.all([
    prisma.characterDieRune.findMany({
      where: { characterId },
      orderBy: { faceIndex: 'asc' },
      select: { die: true, faceIndex: true, runeKey: true },
    }),
    ownedRuneKeys(characterId),
  ])
  return sanitizeLoadout(rows, owned, cls, level)
}

export function sanitizeLoadout(
  rows: Array<{ die: string; faceIndex: number; runeKey: string }>,
  owned: Set<string>,
  cls: string,
  level: number,
): DiceLoadout {
  const out = emptyLoadout()
  const sockets = socketsForLevel(level)
  const count = { atk: 0, grd: 0 }
  const greats = { atk: 0, grd: 0 }
  for (const row of rows) {
    const die = row.die as RuneDie
    if (die !== 'atk' && die !== 'grd') continue
    const rune = runeByKey(row.runeKey)
    if (!rune || rune.class !== cls || rune.die !== die || !owned.has(rune.key)) continue
    if (row.faceIndex < 0 || row.faceIndex > 5) continue
    if (count[die] >= Math.min(sockets[die], MAX_RUNES_PER_DIE)) continue
    if (rune.tier === 'great' && greats[die] >= MAX_GREAT_PER_DIE) continue
    out[die][row.faceIndex] = rune.key
    count[die] += 1
    if (rune.tier === 'great') greats[die] += 1
  }
  return out
}

function hash(s: string): number {
  let h = 2166136261 | 0
  for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619) }
  return h >>> 0
}

/**
 * NPC bots carry runes too, so the arena reads the same at every level. A bot
 * fills the sockets its level allows with its class's runes — Lesser always,
 * Path from L15, one Great from L25 — picked and placed by a hash of its id.
 */
export function botDiceLoadout(botId: string, cls: string, level: number): DiceLoadout {
  const out = emptyLoadout()
  const sockets = socketsForLevel(level)
  const pool = runesForClass(cls)
  for (const die of ['atk', 'grd'] as RuneDie[]) {
    const eligible = pool.filter((r) => r.die === die && (
      r.tier === 'lesser' || (r.tier === 'path' && level >= 15) || (r.tier === 'great' && level >= 25)
    ))
    const ranked = [...eligible].sort((a, b) => hash(`${botId}:${a.key}`) - hash(`${botId}:${b.key}`))
    const picked: RuneDef[] = []
    for (const r of ranked) {
      if (picked.length >= Math.min(sockets[die], MAX_RUNES_PER_DIE)) break
      if (r.tier === 'great' && picked.some((p) => p.tier === 'great')) continue
      picked.push(r)
    }
    // one rune per zone first (faces 0/2/4, rotated by the bot's hash), then the twins 1/3/5
    const rot = hash(`${botId}:${die}`) % 3
    const order = [0, 1, 2].map((i) => [0, 2, 4][(i + rot) % 3]).concat([1, 3, 5])
    picked.forEach((r, i) => { out[die][order[i]] = r.key })
  }
  return out
}

/** Name/desc/asset for every rune on the loadouts — what the client needs to draw them. */
export function runeInfoFor(...loadouts: DiceLoadout[]) {
  const seen = new Set<string>()
  const info: Array<{ key: string; name: string; desc: string; asset: string; die: RuneDie; tier: string }> = []
  for (const l of loadouts) {
    for (const key of [...l.atk, ...l.grd]) {
      const r = runeByKey(key)
      if (r && !seen.has(r.key)) {
        seen.add(r.key)
        info.push({ key: r.key, name: r.name, desc: r.desc, asset: r.asset, die: r.die, tier: r.tier })
      }
    }
  }
  return info
}

// --- profile "Dice" tab payload (GET /api/dice, POST /api/dice/socket) ---------

export async function hasLiveMatch(characterId: string): Promise<boolean> {
  const live = await prisma.pvpMatch.findFirst({
    where: { player1Id: characterId, status: 'in_progress', interactiveTimeoutAt: { gt: new Date() } },
    select: { id: true },
  })
  return live !== null
}

export async function buildDicePayload(character: { id: string; class: string; level: number }) {
  const classRunes = runesForClass(character.class)
  const [rows, owned, nodes, inMatch] = await Promise.all([
    prisma.characterDieRune.findMany({
      where: { characterId: character.id },
      select: { die: true, faceIndex: true, runeKey: true },
    }),
    ownedRuneKeys(character.id),
    prisma.passiveNode.findMany({
      where: { nodeKey: { in: classRunes.map((r) => r.nodeKey) } },
      select: { id: true, nodeKey: true, name: true, cost: true },
    }),
    hasLiveMatch(character.id),
  ])
  const loadout = sanitizeLoadout(rows, owned, character.class, character.level)
  const sockets = socketsForLevel(character.level)
  const nodeByKey = new Map(nodes.map((n) => [n.nodeKey, n]))
  const placed = new Map<string, { die: RuneDie; face: number }>()
  for (const die of ['atk', 'grd'] as RuneDie[]) {
    loadout[die].forEach((k, face) => { if (k) placed.set(k, { die, face }) })
  }
  const dieBlock = (die: RuneDie) => {
    const count = loadout[die].filter(Boolean).length
    const next = socketUnlockLevel(die, sockets[die] + 1)
    return {
      runes: loadout[die],
      sockets: sockets[die],
      max_sockets: MAX_RUNES_PER_DIE,
      next_socket_level: next,
      used: count,
      /** Honest per-round chance a rune face lands with no Focus spent. */
      land_chance: count / 6,
    }
  }
  return {
    character_id: character.id,
    level: character.level,
    class: character.class,
    faces: ['head', 'head', 'chest', 'chest', 'legs', 'legs'],
    in_match: inMatch,
    dice: { atk: dieBlock('atk'), grd: dieBlock('grd') },
    runes: classRunes.map((r) => {
      const node = nodeByKey.get(r.nodeKey)
      return {
        key: r.key,
        name: r.name,
        desc: r.desc,
        asset: r.asset,
        die: r.die,
        tier: r.tier,
        owned: owned.has(r.key),
        socketed: placed.get(r.key) ?? null,
        node_key: r.nodeKey,
        node_id: node?.id ?? null,
        node_name: node?.name ?? null,
        node_cost: node?.cost ?? null,
      }
    }),
  }
}
