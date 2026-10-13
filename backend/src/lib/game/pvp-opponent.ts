/**
 * Guards that keep a player from fighting their own characters.
 *
 * Why this exists: gold and gems live on `users` (schema.prisma), but a user
 * may hold up to 5 characters (`api/characters/route.ts`). Every PvP route used
 * to check only `character_id !== opponent_id`, and matchmaking filtered
 * candidates by character id alone — so a geared main could farm a naked alt,
 * and BOTH the attacker payout and the defender payout landed in the same
 * `users` row. 200 gold + 200 XP per fight into one wallet, plus free rating
 * laundering, at zero risk.
 *
 * Two halves, and both are needed:
 *   - `sameOwner()` blocks the fight itself, wherever an opponent id arrives
 *     from the client.
 *   - `excludeOwnCharacters()` keeps a user's own alts out of the candidate
 *     lists, so the client is never offered a match it will then be refused.
 */

import { NextResponse } from 'next/server'

/** True when both characters belong to the same account. */
export function sameOwner(
  attacker: { userId: string },
  defender: { userId: string }
): boolean {
  return attacker.userId === defender.userId
}

/**
 * Standard refusal for a self-farm attempt. Deliberately vague to the client —
 * there is no legitimate flow that reaches it, and naming the rule only helps
 * someone probing for it.
 */
export function selfFarmResponse() {
  return NextResponse.json(
    { error: 'This opponent is not available.' },
    { status: 400 }
  )
}

/**
 * Prisma `where` fragment for matchmaking queries: exclude the player's own
 * character AND every other character on the same account.
 *
 * Spread into the `where` object:
 *   where: { ...excludeOwnCharacters(characterId, userId), level: {...} }
 */
export function excludeOwnCharacters(characterId: string, userId: string) {
  return {
    id: { not: characterId },
    userId: { not: userId },
  }
}
