/**
 * Dice combat — the table (play mat) a duel is fought on.
 *
 * The fight happens on the DEFENDER's table: when the opponent changes, the
 * mat under the 3D dice changes with them. The client only draws it; the
 * key travels in `/pvp/match/start` as `dice_table`.
 * Design: docs/06_game_systems/DICE_3D_THROW.md §7.
 *
 * Pick order:
 *   1. a cosmetic table the defender has equipped (not built yet — `cosmetic`)
 *   2. the mode's table: dungeon boss / rush miniboss → dragon, rush room → dungeon
 *   3. the defender's class: warrior / rogue / mage / tank
 *   4. tavern
 *
 * `arena`, `frost` and `royal` are not picked automatically — they are kept
 * for cosmetics, seasons and the top league.
 */

export const DICE_TABLE_KEYS = [
  'tavern',
  'warrior',
  'rogue',
  'mage',
  'tank',
  'arena',
  'dungeon',
  'dragon',
  'frost',
  'royal',
] as const

export type DiceTableKey = (typeof DICE_TABLE_KEYS)[number]

export function isDiceTableKey(v: unknown): v is DiceTableKey {
  return typeof v === 'string' && (DICE_TABLE_KEYS as readonly string[]).includes(v)
}

const CLASS_TABLE: Record<string, DiceTableKey> = {
  warrior: 'warrior',
  rogue: 'rogue',
  mage: 'mage',
  tank: 'tank',
}

export interface DiceTableInput {
  opponentType: 'pvp' | 'bot' | 'dungeon_boss' | 'dungeon_rush'
  /** Defender class (`CharacterClass`), if it has one. */
  defenderClass?: string | null
  /** Rush room type for `dungeon_rush` (`combat` | `miniboss` | …). */
  rushRoomType?: string | null
  /** Equipped cosmetic table of the defender, once cosmetics exist. */
  cosmetic?: string | null
}

export function diceTableFor(input: DiceTableInput): DiceTableKey {
  if (isDiceTableKey(input.cosmetic)) return input.cosmetic
  if (input.opponentType === 'dungeon_boss') return 'dragon'
  if (input.opponentType === 'dungeon_rush') return input.rushRoomType === 'miniboss' ? 'dragon' : 'dungeon'
  const byClass = input.defenderClass ? CLASS_TABLE[input.defenderClass] : undefined
  return byClass ?? 'tavern'
}
