// =============================================================================
// balance.ts — Game balance constants and formulas
// =============================================================================

// --- Stamina ---
export const STAMINA = {
  MAX: 120,
  REGEN_RATE: 1, // 1 point per REGEN_INTERVAL_MINUTES
  REGEN_INTERVAL_MINUTES: 8,
  PVP_COST: 10,
  DUNGEON_EASY: 15,
  DUNGEON_NORMAL: 20,
  DUNGEON_HARD: 25,
  BOSS: 40,
  TRAINING: 5,
  FREE_PVP_PER_DAY: 3,
} as const;

// --- HP Regen ---
export const HP_REGEN = {
  REGEN_RATE: 1,              // 1% of maxHp per interval
  REGEN_INTERVAL_MINUTES: 5,  // every 5 minutes
} as const;

// --- XP ---
/** XP required to reach the given level (cumulative threshold). */
export function xpForLevel(level: number): number {
  return 100 * level + 20 * level * level;
}

// --- Gold rewards ---
export const GOLD_REWARDS = {
  PVP_WIN_BASE: 150,
  PVP_LOSS_BASE: 50,
  TRAINING_WIN: 50,
  TRAINING_LOSS: 20,
  REVENGE_MULTIPLIER: 1.5,
} as const;

// --- XP rewards ---
export const XP_REWARDS = {
  PVP_WIN_XP: 120,
  PVP_LOSS_XP: 40,
  TRAINING_WIN_XP: 60,
  TRAINING_LOSS_XP: 20,
} as const;

// --- First win of the day bonus ---
export const FIRST_WIN_BONUS = {
  GOLD_MULT: 2,
  XP_MULT: 2,
} as const;

// --- Equipment upgrade success chances (index 0 = +1, index 9 = +10) ---
export const UPGRADE_CHANCES: readonly number[] = [
  100, // +1
  100, // +2
  100, // +3
  100, // +4
  100, // +5
  80,  // +6
  60,  // +7
  40,  // +8
  25,  // +9
  15,  // +10
] as const;

// --- Daily login rewards (days 1-7, repeating weekly) ---
export interface DailyLoginRewardDef {
  type: string;
  amount: number;
  itemId?: string;
}

export const DAILY_LOGIN_REWARDS: readonly DailyLoginRewardDef[] = [
  { type: 'gold', amount: 200 },                                          // Day 1
  { type: 'consumable', amount: 1, itemId: 'stamina_potion_small' },      // Day 2
  { type: 'gold', amount: 500 },                                          // Day 3
  { type: 'consumable', amount: 2, itemId: 'stamina_potion_small' },      // Day 4
  { type: 'gold', amount: 1000 },                                         // Day 5
  { type: 'consumable', amount: 1, itemId: 'stamina_potion_large' },      // Day 6
  { type: 'gems', amount: 5 },                                            // Day 7
] as const;

// --- In-App Purchase products ---
export interface IapProduct {
  gems: number;
  price: number;
}

export const IAP_PRODUCTS: Record<string, IapProduct> = {
  gems_small: { gems: 100, price: 0.99 },
  gems_medium: { gems: 550, price: 4.99 },
  gems_large: { gems: 1200, price: 9.99 },
  gems_huge: { gems: 2500, price: 19.99 },
  gems_mega: { gems: 6500, price: 49.99 },
} as const;

// --- Battle Pass ---
export const BATTLE_PASS = {
  BP_XP_PER_PVP: 20,
  BP_XP_PER_DUNGEON_FLOOR: 30,
  BP_XP_PER_QUEST: 50,
  BP_XP_PER_ACHIEVEMENT: 100,
} as const;

/** XP required to reach a given Battle Pass level. */
export function bpXpForLevel(level: number): number {
  return 100 + level * 50;
}

// --- ELO ---
export const ELO = {
  K_CALIBRATION: 48,
  K_DEFAULT: 32,
  CALIBRATION_GAMES: 10,
  MIN_RATING: 0,
} as const;

