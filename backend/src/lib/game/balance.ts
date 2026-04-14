// =============================================================================
// balance.ts — Game balance constants and formulas
// =============================================================================

// --- Stamina ---
export const STAMINA = {
  // Economy v3 (2026-04-14): raised 120 → 180 so two daily check-ins fully use
  // overnight regen (24h 0→max at 1 point / 8 min). See ECONOMY_RULES.md R8.
  MAX: 180,
  REGEN_RATE: 1, // 1 point per REGEN_INTERVAL_MINUTES
  REGEN_INTERVAL_MINUTES: 8,
  PVP_COST: 10,
  DUNGEON_EASY: 15,
  DUNGEON_NORMAL: 20,
  DUNGEON_HARD: 25,
  BOSS: 40,
  TRAINING: 5,
  FREE_PVP_PER_DAY: 3,       // was 5 — 3 free = hook, then stamina/gems
} as const;

// --- Stamina Refill Diminishing Returns (W3.D4) ---
//
// Industry precedent: Clash Royale gem-for-gold, LoL boosts, Genshin Fragile Resin.
// Rule: the Nth refill of the day costs more gems than the previous one so whales
// cannot buy unlimited energy at a flat rate. Free-to-play users are unaffected
// because the base price equals STAMINA_REFILL in GEM_COSTS.
//
// Cost formula for refill index `n` (0-indexed):
//   cost_n = base_cost × REFILL_COST_MULTIPLIERS[min(n, cap)]
//
// A hard cap prevents a 5th+ refill on the same day — there is no price that
// makes a 20-refill day healthy for the economy.
export const STAMINA_REFILL_DR = {
  /** Multiplier applied to the base gem cost per refill index on that day. */
  // Economy v3 (2026-04-13): raised multipliers. With base cost 50 (was 30) the sequence is
  // 50 / 80 / 140 / 240 — whales still can refill, but the 4th refill costs ~5× the 1st.
  // See ECONOMY_RULES.md R8.refill.
  COST_MULTIPLIERS: [1, 1.6, 2.8, 4.8] as const, // refill 1 → 1×, 2 → 1.6×, 3 → 2.8×, 4 → 4.8×
  /** Maximum number of refills allowed per day. */
  DAILY_CAP: 4,
} as const;

// --- Training / Dungeon XP Diminishing Returns (W3.D4) ---
//
// Industry precedent: WoW rested XP (soft), LoL FWoTD (first win of the day),
// Raid: Shadow Legends Dungeon Energy, Genshin daily commissions.
// Rule: first N dungeon clears/day give full XP. The next M are at 50%. Beyond
// that, XP floors at 10% (never zero — never brick the player if they want to
// keep playing, just remove the farming incentive).
//
// The multiplier is chosen by the NUMBER of dungeon clears taken today, not by
// total XP earned, so that long boss fights are not disproportionately nerfed.
export const TRAINING_XP_DR = {
  /** Clears at 100% XP multiplier (per day). */
  FULL_XP_CLEARS: 6,
  /** Additional clears at 50% XP multiplier. */
  HALF_XP_CLEARS: 6,
  /** Floor multiplier for all clears past the half-xp window. */
  FLOOR_MULTIPLIER: 0.1,
} as const;

/**
 * Multiplier to apply to a dungeon XP reward based on how many clears
 * the character has already done today.
 *
 * @param clearsToday Number of dungeon clears already counted today (pre-increment).
 */
export function trainingXpMultiplier(clearsToday: number): number {
  if (clearsToday < 0) return 1;
  if (clearsToday < TRAINING_XP_DR.FULL_XP_CLEARS) return 1;
  if (clearsToday < TRAINING_XP_DR.FULL_XP_CLEARS + TRAINING_XP_DR.HALF_XP_CLEARS) return 0.5;
  return TRAINING_XP_DR.FLOOR_MULTIPLIER;
}

/**
 * Gem cost for the Nth stamina refill of the day. Returns null if the daily
 * refill cap has been hit.
 *
 * @param baseCost       The base gem cost from GEM_COSTS.STAMINA_REFILL.
 * @param refillsToday   Number of refills already used today (pre-increment).
 */
