// =============================================================================
// progression.ts — Level up and prestige system
// =============================================================================

import { xpForLevel } from './balance';
import { PRESTIGE, PASSIVES } from './balance';

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
export function checkLevelUp(character: {
  currentXp: number;
  level: number;
}): LevelUpResult {
  let { currentXp, level } = character;
  let totalStatPoints = 0;
  let totalPassivePoints = 0;
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
    totalPassivePoints += PASSIVES.POINTS_PER_LEVEL;
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
    passivePointsAwarded: totalPassivePoints,
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
