// =============================================================================
// combat-seed.ts — per-match RNG seeds the client can't reproduce
// =============================================================================
//
// Mixes a server secret into (match, round, salt) so a modified client can't
// predict the opponent's dice or the AI's rerolls (see the 2026-10-14 audit
// note in /api/pvp/strike). FNV-1a, 32-bit.

const SEED_SECRET = process.env.COMBAT_SEED_SECRET ?? process.env.BOT_TICKET_SECRET ?? ''

export function deriveCombatSeed(matchId: string, round: number, salt: string): number {
  let h = 2166136261 | 0
  const s = `${SEED_SECRET}:${matchId}:${round}:${salt}`
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i)
    h = Math.imul(h, 16777619)
  }
  return h | 0
}
