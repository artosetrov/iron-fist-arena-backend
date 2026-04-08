// =============================================================================
// npc-bots.ts — NPC bot generation for new player onboarding
//
// New players (< NPC_FIGHT_THRESHOLD total PvP fights) face NPC bots
// with reduced stats to guarantee a positive first experience.
// Bots are virtual — they do NOT exist in the database.
// =============================================================================

import type { CharacterStats, CharacterClassType } from './combat'
import { emptyPassiveBonuses } from './passives'

/** Number of bot fights before transitioning to real PvP */
export const NPC_FIGHT_THRESHOLD = 3

/** Bot ID prefix — used to detect bot opponents throughout the PvP pipeline */
export const NPC_BOT_PREFIX = 'npc_'

/** Check if an opponent ID belongs to an NPC bot */
export function isNpcBot(opponentId: string): boolean {
  return opponentId.startsWith(NPC_BOT_PREFIX)
}

/** Check if a player still qualifies for bot matches */
export function shouldFaceBots(pvpWins: number, pvpLosses: number): boolean {
  return (pvpWins + pvpLosses) < NPC_FIGHT_THRESHOLD
}

// --- Bot stat scaling per fight number ---
// Fight 1: 65% stats (easy win), Fight 2: 80%, Fight 3: 90%
const BOT_DIFFICULTY: Record<number, number> = {
  0: 0.65,
  1: 0.80,
  2: 0.90,
}

function getBotDifficulty(totalFights: number): number {
  return BOT_DIFFICULTY[totalFights] ?? 0.90
}

// --- Fantasy name pools ---
const BOT_NAMES: Record<CharacterClassType, string[]> = {
  warrior: ['Ironjaw', 'Grimblade', 'Stonewall', 'Ashguard', 'Duskhelm'],
  rogue: ['Shadowstep', 'Nightfang', 'Silkblade', 'Whisperknife', 'Daggermist'],
  mage: ['Emberveil', 'Frostweave', 'Spellshard', 'Runewhisper', 'Ashflame'],
  tank: ['Bulwark', 'Ironhide', 'Shieldmaul', 'Granitewall', 'Steelguard'],
}

const BOT_ORIGINS = ['human', 'orc', 'skeleton', 'demon', 'dogfolk'] as const

// --- Bot avatar keys (use default skins so the client renders them) ---
const BOT_AVATARS: Record<string, string> = {
  human_male: 'human_male_default',
  human_female: 'human_female_default',
  orc_male: 'orc_male_default',
  orc_female: 'orc_female_default',
  skeleton_male: 'skeleton_male_default',
  skeleton_female: 'skeleton_female_default',
  demon_male: 'demon_male_default',
  demon_female: 'demon_female_default',
  dogfolk_male: 'dogfolk_male_default',
  dogfolk_female: 'dogfolk_female_default',
}

/**
 * Deterministically pick a value from an array using a seed index.
 */
function pickFromArray<T>(arr: T[], seed: number): T {
  return arr[Math.abs(seed) % arr.length]
}

/**
 * Generate a unique bot ID that encodes the fight number for reproducibility.
 * Format: npc_{class}_{fightIndex}_{timestamp}
 */
export function generateBotId(botClass: CharacterClassType, fightIndex: number): string {
  return `${NPC_BOT_PREFIX}${botClass}_${fightIndex}_${Date.now()}`
}

/**
 * Calculate maxHp using the same formula as character creation.
 */
function calculateMaxHp(vit: number, end: number): number {
  return 80 + vit * 5 + end * 3
}

/**
 * Generate an NPC bot opponent card for the opponents list.
 * Returns the same shape as the Prisma character select in /pvp/opponents.
 */
