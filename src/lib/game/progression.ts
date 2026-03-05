// =============================================================================
// progression.ts — Level up and prestige system
// =============================================================================

import { xpForLevel } from './balance';
import { PRESTIGE } from './balance';

// Re-export for convenience
export { xpForLevel };

// --- Types ---

export interface LevelUpResult {
  leveledUp: boolean;
  newLevel: number;
  remainingXp: number;
  statPointsAwarded: number;
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
export function checkLevelUp(character: {
  currentXp: number;
  level: number;
}): LevelUpResult {
  let { currentXp, level } = character;
  let totalStatPoints = 0;
  const startLevel = level;

  // Allow multiple level-ups in one pass
  while (level < PRESTIGE.MAX_LEVEL) {
    const needed = xpForLevel(level + 1);
    if (currentXp < needed) {
      break;
    }
    currentXp -= needed;
    level += 1;
    totalStatPoints += PRESTIGE.STAT_POINTS_PER_LEVEL;
  }

  // Cap XP if at max level
  if (level >= PRESTIGE.MAX_LEVEL) {
    // Don't lose XP, but stop leveling
    // Player must prestige to continue
  }

  return {
    leveledUp: level > startLevel,
    newLevel: level,
    remainingXp: currentXp,
    statPointsAwarded: totalStatPoints,
  };
}

// --- Prestige ---

/**
 * Check whether a character is eligible for prestige and compute the result.
 *
 * Prestige rules:
 * - Must be level 50 (PRESTIGE.MAX_LEVEL)
 * - Resets to level 1
 * - Keeps items
 * - Gains prestige_level + 1
 * - Bonus: +5% all stats per prestige level
 *
 * @param currentLevel    Character's current level
 * @param currentPrestige Character's current prestige level
 */
export function checkPrestige(
  currentLevel: number,
  currentPrestige: number,
): PrestigeResult {
  const canPrestige = currentLevel >= PRESTIGE.MAX_LEVEL;
  const newPrestigeLevel = canPrestige ? currentPrestige + 1 : currentPrestige;
  const statBonusPercent = newPrestigeLevel * PRESTIGE.STAT_BONUS_PER_PRESTIGE * 100;

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
export function applyPrestigeBonus(baseStat: number, prestigeLevel: number): number {
  const multiplier = 1 + prestigeLevel * PRESTIGE.STAT_BONUS_PER_PRESTIGE;
  return Math.floor(baseStat * multiplier);
}
