/**
 * Wagering minigames: the Shell Game, the Fortune Wheel and Fortune's Table.
 *
 * App Review (2026-11-16) refused 1.0.2 because the age rating declares
 * simulated gambling and the developer account is an individual one. Apple
 * accepts simulated gambling only from organization accounts. Until the
 * account is an organization the iOS build ships without these games
 * (`AppConstants.gamblingMinigamesEnabled`, a compile-time constant), and the
 * server stops handing out quests that point at them.
 *
 * The game endpoints themselves stay up for dev builds; no store build can
 * reach them. Turning the games back on takes BOTH a new iOS build with the
 * constant flipped AND this env var, plus an honest age rating
 * (Simulated Gambling ≠ None) on an organization account.
 */
export const GAMBLING_MINIGAMES_ENABLED = process.env.GAMBLING_MINIGAMES_ENABLED === 'true'

/** Daily / weekly quest types that can only be completed in a wagering game. */
export const GAMBLING_QUEST_TYPES: ReadonlySet<string> = new Set(['shell_game_play'])

/** Tutorial quests that send the player to a wagering game. */
export const GAMBLING_TUTORIAL_QUEST_IDS: ReadonlySet<string> = new Set(['try_tavern'])

/** True when a quest of this type may be offered to players right now. */
export function isQuestTypeOffered(questType: string): boolean {
  return GAMBLING_MINIGAMES_ENABLED || !GAMBLING_QUEST_TYPES.has(questType)
}
