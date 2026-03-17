// =============================================================================
// progression.ts — Level up and prestige system
// =============================================================================

import { xpForLevel } from './balance';
import { getPrestigeConfig, getPassivesConfig } from './live-config';

// Re-export for convenience
export { xpForLevel };

// --- Apply Level Up (DB helper) ---

/**
 * After XP has been incremented on a character, call this to check
 * and apply any pending level-ups. Works with both PrismaClient and
 * transaction contexts.
 *
 * @returns LevelUpResult or null if character not found
 */
export async function applyLevelUp(
  tx: { character: { findUnique: Function; update: Function } },
  characterId: string,
): Promise<LevelUpResult | null> {
  const character = await tx.character.findUnique({
    where: { id: characterId },
    select: { currentXp: true, level: true },
  });
  if (!character) return null;

  const result = checkLevelUp(character);
  if (!result.leveledUp) return result;

  await tx.character.update({
    where: { id: characterId },
    data: {
      level: result.newLevel,
      currentXp: result.remainingXp,
      statPointsAvailable: { increment: result.statPointsAwarded },
      passivePointsAvailable: { increment: result.passivePointsAwarded },
    },
  });

  return result;
}

// --- Types ---

export interface LevelUpResult {
  leveledUp: boolean;
  newLevel: number;
  remainingXp: number;
  statPointsAwarded: number;
  passivePointsAwarded: number;
}

export interface PrestigeResult {
  canPrestige: boolean;
  newPrestigeLevel: number;
  statBonusPercent: number;
}

// --- Level Up ---

/**
 * Check if a character has enough XP to level up.
 * Handles multiple level-ups in a single call (e.g. huge XP dump).
 *
 * @param character  Object with currentXp and level
 * @returns          Whether a level occurred, the new level, leftover XP, and stat points awarded
 */
export async function checkLevelUp(character: {
  currentXp: number;
  level: number;
}): Promise<LevelUpResult> {
  const prestigeConfig = await getPrestigeConfig();
  const passivesConfig = await getPassivesConfig();

  let { currentXp, level } = character;
  let totalStatPoints = 0;
  let totalPassivePoints = 0;
  const startLevel = level;

  // Allow multiple level-ups in one pass
  while (level < prestigeConfig.MAX_LEVEL) {
    const needed = xpForLevel(level + 1);
    if (currentXp < needed) {
      break;
    }
    currentXp -= needed;
    level += 1;
    totalStatPoints += prestigeConfig.STAT_POINTS_PER_LEVEL;
    totalPassivePoints += passivesConfig.POINTS_PER_LEVEL;
  }

  // Cap XP if at max level
  if (level >= prestigeConfig.MAX_LEVEL) {
    // Don't lose XP, but stop leveling
    // Player must prestige to continue
  }

  return {
    leveledUp: level > startLevel,
    newLevel: level,
    remainingXp: currentXp,
    statPointsAwarded: totalStatPoints,
    passivePointsAwarded: totalPassivePoints,
  };
}

// --- Prestige ---

/**
 * Check whether a character is eligible for prestige and compute the result.
 *
 * Prestige rules:
 * - Must be at max level
 * - Resets to level 1
 * - Keeps items
 * - Gains prestige_level + 1
 * - Bonus: +% all stats per prestige level
 *
 * @param currentLevel    Character's current level
 * @param currentPrestige Character's current prestige level
 */
export async function checkPrestige(
  currentLevel: number,
  currentPrestige: number,
): Promise<PrestigeResult> {
  const prestigeConfig = await getPrestigeConfig();
  const canPrestige = currentLevel >= prestigeConfig.MAX_LEVEL;
  const newPrestigeLevel = canPrestige ? currentPrestige + 1 : currentPrestige;
  const statBonusPercent = newPrestigeLevel * prestigeConfig.STAT_BONUS_PER_PRESTIGE * 100;

  return {
    canPrestige,
    newPrestigeLevel,
    statBonusPercent,
  };
}

/**
 * Apply prestige bonus to a base stat value.
 *
 * @param baseStat       The raw stat value
 * @param prestigeLevel  The character's prestige level
 * @returns              The stat value after prestige bonus
 */
export async function applyPrestigeBonus(baseStat: number, prestigeLevel: number): Promise<number> {
  const prestigeConfig = await getPrestigeConfig();
  const multiplier = 1 + prestigeLevel * prestigeConfig.STAT_BONUS_PER_PRESTIGE;
  return Math.floor(baseStat * multiplier);
}