// --- Combat ---
export const COMBAT = {
  MAX_TURNS: 15,
  MIN_DAMAGE: 1,
  CRIT_MULTIPLIER: 1.5,
  MAX_CRIT_CHANCE: 50,
  MAX_DODGE_CHANCE: 30,
  ROGUE_DODGE_BONUS: 3,         // rogues get +3% dodge (was 5)
  TANK_DAMAGE_REDUCTION: 0.85,  // tanks take 15% less damage
  DAMAGE_VARIANCE: 0.10,        // ±10% damage variance
  POISON_ARMOR_PENETRATION: 0.3, // poison ignores 30% of armor (was 50%)
  // Crit/dodge formula coefficients (rebalanced to nerf AGI dominance)
  CRIT_PER_LUK: 0.7,            // was 0.5 — LUK is now the primary crit stat
  CRIT_PER_AGI: 0.15,           // was 0.3 — AGI crit contribution halved
  DODGE_PER_AGI: 0.2,           // was 0.3 — dodge slightly nerfed
  DODGE_PER_LUK: 0.1,           // NEW — LUK adds minor dodge
  // CHA intimidation: reduces enemy damage by 0.15% per CHA point (max 15%)
  CHA_INTIMIDATION_PER_POINT: 0.15,
  CHA_INTIMIDATION_CAP: 15,
} as const;

// --- Prestige ---
export const PRESTIGE = {
  MAX_LEVEL: 50,
  STAT_BONUS_PER_PRESTIGE: 0.05, // +5% all stats per prestige level
  STAT_POINTS_PER_LEVEL: 3,
} as const;

// --- Loot drop chances by source ---
export const DROP_CHANCES: Record<string, number> = {
  pvp: 0.15,
  training: 0.05,
  dungeon_easy: 0.20,
  dungeon_normal: 0.30,
  dungeon_hard: 0.40,
  boss: 0.75,
} as const;

/** CHA gold bonus: +1% per CHA point (was 0.5%) */
export function chaGoldBonus(baseGold: number, cha: number): number {
  return Math.floor(baseGold * (1 + cha * 0.01));
}

// --- Win Streak Gold Bonuses ---
// Index = streak length, value = bonus multiplier (0 = no bonus)
// 3-win: +20%, 5-win: +50%, 8+win: +100%
export const WIN_STREAK_BONUSES: readonly number[] = [
  0, 0, 0, 0.2, 0.2, 0.5, 0.5, 0.5, 1.0, 1.0, 1.0,
] as const;

/** Get the gold bonus multiplier for the current win streak. */
export function streakGoldMultiplier(winStreak: number): number {
  if (winStreak < 0) return 0;
  const idx = Math.min(winStreak, WIN_STREAK_BONUSES.length - 1);
  return WIN_STREAK_BONUSES[idx];
}

/** Scale PvP gold/XP reward based on character level (higher levels earn slightly more). */
export function levelScaledReward(baseReward: number, level: number): number {
  // +2% per level above 1 (level 50 gets +98% = ~2x rewards)
  return Math.floor(baseReward * (1 + (level - 1) * 0.02));
}

// --- Active Skills ---
export const SKILLS = {
  MAX_EQUIPPED_SLOTS: 4,
  UPGRADE_GOLD_BASE: 500,
  UPGRADE_GOLD_PER_RANK: 500,
  LEARN_GOLD_COST: 200,
} as const;

// --- Passive Tree ---
export const PASSIVES = {
  POINTS_PER_LEVEL: 1,
  MAX_PASSIVE_POINTS: 50,
  RESPEC_GEM_COST: 50,
} as const;

// --- Gem costs ---
export const GEM_COSTS = {
  STAMINA_REFILL: 30,
  EXTRA_PVP_COMBAT: 50,
  BATTLE_PASS_PREMIUM: 500,
  GOLD_MINE_BUY_SLOT: 50,
  GOLD_MINE_BOOST: 10,
} as const;

// --- Inventory ---
export const INVENTORY = {
  MAX_SLOTS: 100,
  BASE_SLOTS: 28,
  EXPAND_AMOUNT: 10,
  EXPAND_COST_GOLD: 5000,
  MAX_EXPANSIONS: 3, // 28 + 3*10 = 58 max
} as const;

// --- Extra PvP combat ---
export const EXTRA_PVP = {
  STAMINA_GRANTED: 5,
} as const;

// --- Rarity distribution (must sum to 100) ---
export const RARITY_DISTRIBUTION = {
  common: 50,
  uncommon: 30,
  rare: 15,
  epic: 4,
  legendary: 1,
} as const;
