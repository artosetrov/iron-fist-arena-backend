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
  // PVP  (tracked in pvp/fight, pvp/resolve, pvp/revenge)
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
  revenge_first: {
    target: 1,
    category: 'pvp',
    rewardType: 'gold',
    rewardAmount: 300,
  },
  revenge_wins_10: {
    target: 10,
    category: 'pvp',
    rewardType: 'gems',
    rewardAmount: 2,
  },

  // -------------------------------------------------------------------------
  // Progression  (tracked in applyLevelUp + prestige route)
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
  first_prestige: {
    target: 1,
    category: 'progression',
    rewardType: 'gems',
    rewardAmount: 10,
  },
  prestige_3: {
    target: 3,
    category: 'progression',
    rewardType: 'gems',
    rewardAmount: 20,
  },

  // -------------------------------------------------------------------------
  // Ranking  (tracked after ELO update in pvp/fight + pvp/resolve)
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
