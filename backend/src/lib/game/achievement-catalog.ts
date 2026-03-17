// =============================================================================
// achievement-catalog.ts — All achievement definitions
// =============================================================================

export interface AchievementDef {
  target: number;
  category: string;
  rewardType: string;
  rewardAmount: number;
  rewardId?: string;
}

/**
 * Master catalog of all achievements.
 *
 * Keys match the `achievementKey` column in the `achievements` table.
 * `target` is the progress value required to complete the achievement.
 */
export const ACHIEVEMENT_CATALOG: Record<string, AchievementDef> = {
  // -------------------------------------------------------------------------
  // PVP
  // -------------------------------------------------------------------------
  pvp_first_blood: {
    target: 1,
    category: 'pvp',
    rewardType: 'gold',
    rewardAmount: 100,
  },
  pvp_wins_10: {
    target: 10,
    category: 'pvp',
    rewardType: 'gold',
    rewardAmount: 500,
  },
  pvp_wins_50: {
    target: 50,
    category: 'pvp',
    rewardType: 'gems',
    rewardAmount: 2,
  },
  pvp_wins_100: {
    target: 100,
    category: 'pvp',
    rewardType: 'gems',
    rewardAmount: 5,
  },
  pvp_wins_500: {
    target: 500,
    category: 'pvp',
    rewardType: 'gems',
    rewardAmount: 10,
  },
  pvp_streak_5: {
    target: 5,
    category: 'pvp',
    rewardType: 'gold',
    rewardAmount: 1000,
  },
  pvp_streak_10: {
    target: 10,
    category: 'pvp',
    rewardType: 'gems',
    rewardAmount: 3,
  },

  // -------------------------------------------------------------------------
  // Revenge
  // -------------------------------------------------------------------------
  revenge_first: {
    target: 1,
    category: 'revenge',
    rewardType: 'gold',
    rewardAmount: 300,
  },
  revenge_wins_10: {
    target: 10,
    category: 'revenge',
    rewardType: 'gems',
    rewardAmount: 2,
  },

  // -------------------------------------------------------------------------
  // Level / Progression
  // -------------------------------------------------------------------------
  reach_level_10: {
    target: 10,
    category: 'progression',
    rewardType: 'gold',
    rewardAmount: 500,
  },
  reach_level_25: {
    target: 25,
    category: 'progression',
    rewardType: 'gems',
    rewardAmount: 2,
  },
  reach_level_50: {
    target: 50,
    category: 'progression',
    rewardType: 'gems',
    rewardAmount: 5,
  },

  // -------------------------------------------------------------------------
  // Prestige
  // -------------------------------------------------------------------------
  first_prestige: {
    target: 1,
    category: 'prestige',
    rewardType: 'gems',
    rewardAmount: 10,
  },
  prestige_3: {
    target: 3,
    category: 'prestige',
    rewardType: 'gems',
    rewardAmount: 20,
  },

  // -------------------------------------------------------------------------
  // Equipment
  // -------------------------------------------------------------------------
  first_legendary: {
    target: 1,
    category: 'equipment',
    rewardType: 'gold',
    rewardAmount: 1000,
  },
  full_set: {
    target: 1,
    category: 'equipment',
    rewardType: 'gems',
    rewardAmount: 3,
  },
  upgrade_10: {
    target: 1,
    category: 'equipment',
    rewardType: 'gems',
    rewardAmount: 5,
  },
  equip_all_slots: {
    target: 1,
    category: 'equipment',
    rewardType: 'gold',
    rewardAmount: 500,
  },

  // -------------------------------------------------------------------------
  // Dungeon
  // -------------------------------------------------------------------------
  dungeon_first_clear: {
    target: 1,
    category: 'dungeon',
    rewardType: 'gold',
    rewardAmount: 300,
  },
  dungeon_all_easy: {
    target: 1,
    category: 'dungeon',
    rewardType: 'gems',
    rewardAmount: 2,
  },
  dungeon_all_hard: {
    target: 1,
    category: 'dungeon',
    rewardType: 'gems',
    rewardAmount: 10,
  },
  boss_no_damage: {
    target: 1,
    category: 'dungeon',
    rewardType: 'gems',
    rewardAmount: 5,
  },

  // -------------------------------------------------------------------------
  // Economy
  // -------------------------------------------------------------------------
  earn_gold_10k: {
    target: 10000,
    category: 'economy',
    rewardType: 'gold',
    rewardAmount: 500,
  },
  earn_gold_100k: {
    target: 100000,
    category: 'economy',
    rewardType: 'gems',
    rewardAmount: 3,
  },
  spend_gold_50k: {
    target: 50000,
    category: 'economy',
    rewardType: 'gems',
    rewardAmount: 2,
  },

  // -------------------------------------------------------------------------
  // Minigame
  // -------------------------------------------------------------------------
  shell_game_win_10: {
    target: 10,
    category: 'minigame',
    rewardType: 'gold',
    rewardAmount: 1000,
  },

  // -------------------------------------------------------------------------
  // Ranking
  // -------------------------------------------------------------------------
  rank_silver: {
    target: 1200,
    category: 'ranking',
    rewardType: 'gems',
    rewardAmount: 1,
  },
  rank_gold: {
    target: 1500,
    category: 'ranking',
    rewardType: 'gems',
    rewardAmount: 3,
  },
  rank_diamond: {
    target: 1800,
    category: 'ranking',
    rewardType: 'gems',
    rewardAmount: 10,
  },
  rank_grandmaster: {
    target: 2200,
    category: 'ranking',
    rewardType: 'gems',
    rewardAmount: 25,
  },

  // -------------------------------------------------------------------------
  // Daily / Streak
  // -------------------------------------------------------------------------
  login_7_days: {
    target: 7,
    category: 'daily',
    rewardType: 'gems',
    rewardAmount: 2,
  },
  login_30_days: {
    target: 30,
    category: 'daily',
    rewardType: 'gems',
    rewardAmount: 10,
  },
  daily_quest_100: {
    target: 100,
    category: 'daily',
    rewardType: 'gems',
    rewardAmount: 5,
  },
} as const;

/**
 * All achievement keys as a typed array.
 */
export const ACHIEVEMENT_KEYS = Object.keys(ACHIEVEMENT_CATALOG) as (keyof typeof ACHIEVEMENT_CATALOG)[];

/**
 * Get all achievements for a given category.
 */
export function getAchievementsByCategory(category: string): [string, AchievementDef][] {
  return Object.entries(ACHIEVEMENT_CATALOG).filter(
    ([, def]) => def.category === category,
  );
}

/**
 * Load achievement catalog from DB (AchievementDefinition table).
 * Falls back to hardcoded ACHIEVEMENT_CATALOG if DB is empty or unavailable.
 */
export async function getAchievementCatalog(): Promise<Record<string, AchievementDef>> {
  try {
    const { prisma } = await import('@/lib/prisma');
    const defs = await (prisma as any).achievementDefinition.findMany({
      where: { active: true },
    });
    if (defs.length > 0) {
      const catalog: Record<string, AchievementDef> = {};
      for (const def of defs) {
        catalog[def.key] = {
          target: def.target,
          category: def.category,
          rewardType: def.rewardType,
          rewardAmount: def.rewardAmount,
          rewardId: def.rewardId ?? undefined,
        };
      }
      return catalog;
    }
  } catch {
    // DB not available or model not yet migrated — fall back
  }
  return { ...ACHIEVEMENT_CATALOG };
}