export function staminaRefillGemCost(baseCost: number, refillsToday: number): number | null {
  if (refillsToday < 0) refillsToday = 0;
  if (refillsToday >= STAMINA_REFILL_DR.DAILY_CAP) return null;
  const mult = STAMINA_REFILL_DR.COST_MULTIPLIERS[refillsToday]
    ?? STAMINA_REFILL_DR.COST_MULTIPLIERS[STAMINA_REFILL_DR.COST_MULTIPLIERS.length - 1];
  return Math.ceil(baseCost * mult);
}

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

// --- Gold rewards (Economy v2 — reduced to fix gold hyperinflation) ---
export const GOLD_REWARDS = {
  PVP_WIN_BASE: 150,         // was 200 — sink ratio was 10%, target 55-65%
  PVP_LOSS_BASE: 50,         // was 70 — loss shouldn't feel comfortable
  TRAINING_WIN: 30,           // was 50 — training = practice, not income
  TRAINING_LOSS: 10,          // was 20
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
// Economy v3 (2026-04-13): bumped the +9 / +10 floor (25%/15% → 30%/20%) and
// changed the failure mode at +9 / +10 to "downgrade by 1" instead of "stays".
// Why: previous setup turned high-end upgrading into a flat gold tax that whales
// could brute-force. Downgrade-on-fail makes the choice meaningful — Protection
// Scrolls become a real call. Higher base success keeps the median grinder honest.
// See ECONOMY_RULES.md R7.3.
export const UPGRADE_CHANCES: readonly number[] = [
  100, // +1
  100, // +2
  100, // +3
  100, // +4
  100, // +5
  80,  // +6
  60,  // +7
  40,  // +8
  30,  // +9  (v3: was 25)
  20,  // +10 (v3: was 15)
] as const;

/** Plus-levels at which a failed upgrade attempt downgrades the item by 1 (unless protected). */
export const UPGRADE_DOWNGRADE_LEVELS: readonly number[] = [9, 10] as const;

// --- Daily login rewards (days 1-7, repeating weekly) ---
//
// W1.D3 SSoT contract (2026-04-10): server is the source of truth for BOTH
// the reward mechanics (type/amount/itemId) AND the display (displayName,
// displayIcon). Clients must render `displayName` and map `displayIcon` to
// their local asset catalog; they must NOT invent labels client-side.
//
// `displayIcon` values are asset keys understood by both the iOS xcassets
// catalog and the admin panel. Keep the set below small and stable.
export interface DailyLoginRewardDef {
  type: 'gold' | 'gems' | 'consumable';
  amount: number;
  itemId?: string;
  /** Human label shown in the UI, e.g. "150 Gold" or "1 S. Potion". */
  displayName: string;
  /** Asset key for the UI icon (see xcassets / admin panel preview map). */
  displayIcon:
    | 'icon-gold'
    | 'icon-gems'
    | 'icon-stamina-small'
    | 'icon-stamina-large'
    | 'icon-hp-potion-small'
    | 'icon-hp-potion-large';
}

// --- Daily login rewards (Economy v2 — reduced gold days to prevent passive > active income) ---
export const DAILY_LOGIN_REWARDS: readonly DailyLoginRewardDef[] = [
  { type: 'gold',       amount: 150, displayName: '150 Gold',    displayIcon: 'icon-gold' },                                                     // Day 1 (was 200)
  { type: 'consumable', amount: 1,   displayName: '1 S. Potion', displayIcon: 'icon-stamina-small', itemId: 'stamina_potion_small' },             // Day 2
  { type: 'gold',       amount: 300, displayName: '300 Gold',    displayIcon: 'icon-gold' },                                                     // Day 3 (was 500)
  { type: 'consumable', amount: 2,   displayName: '2 S. Potions', displayIcon: 'icon-stamina-small', itemId: 'stamina_potion_small' },            // Day 4
  { type: 'gold',       amount: 500, displayName: '500 Gold',    displayIcon: 'icon-gold' },                                                     // Day 5 (was 1000)
  { type: 'consumable', amount: 1,   displayName: '1 L. Potion', displayIcon: 'icon-stamina-large', itemId: 'stamina_potion_large' },             // Day 6
  { type: 'gems',       amount: 25,  displayName: '25 Gems',     displayIcon: 'icon-gems' },                                                     // Day 7
] as const;

// --- In-App Purchase products ---
// Economy v3 (2026-04-13): added `enabled` flag for lifecycle management.
// `enabled: false` = no new purchases, but server still honors existing owners
// (e.g., premium_forever entitlement remains valid for users who bought before disable).
// Rules: see docs/06_game_systems/ECONOMY_RULES.md R10, R11.
/**
 * Bundle item grant — a count of a consumable to drop into the user's
 * active (most-recent) character's ConsumableInventory on purchase.
 * Used by Adventurer's Bundles to deliver Protection Scrolls / Legendary
 * Shards alongside currencies. Enum values must exist in ConsumableType.
 */
export interface IapItemGrant {
  type: 'protection_scroll' | 'legendary_shard';
  quantity: number;
}

export interface IapProduct {
  gems: number;
  gold: number;
  premium: boolean; // grants permanent premium (legacy: premium_forever). For subscriptions, use `subscription` instead.
  monthlyGemCard: boolean; // activates daily gem card (50 instant + 10/day x30)
  price: number;
  enabled?: boolean; // default: true. If false, /api/iap/products hides it and /verify-receipt rejects new purchases.
  items?: IapItemGrant[]; // optional consumable grants for bundle SKUs
  // Premium Pass Phase 2 (2026-04-14): auto-renewable subscription marker.
  // When set, /verify-receipt upserts a PremiumSubscription row (not user.premiumUntil).
  // See docs/06_game_systems/PREMIUM_PASS_MIGRATION.md.
  subscription?: {
    durationDays: 30; // only 30-day SKU shipped in Phase 2
    monthlyGems: number; // gems credited per renewal period
  };
}

export const IAP_PRODUCTS: Record<string, IapProduct> = {
  // Gem packs (core premium currency — always enabled)
  gems_small:  { gems: 100,  gold: 0, premium: false, monthlyGemCard: false, price: 0.99 },
  gems_medium: { gems: 550,  gold: 0, premium: false, monthlyGemCard: false, price: 4.99 },
  gems_large:  { gems: 1200, gold: 0, premium: false, monthlyGemCard: false, price: 9.99 },
  gems_huge:   { gems: 2500, gold: 0, premium: false, monthlyGemCard: false, price: 19.99 },
  gems_mega:   { gems: 6500, gold: 0, premium: false, monthlyGemCard: false, price: 49.99 },
  // Flat gold packs — DISABLED in Economy v3. Selling gold directly shortcuts the
  // soft-currency loop and erodes the gem→gold shop. Replaced by Adventurer's Bundles.
  // See ECONOMY_RULES.md R10.2, R15.
  gold_500:    { gems: 0, gold: 500,   premium: false, monthlyGemCard: false, price: 0.99,  enabled: false },
  gold_1200:   { gems: 0, gold: 1200,  premium: false, monthlyGemCard: false, price: 1.99,  enabled: false },
  gold_3500:   { gems: 0, gold: 3500,  premium: false, monthlyGemCard: false, price: 4.99,  enabled: false },
  gold_8000:   { gems: 0, gold: 8000,  premium: false, monthlyGemCard: false, price: 9.99,  enabled: false },
  gold_20000:  { gems: 0, gold: 20000, premium: false, monthlyGemCard: false, price: 19.99, enabled: false },
  // Adventurer's Bundles — v3 replacement for flat gold packs. Mixed gems+gold + consumables.
  // Extras route to the user's most-recently-updated character. See ECONOMY_RULES.md R10.3.
  //   I   — 1× Protection Scroll (rationale: first-time +9 attempts).
  //   II  — 3× Protection Scroll + 1× Legendary Shard (mid-game +10 push).
  //   III — 5× Protection Scroll + 5× Legendary Shard (whale bundle, crafting-grade).
  adventurer_bundle_I:   { gems: 600,  gold: 3000,  premium: false, monthlyGemCard: false, price: 4.99,
    items: [{ type: 'protection_scroll', quantity: 1 }] },
  adventurer_bundle_II:  { gems: 1400, gold: 10000, premium: false, monthlyGemCard: false, price: 9.99,
    items: [{ type: 'protection_scroll', quantity: 3 }, { type: 'legendary_shard', quantity: 1 }] },
  adventurer_bundle_III: { gems: 3200, gold: 20000, premium: false, monthlyGemCard: false, price: 19.99,
    items: [{ type: 'protection_scroll', quantity: 5 }, { type: 'legendary_shard', quantity: 5 }] },
  // Monthly Gem Card (50 instant gems + server creates daily_gem_card entry)
  monthly_gem_card: { gems: 50, gold: 0, premium: false, monthlyGemCard: true, price: 4.99 },
  // Starter Bundle — one-time purchase for new players (best value, creates habit)
  starter_bundle: { gems: 200, gold: 3000, premium: false, monthlyGemCard: false, price: 2.99 },
  // Premium Forever — DISABLED for new purchases in Economy v3.
  // Existing owners keep entitlement (server checks `premiumUntil`). New monetization path:
  // Premium Pass (30-day subscription) — see docs/06_game_systems/PREMIUM_PASS_MIGRATION.md.
  premium_forever: { gems: 0, gold: 0, premium: true, monthlyGemCard: false, price: 9.99, enabled: false },
  // Premium Pass — 30-day auto-renewable subscription. Economy v3 successor to premium_forever.
  // Grants premium entitlement for the subscription window + 300 gems per renewal.
  // Verified by Apple Server Notifications v2 webhook; tracked in premium_subscriptions table.
  // Field mapping: price = introductory/list price; actual charge is Apple's renewal amount.
  // See docs/06_game_systems/PREMIUM_PASS_MIGRATION.md.
  premium_pass_monthly: {
    gems: 0, gold: 0, premium: false, monthlyGemCard: false, price: 4.99,
    subscription: { durationDays: 30, monthlyGems: 300 },
  },
} as const;

// --- Battle Pass ---
export const BATTLE_PASS = {
  BP_XP_PER_PVP: 20,
  BP_XP_PER_DUNGEON_FLOOR: 30,
  BP_XP_PER_QUEST: 50,
  BP_XP_PER_ACHIEVEMENT: 100,
} as const;

// --- Battle Pass Weekly Challenges (W3.D5 — BAL-06) ---
//
// Every character gets 5 rotating challenge slots per ISO week. Pool is
// selected deterministically via mulberry32(seedFromWeek) — no cron job, no
// DB writes until the player actually scores progress.
//
// Design intent (industry reference: Fortnite, LoL, Valorant):
//   - 5 challenges keeps the list skimmable on mobile (< 1 screen)
//   - Each completion awards 150 BP XP (≈ 3x a daily quest) so clearing all
//     five = 750 BP XP, i.e. ~1.5 BP levels → meaningful weekly pull
//   - Goals scale modestly vs dailies but are still achievable in one evening
//     of play if the pool slots overlap with the player's session pattern
//   - No rerolls in v1 — the rotation IS the reroll
//
// Extending: add a new tuple to WEEKLY_CHALLENGE_POOL, bump BP_WEEKLY_XP if
// rebalancing. Do NOT change pool length — it's load-bearing for determinism
// across historical weeks (claimed rows reference goal_type + slot_index).
export const BP_WEEKLY = {
  SLOTS: 5,
  XP_PER_CLEAR: 150,
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

// --- PvP Rank Thresholds (W3.D5 — Variant A ladder rewrite) ---
//
// Ladder: Bronze → Silver → Gold → Platinum → Diamond → Master → Grandmaster → Challenger
// Each ranged tier is 750 ELO wide with 3 divisions (III → II → I, 250 ELO each).
// Master (3750-4249) and Grandmaster (4250+) have no divisions.
// Challenger is top-100 leaderboard rank inside the Grandmaster rating band —
// NOT a persistent rating threshold, so no constant here.
//
// Industry precedent: LoL 10 tiers × 4 div, Valorant 9 × 3, Apex 8 × 4.
// Starting rating 1000 (Character.pvpRating default) lands in Silver II.
//
// These constants are kept for live-config compatibility AND as the source
// of truth for tier floors, but the ladder logic lives in tier.ts
// (tierFromRating / divisionFromRating). Do not duplicate those computations
// here — import from tier.ts instead.
export const PVP_RANKS = {
  BRONZE: 0,
  SILVER: 750,
  GOLD: 1500,
  PLATINUM: 2250,
  DIAMOND: 3000,
  MASTER: 3750,
  GRANDMASTER: 4250,
} as const;

// --- Combat ---
export const COMBAT = {
  MAX_TURNS: 15,
  MIN_DAMAGE: 1,
  CRIT_MULTIPLIER: 1.5,
  MAX_CRIT_CHANCE: 50,
  MAX_DODGE_CHANCE: 30,
  ROGUE_DODGE_BONUS: 4,         // W3.D2 partial restore (was 3, original 5)
  TANK_DAMAGE_REDUCTION: 0.85,  // tanks take 15% less damage
  DAMAGE_VARIANCE: 0.10,        // ±10% damage variance
  POISON_ARMOR_PENETRATION: 0.3, // poison ignores 30% of armor (was 50%)
  // Crit/dodge formula coefficients (W3.D2 partial restore to ease AGI/Rogue pressure)
  CRIT_PER_LUK: 0.6,            // W3.D2 was 0.7 — minor LUK concession to AGI
  CRIT_PER_AGI: 0.2,            // W3.D2 was 0.15 — partial restore toward original 0.3
  DODGE_PER_AGI: 0.2,           // unchanged
  DODGE_PER_LUK: 0.1,           // minor LUK dodge contribution (kept)
  // Rogue Execute — bonus damage vs low-HP enemies (thematic finisher)
  ROGUE_EXECUTE_HP_THRESHOLD: 0.35, // triggers when defender HP ratio <= 35%
  ROGUE_EXECUTE_DAMAGE_BONUS: 0.15, // +15% final damage when triggered
  // W3.D1 — CHA miss chance (REPLACES legacy CHA intimidation damage reduction).
  // Defender's CHA unnerves the attacker, causing them to miss entirely.
  // Rolled BEFORE dodge so it's a pure pre-hit whiff, not evasion.
  // Industry precedent: D&D charm/intimidate save, MMO "blind" debuffs.
  CHA_MISS_PER_POINT: 0.2,  // +0.2% miss per CHA point of defender
  CHA_MISS_CAP: 20,         // max 20% miss from CHA alone
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

  // W3.D4 — Stance symmetry.
  // Every zone must be viable on BOTH attack and defense; no strictly dominated options.
  // Personality per zone stays consistent across the two sides:
  //   head  = high risk / high reward (glass cannon)
  //   chest = balanced (steady)
  //   legs  = safe / mixed (no big payoff, no big penalty)
  //
  // Legs attack used to be (offense:0, crit:-3) — strictly dominated by chest.
  // New: (offense:2, crit:0) — small but non-zero upside, rewarding mixups.
  ATTACK_ZONE: {
    head:  { offense: 10, crit: 5 },   // aggressive, high crit
    chest: { offense: 5,  crit: 0 },   // balanced
    legs:  { offense: 2,  crit: 0 },   // safe — small offense, no crit penalty
  } as const satisfies Record<BodyZone, { offense: number; crit: number }>,

  // Intrinsic bonuses for choosing a defense zone
  // Kept unchanged — already symmetric across the three zones.
  DEFENSE_ZONE: {
    head:  { defense: 0,  dodge: 8 },  // evasive (matches head-attack "risk" identity)
    chest: { defense: 10, dodge: 0 },  // tanky   (matches chest "steady" identity)
    legs:  { defense: 5,  dodge: 3 },  // mixed   (matches legs "safe" identity)
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
 * CHA gold bonus with diminishing returns (W3.D3 — cap reduced 125% → 80%).
 *
 * W3.D1 turned CHA's primary effect into miss-chance (intimidation). Gold
 * bonus is now a secondary flavour of the stat, and 125% stacked with
 * win-streak + first-win + level-scaling blew sink-ratio targets apart in
 * economy simulations. 80% cap keeps the "merchant build" feel without
 * making CHA mandatory for farming. Industry precedent: Diablo III Paragon
 * fame DR, RAID masteries with hard ceilings.
 *
 * Curve shape is unchanged — only the hard ceiling moved:
 * - CHA 0-30:  +2.5% per point
 * - CHA 31-60: +1.0% per point
 * - CHA 61+:   +0.5% per point, capped at +80%
 */
export const CHA_GOLD_BONUS_CAP = 0.80;

export function chaGoldBonus(baseGold: number, cha: number): number {
  let bonus = 0;
  if (cha <= 30) {
    bonus = cha * 0.025;
  } else if (cha <= 60) {
    bonus = 30 * 0.025 + (cha - 30) * 0.01;
  } else {
    bonus = 30 * 0.025 + 30 * 0.01 + (cha - 60) * 0.005;
  }
  // W3.D3 — hard cap at 80% (was 125%).
  bonus = Math.min(bonus, CHA_GOLD_BONUS_CAP);
  return Math.floor(baseGold * (1 + bonus));
}

// --- Loss Streak Gold Protection (W3.D3 — capped at +50%) ---
// After consecutive losses, next win gives bonus gold to reduce frustration.
// Pre-W3.D3: [..., 0.3, 0.3, 0.5, 0.5, 0.8, ...] — up to +80% bonus was a
// whale-farming loophole when combined with CHA+streak+first-win stacking.
// W3.D3 rebalance (Clash Royale / LoL recovery model): max +50%. This still
// cushions tilt recovery without letting a loss-streak farmer out-earn a
// straight winner. Ratio stays monotone non-decreasing.
export const LOSS_STREAK_BONUSES: readonly number[] = [
  0, 0, 0, 0.2, 0.2, 0.35, 0.35, 0.5, 0.5, 0.5, 0.5,
] as const;

/** Get the gold bonus multiplier for loss streak recovery (applied on next WIN). */
export function lossStreakGoldMultiplier(lossStreak: number): number {
  if (lossStreak < 0) return 0;
  const idx = Math.min(lossStreak, LOSS_STREAK_BONUSES.length - 1);
  return LOSS_STREAK_BONUSES[idx];
}

// --- Win Streak Gold Bonuses (W3.D3 — capped at +50%) ---
// Index = streak length, value = bonus multiplier (0 = no bonus).
// Pre-W3.D3: [..., 0.2, 0.2, 0.5, 0.5, 0.5, 1.0, ...] — an 8-win streak
// doubled income, and stacked with CHA + first-win + level-scaling it ran
// theoretical peak earnings to ~×13 average. Clash Royale, Fortnite and LoL
// all cap streak bonuses well under ×2 (typical ×1.25 – ×1.5). W3.D3 caps
// the top bucket at +50% which holds peak stacking to ~×6 — aggressive but
// not uncapped. Empirically this change alone moves sink ratio by ~20 pts.
export const WIN_STREAK_BONUSES: readonly number[] = [
  0, 0, 0, 0.15, 0.15, 0.3, 0.3, 0.3, 0.5, 0.5, 0.5,
] as const;

/** Get the gold bonus multiplier for the current win streak. */
export function streakGoldMultiplier(winStreak: number): number {
  if (winStreak < 0) return 0;
  const idx = Math.min(winStreak, WIN_STREAK_BONUSES.length - 1);
  return WIN_STREAK_BONUSES[idx];
}

/** Scale PvP gold/XP reward based on character level (higher levels earn slightly more). */
export function levelScaledReward(baseReward: number, level: number): number {
  // Economy v3 (2026-04-13): +4% per level above 1 (was +2%).
  // v2's +2% was slower than cost scaling (repair/upgrade grow faster), making midgame
  // feel like treading water. Doubling the slope keeps earning power ahead of costs at
  // L10–L30. Level 50 now gets +196% = ~3× rewards. See ECONOMY_RULES.md R3.
  return Math.floor(baseReward * (1 + (level - 1) * 0.04));
}

// --- Equipment Repair Costs (W3.D3 — bumped to meet sink-ratio target) ---
// Pre-W3.D3 (80 / 15) only took ~15% of a typical fight's gold, well under
// the 25-35% band used by RAID: Shadow Legends and AFK Arena for equipment
// maintenance. W3.D3 raises base cost 80 → 120 and per-level 15 → 20 so
// that a full gear repair lands at ~70-90% of the gold earned between
// repair cycles. Durability is still 100 → dozens of fights, so the sink
// is applied in lumps rather than per-fight tax.
export const REPAIR_COSTS = {
  BASE_COST: 120,
  PER_LEVEL: 20,
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

// --- Equipment Upgrade Costs (Economy v2 — exponential to create endgame gold sink) ---
export const UPGRADE_COSTS = {
  BASE: 150,
  EXPONENT: 1.4,
} as const;

/** Calculate gold cost for upgrading to +N. Exponential: 150 × 1.4^N */
export function upgradeCost(plusLevel: number): number {
  return Math.floor(UPGRADE_COSTS.BASE * Math.pow(UPGRADE_COSTS.EXPONENT, plusLevel));
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

// --- Gem costs (Economy v3, 2026-04-13) ---
// See ECONOMY_RULES.md R7.3 (protection), R8 (stamina), R11/R12 (BP), R13 (mine).
export const GEM_COSTS = {
  STAMINA_REFILL: 50,           // v3: 30 → 50 (1st of day). Diminishing curve via STAMINA_REFILL_DR: 50 / 80 / 140 / 240.
  EXTRA_PVP_COMBAT: 50,         // kept for backward compat, prefer STAMINA_REFILL
  BATTLE_PASS_PREMIUM: 700,     // v3: 500 → 700. Brings BP price in line with industry mid-core (~$5 effective) and pushes whales into the Premium Pass funnel.
  GOLD_MINE_BUY_SLOT: 50,
  GOLD_MINE_BOOST: 15,          // v3: 3 → 15. At 3💎 the boost was a no-op pricewise; at 15💎 it becomes a meaningful "skip the wait" choice while still F2P-affordable from daily gem income.
  UPGRADE_PROTECTION: 40,       // v3: 50 → 40. With downgrade-on-fail at +9/+10 (UPGRADE_DOWNGRADE_LEVELS) the scroll has higher utility, so the price drop keeps the EV positive for the player.
} as const;

// --- Stat Point Purchase (escalating daily cost) ---
export const STAT_PURCHASE = {
  ESCALATION: [15, 20, 30, 45, 65] as readonly number[],
  DAILY_LIMIT: 5,
  GLOBAL_CAP: 50,
} as const;

// --- Inventory ---
// NOTE: per-character slot count lives on Character.inventorySlots (default BASE_SLOTS,
// grows by EXPAND_AMOUNT on each expand, capped at BASE_SLOTS + MAX_EXPANSIONS*EXPAND_AMOUNT).
// There is NO separate global cap — MAX_SLOTS is derived, not configurable. See CRIT-04.
export const INVENTORY = {
  BASE_SLOTS: 28,
  EXPAND_AMOUNT: 10,
  EXPAND_COST_GOLD: 5000,
  MAX_EXPANSIONS: 3, // 28 + 3*10 = 58 max
  /** Derived hard ceiling — equals the maximum any character can ever reach. */
  MAX_SLOTS: 28 + 3 * 10, // = 58
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
