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
  FREE_PVP_PER_DAY: 5,
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
  PVP_WIN_BASE: 200,
  PVP_LOSS_BASE: 70,
  TRAINING_WIN: 50,
  TRAINING_LOSS: 20,
  REVENGE_MULTIPLIER: 1.5,
} as const;

// --- XP rewards ---
export const XP_REWARDS = {
  PVP_WIN_XP: 150,
  PVP_LOSS_XP: 50,
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
  { type: 'gems', amount: 25 },                                           // Day 7
] as const;

// --- In-App Purchase products ---
export interface IapProduct {
  gems: number;
  gold: number;
  premium: boolean; // grants permanent premium
  monthlyGemCard: boolean; // activates daily gem card (50 instant + 10/day x30)
  price: number;
}

export const IAP_PRODUCTS: Record<string, IapProduct> = {
  // Gem packs
  gems_small:  { gems: 100,  gold: 0, premium: false, monthlyGemCard: false, price: 0.99 },
  gems_medium: { gems: 550,  gold: 0, premium: false, monthlyGemCard: false, price: 4.99 },
  gems_large:  { gems: 1200, gold: 0, premium: false, monthlyGemCard: false, price: 9.99 },
  gems_huge:   { gems: 2500, gold: 0, premium: false, monthlyGemCard: false, price: 19.99 },
  gems_mega:   { gems: 6500, gold: 0, premium: false, monthlyGemCard: false, price: 49.99 },
  // Gold packs
  gold_500:    { gems: 0, gold: 500,   premium: false, monthlyGemCard: false, price: 0.99 },
  gold_1200:   { gems: 0, gold: 1200,  premium: false, monthlyGemCard: false, price: 1.99 },
  gold_3500:   { gems: 0, gold: 3500,  premium: false, monthlyGemCard: false, price: 4.99 },
  gold_8000:   { gems: 0, gold: 8000,  premium: false, monthlyGemCard: false, price: 9.99 },
  gold_20000:  { gems: 0, gold: 20000, premium: false, monthlyGemCard: false, price: 19.99 },
  // Monthly Gem Card (50 instant gems + server creates daily_gem_card entry)
  monthly_gem_card: { gems: 50, gold: 0, premium: false, monthlyGemCard: true, price: 4.99 },
  // Starter Bundle — one-time purchase for new players (best value, creates habit)
  starter_bundle: { gems: 200, gold: 3000, premium: false, monthlyGemCard: false, price: 2.99 },
  // Premium — one-time forever unlock
  premium_forever: { gems: 0, gold: 0, premium: true, monthlyGemCard: false, price: 9.99 },
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

// --- PvP Rank Thresholds ---
export const PVP_RANKS = {
  BRONZE: 0,
  SILVER: 1200,
  GOLD: 1500,
  PLATINUM: 1800,
  DIAMOND: 2100,
  GRANDMASTER: 2400,
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
  // CHA intimidation: reduces enemy damage by 0.25% per CHA point (max 25%)
  CHA_INTIMIDATION_PER_POINT: 0.25,
  CHA_INTIMIDATION_CAP: 25,
} as const;

// --- Battle Fatigue (anti-stall mechanic) ---
// After FATIGUE_START_TURN, both fighters deal +FATIGUE_PERCENT_PER_TURN% more damage per turn
export const BATTLE_FATIGUE = {
  FATIGUE_START_TURN: 10,
  FATIGUE_PERCENT_PER_TURN: 10, // +10% per turn after start
} as const;

// --- Stance Zones ---
export type BodyZone = 'head' | 'chest' | 'legs';

export const STANCE_ZONES = {
  VALID_ZONES: ['head', 'chest', 'legs'] as readonly BodyZone[],

  // Intrinsic bonuses for choosing an attack zone
  ATTACK_ZONE: {
    head:  { offense: 10, crit: 5 },   // aggressive, high crit
    chest: { offense: 5,  crit: 0 },   // balanced
    legs:  { offense: 0,  crit: -3 },  // conservative
  } as const satisfies Record<BodyZone, { offense: number; crit: number }>,

  // Intrinsic bonuses for choosing a defense zone
  DEFENSE_ZONE: {
    head:  { defense: 0,  dodge: 8 },  // evasive
    chest: { defense: 10, dodge: 0 },  // tanky
    legs:  { defense: 5,  dodge: 3 },  // balanced
  } as const satisfies Record<BodyZone, { defense: number; dodge: number }>,

  // Zone matching bonuses
  MISMATCH_OFFENSE_BONUS: 5,   // attacker bonus when attack zone != defender's defense zone
  MATCH_DEFENSE_BONUS: 15,     // defender bonus when correctly predicting attack zone
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

/**
 * CHA gold bonus with diminishing returns:
 * - CHA 0-30:  +2.5% per point (max +75%)
 * - CHA 31-60: +1.0% per point (max +105% cumulative)
 * - CHA 61+:   +0.5% per point (hard cap +125%)
 */
export function chaGoldBonus(baseGold: number, cha: number): number {
  let bonus = 0;
  if (cha <= 30) {
    bonus = cha * 0.025;
  } else if (cha <= 60) {
    bonus = 30 * 0.025 + (cha - 30) * 0.01;
  } else {
    bonus = 30 * 0.025 + 30 * 0.01 + (cha - 60) * 0.005;
  }
  // Hard cap at 125%
  bonus = Math.min(bonus, 1.25);
  return Math.floor(baseGold * (1 + bonus));
}

// --- Loss Streak Gold Protection ---
// After consecutive losses, next win gives bonus gold to reduce frustration
// 3 losses: +30%, 5 losses: +50%, 7+ losses: +80%
export const LOSS_STREAK_BONUSES: readonly number[] = [
  0, 0, 0, 0.3, 0.3, 0.5, 0.5, 0.8, 0.8, 0.8, 0.8,
] as const;

/** Get the gold bonus multiplier for loss streak recovery (applied on next WIN). */
export function lossStreakGoldMultiplier(lossStreak: number): number {
  if (lossStreak < 0) return 0;
  const idx = Math.min(lossStreak, LOSS_STREAK_BONUSES.length - 1);
  return LOSS_STREAK_BONUSES[idx];
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

// --- Equipment Repair Costs (gold sink, scales with item level and rarity) ---
export const REPAIR_COSTS = {
  BASE_COST: 50,                // Base gold per repair
  PER_LEVEL: 10,                // +10 gold per item level
  RARITY_MULTIPLIERS: {         // Multiplier by rarity
    common: 1.0,
    uncommon: 1.5,
    rare: 2.0,
    epic: 3.0,
    legendary: 5.0,
  },
} as const;

/** Calculate repair cost for a single item. */
export function repairCost(itemLevel: number, rarity: string): number {
  const mult = (REPAIR_COSTS.RARITY_MULTIPLIERS as Record<string, number>)[rarity] ?? 1.0;
  return Math.floor((REPAIR_COSTS.BASE_COST + itemLevel * REPAIR_COSTS.PER_LEVEL) * mult);
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
  RESPEC_GOLD_COST: 5000, // Alternative gold cost for respec (gold sink)
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