export function generateBotOpponentCard(
  playerLevel: number,
  playerClass: CharacterClassType,
  fightIndex: number,
): Record<string, unknown> {
  const difficulty = getBotDifficulty(fightIndex)
  const baseStat = 10

  // Bot class differs from player class for variety (rotate through classes)
  const allClasses: CharacterClassType[] = ['warrior', 'rogue', 'mage', 'tank']
  const botClass = allClasses[(allClasses.indexOf(playerClass) + fightIndex + 1) % allClasses.length]
  const botOrigin = pickFromArray([...BOT_ORIGINS], fightIndex + 7)
  const botGender = fightIndex % 2 === 0 ? 'male' : 'female'
  const botName = pickFromArray(BOT_NAMES[botClass], fightIndex)

  // Scale stats down by difficulty factor
  const scaledStat = (base: number) => Math.max(1, Math.floor(base * difficulty))

  const str = scaledStat(baseStat)
  const agi = scaledStat(baseStat)
  const vit = scaledStat(baseStat)
  const end = scaledStat(baseStat)
  const int_ = scaledStat(baseStat)
  const wis = scaledStat(baseStat)
  const luk = scaledStat(Math.floor(baseStat * 0.5)) // Low LUK = fewer crits
  const cha = scaledStat(baseStat)

  const maxHp = calculateMaxHp(vit, end)
  const botId = generateBotId(botClass, fightIndex)

  return {
    id: botId,
    characterName: botName,
    class: botClass,
    origin: botOrigin,
    level: playerLevel,
    pvpRating: 1000,
    pvpWins: fightIndex,
    pvpLosses: 0,
    pvpWinStreak: 0,
    maxHp,
    armor: scaledStat(5),
    magicResist: scaledStat(5),
    gender: botGender,
    avatar: BOT_AVATARS[`${botOrigin}_${botGender}`] ?? null,
    gearScore: 0,
    str, agi, vit, int: int_, wis, luk, cha,
    // Matchmaking sort fields
    ratingDiff: 0,
    levelDiff: 0,
    gearDiff: 0,
    isNpcBot: true, // Client hint — does NOT affect gameplay
  }
}

/**
 * Generate full CharacterStats for an NPC bot (used by combat engine).
 * The bot has NO skills and NO passive bonuses — pure auto-attack.
 * Stats are scaled down to ensure the player has an advantage.
 */
export function generateBotCombatStats(
  botId: string,
  playerStats: CharacterStats,
  totalFights: number,
): CharacterStats {
  const difficulty = getBotDifficulty(totalFights)
  const scaledStat = (value: number) => Math.max(1, Math.floor(value * difficulty))

  // Determine bot class from the ID (encoded in generateBotId)
  const parts = botId.replace(NPC_BOT_PREFIX, '').split('_')
  const botClass = (parts[0] as CharacterClassType) || 'warrior'
  const fightIndex = parseInt(parts[1], 10) || 0
  const botOrigin = pickFromArray([...BOT_ORIGINS], fightIndex + 7)
  const botGender = fightIndex % 2 === 0 ? 'male' : 'female'
  const botName = pickFromArray(BOT_NAMES[botClass], fightIndex)

  const str = scaledStat(playerStats.str)
  const agi = scaledStat(playerStats.agi)
  const vit = scaledStat(playerStats.vit)
  const end = scaledStat(playerStats.end)
  const int_ = scaledStat(playerStats.int)
  const wis = scaledStat(playerStats.wis)
  // Bot LUK is heavily nerfed — reduces crit chance significantly
  const luk = Math.max(1, Math.floor(playerStats.luk * difficulty * 0.4))
  const cha = scaledStat(playerStats.cha)

  const maxHp = calculateMaxHp(vit, end)

  return {
    id: botId,
    name: botName,
    class: botClass,
    level: playerStats.level,
    str,
    agi,
    vit,
    end: end,
    int: int_,
    wis,
    luk,
    cha,
    maxHp,
    currentHp: maxHp,
    armor: scaledStat(playerStats.armor),
    magicResist: scaledStat(playerStats.magicResist),
    avatar: BOT_AVATARS[`${botOrigin}_${botGender}`] ?? null,
    combatStance: { attack: 'chest', defense: 'chest' },
    equippedSkills: [], // Bots have no skills — auto-attack only
    passiveBonuses: emptyPassiveBonuses(), // No passive bonuses
  }
}
