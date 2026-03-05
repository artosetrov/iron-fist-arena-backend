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
    rewardAmount: 200,
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
    rewardAmount: 25,
  },
  pvp_wins_100: {
    target: 100,
    category: 'pvp',
    rewardType: 'gems',
    rewardAmount: 50,
  },
  pvp_wins_500: {
    target: 500,
    category: 'pvp',
    rewardType: 'gems',
    rewardAmount: 200,
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
    rewardAmount: 50,
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
    rewardAmount: 30,
  },

  // -------------------------------------------------------------------------
  // Level / Progression
  // -------------------------------------------------------------------------
  reach_level_10: {
    target: 10,
    category: 'progression',
    rewardType: 'gold',
    rewardAmount: 1000,
  },
  reach_level_25: {
    target: 25,
    category: 'progression',
    rewardType: 'gems',
    rewardAmount: 50,
  },
  reach_level_50: {
    target: 50,
    category: 'progression',
    rewardType: 'gems',
    rewardAmount: 100,
  },

  // -------------------------------------------------------------------------
  // Prestige
  // -------------------------------------------------------------------------
  first_prestige: {
    target: 1,
    category: 'prestige',
    rewardType: 'gems',
    rewardAmount: 100,
  },
  prestige_3: {
    target: 3,
    category: 'prestige',
    rewardType: 'gems',
    rewardAmount: 300,
  },

  // -------------------------------------------------------------------------
  // Equipment
  // -------------------------------------------------------------------------
  first_legendary: {
    target: 1,
    category: 'equipment',
    rewardType: 'gold',
    rewardAmount: 2000,
  },
  full_set: {
    target: 1,
    category: 'equipment',
    rewardType: 'gems',
    rewardAmount: 50,
  },
  upgrade_10: {
    target: 1,
    category: 'equipment',
    rewardType: 'gems',
    rewardAmount: 100,
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
    rewardAmount: 500,
  },
  dungeon_all_easy: {
    target: 1,
    category: 'dungeon',
    rewardType: 'gold',
    rewardAmount: 1000,
  },
  dungeon_all_hard: {
    target: 1,
    category: 'dungeon',
    rewardType: 'gems',
    rewardAmount: 100,
  },
  boss_no_damage: {
    target: 1,
    category: 'dungeon',
    rewardType: 'gems',
    rewardAmount: 75,
  },

  // -------------------------------------------------------------------------
  // Economy
  // -------------------------------------------------------------------------
  earn_gold_10k: {
    target: 10000,
    category: 'economy',
    rewardType: 'gold',
    rewardAmount: 1000,
  },
  earn_gold_100k: {
    target: 100000,
    category: 'economy',
    rewardType: 'gems',
    rewardAmount: 50,
  },
  spend_gold_50k: {
    target: 50000,
    category: 'economy',
    rewardType: 'gold',
    rewardAmount: 2000,
  },

  // -------------------------------------------------------------------------
  // Minigame
  // -------------------------------------------------------------------------
  shell_game_win_10: {
    target: 10,
    category: 'minigame',
    rewardType: 'gold',
    rewardAmount: 500,
  },

  // -------------------------------------------------------------------------
  // Ranking
  // -------------------------------------------------------------------------
  rank_silver: {
    target: 1200,
    category: 'ranking',
    rewardType: 'gold',
    rewardAmount: 500,
  },
  rank_gold: {
    target: 1500,
    category: 'ranking',
    rewardType: 'gems',
    rewardAmount: 25,
  },
  rank_diamond: {
    target: 1800,
    category: 'ranking',
    rewardType: 'gems',
    rewardAmount: 75,
  },
  rank_grandmaster: {
    target: 2200,
    category: 'ranking',
    rewardType: 'gems',
    rewardAmount: 200,
  },

  // -------------------------------------------------------------------------
  // Daily / Streak
  // -------------------------------------------------------------------------
  login_7_days: {
    target: 7,
    category: 'daily',
    rewardType: 'gems',
    rewardAmount: 20,
  },
  login_30_days: {
    target: 30,
    category: 'daily',
    rewardType: 'gems',
    rewardAmount: 100,
  },
  daily_quest_100: {
    target: 100,
    category: 'daily',
    rewardType: 'gems',
    rewardAmount: 75,
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
