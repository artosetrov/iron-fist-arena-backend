// =============================================================================
// balance.ts — Game balance constants and formulas
// =============================================================================

import { minRatingForTier } from './tier';

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

// --- Stamina potion daily cap (2026-09-12) ---
// Gem refills were capped at 4/day, but potions — which restore the SAME bar
// and are handed out free by contraband — had no cap at all. Matching the two
// keeps stamina an actual throttle instead of a formality.
export const STAMINA_POTION_DR = {
  /** Maximum stamina potions of any size a character may drink per day. */
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
export function trainingXpMultiplier(
  clearsToday: number,
  cfg: { FULL_XP_CLEARS: number; HALF_XP_CLEARS: number; FLOOR_MULTIPLIER: number } = TRAINING_XP_DR,
): number {
  if (clearsToday < 0) return 1;
  if (clearsToday < cfg.FULL_XP_CLEARS) return 1;
  if (clearsToday < cfg.FULL_XP_CLEARS + cfg.HALF_XP_CLEARS) return 0.5;
  return cfg.FLOOR_MULTIPLIER;
}

/**
 * Gem cost for the Nth stamina refill of the day. Returns null if the daily
 * refill cap has been hit.
 *
 * @param baseCost       The base gem cost from GEM_COSTS.STAMINA_REFILL.
 * @param refillsToday   Number of refills already used today (pre-increment).
 */
export function staminaRefillGemCost(
  baseCost: number,
  refillsToday: number,
  cfg: { DAILY_CAP: number; COST_MULTIPLIERS: readonly number[] } = STAMINA_REFILL_DR,
): number | null {
  if (refillsToday < 0) refillsToday = 0;
  if (refillsToday >= cfg.DAILY_CAP) return null;
  const mults = cfg.COST_MULTIPLIERS.length > 0 ? cfg.COST_MULTIPLIERS : STAMINA_REFILL_DR.COST_MULTIPLIERS;
  const mult = mults[refillsToday] ?? mults[mults.length - 1];
  return Math.ceil(baseCost * mult);
}

// --- Matchmaking (live-tunable via live-config `matchmaking.*`) ---
export const MATCHMAKING = {
  LEVEL_RANGE: 10,            // ± levels for opponent search
  GEAR_SCORE_TOLERANCE: 0.8,  // ± fraction of the player's gear score
} as const;

// --- HP Regen ---
export const HP_REGEN = {
  REGEN_RATE: 1,              // 1% of maxHp per interval
  REGEN_INTERVAL_MINUTES: 5,  // every 5 minutes
} as const;

// --- Monthly Gem Card ---
// Sold as "50 gems now + 10 gems a day for 30 days". The instant 50 come from
// IAP_PRODUCTS.monthly_gem_card.gems; the daily part is claimed lazily by
// `grantDailyGemCard` on /api/game/init (nothing paid it out before
// AUDIT-2026-10-13 H3).
export const MONTHLY_GEM_CARD = {
  DAILY_GEMS: 10,
  DAYS: 30,
} as const;

// --- XP ---
/**
 * Scale on the whole level curve. ONE knob, mirrored in iOS
 * `Character.xpCurveScale` — change both or the XP bar lies.
 *
 * Why 3 (2026-10-14 balance audit): with the design curve alone (55k total)
 * and PvP XP level-scaled at +4%/level on top, a full-stamina player hit L50
 * on day 12 — day 4 with the legal four gem refills — under a 90-day Battle
 * Pass season, with nine of ten buildings open by day 2. ×3 puts L50 near
 * day 35 without touching the reward side. It also makes the empty level
 * bands (16–19, 22–24, 26–29, …) three times longer in wall-clock, so it is
 * meant to ship together with content in those bands — skill unlocks and
 * items at itemLevel 41–50 — not instead of it.
 */
export const XP_CURVE_SCALE = 3;

/**
 * Cumulative XP threshold for a level: `(100N + 20N²) × XP_CURVE_SCALE`
 * (BALANCE_CONSTANTS.md "XP Formula", scaled). Level 50 = 165,000 total.
 *
 * NOT the per-level requirement. `checkLevelUp` resets `currentXp` on every
 * level, so it must use `xpToNextLevel` below. Feeding this cumulative value
 * into the per-level loop made L50 cost ~986k XP (×18 the design) — the
 * "XP curve" item open since the April balance audit (AUDIT-2026-10-13 H6).
 */
export function xpForLevel(level: number): number {
  return (100 * level + 20 * level * level) * XP_CURVE_SCALE;
}

/**
 * XP needed to finish `level` (reach `level + 1`) when XP resets per level.
 * `xpForLevel(level + 1) - xpForLevel(level)` = `(120 + 40·level) × scale`.
 * At scale 3: L1→2 = 480, L10→11 = 1,560, L49→50 = 6,240; sum 1..49 = 164,640.
 * iOS mirrors this in `Character.xpNeeded` — keep both in sync.
 */
export function xpToNextLevel(level: number): number {
  return xpForLevel(level + 1) - xpForLevel(level);
}

// --- Gold rewards (Economy v2 — reduced to fix gold hyperinflation) ---
export const GOLD_REWARDS = {
  PVP_WIN_BASE: 150,         // was 200 — sink ratio was 10%, target 55-65%
  PVP_LOSS_BASE: 50,         // was 70 — loss shouldn't feel comfortable
  TRAINING_WIN: 30,           // was 50 — training = practice, not income
  TRAINING_LOSS: 10,          // was 20
  REVENGE_MULTIPLIER: 1.5,
  // Share of the base paid to the DEFENDER of an incoming attack. They spent
  // no stamina, made no choice and took no gear wear; at a full share (the
  // state until 2026-10-14) every fight minted gold on two accounts and an
  // active player earned ~2 100/day for being attacked. One third keeps the
  // "your castle held" moment without a second income stream.
  DEFENDER_REWARD_SHARE: 0.34,
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
  // Monthly Gem Card (50 instant gems + server creates daily_gem_card entry;
  // the 10/day is granted lazily by /api/game/init — see MONTHLY_GEM_CARD)
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
// Master and Grandmaster have no divisions. The widths below describe the
// frozen defaults; once an operator edits `pvp_ranks.*` the tiers are whatever
// resolveTierRanges() produces, so read tier.ts rather than this comment.
// Challenger is top-100 leaderboard rank inside the Grandmaster rating band —
// NOT a persistent rating threshold, so no constant here.
//
// Industry precedent: LoL 10 tiers × 4 div, Valorant 9 × 3, Apex 8 × 4.
// Starting rating 1000 (Character.pvpRating default) lands in Silver II.
//
// These constants exist so the admin balance panel can edit tier floors under
// the `pvp_ranks.*` keys. They are DERIVED from tier.ts, not typed out again:
// as literals they were a second copy of the ladder that nothing checked, and
// a second copy of a table is a table that will eventually disagree with the
// first one. The ladder logic itself (tierFromRating / divisionFromRating)
// lives in tier.ts — never re-derive it here.
export const PVP_RANKS = {
  BRONZE: minRatingForTier('bronze'),
  SILVER: minRatingForTier('silver'),
  GOLD: minRatingForTier('gold'),
  PLATINUM: minRatingForTier('platinum'),
  DIAMOND: minRatingForTier('diamond'),
  MASTER: minRatingForTier('master'),
  GRANDMASTER: minRatingForTier('grandmaster'),
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
  // 2026-10-14 balance audit. Armor/MR reduce damage by 100/(100+resist) with
  // no ceiling, while damage is linear in stats — so from L1 to L50 damage grew
  // ×28 and effective HP ×69. By L25, 29% of mirror matches hit the 15-turn
  // cap; at L50 essentially all of them did, decided by an HP% comparison.
  // Capping the reduction keeps late-game armor meaningful without letting it
  // outrun damage forever. Swept with tests/lib/combat-ttk.test.ts on the
  // real engine: 0.75 still timed out 40% of L50 mirrors; 0.6 ends L25 and
  // L50 mirrors in ~10 rounds with the cap essentially never reached, and
  // leaves armor below ~150 (around L15) untouched. 0.6 = at most 60% of a
  // hit absorbed.
  MAX_RESIST_REDUCTION: 0.6,
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

// --- Zone Matrix v2 (Combat v2, docs/06_game_systems/COMBAT_V2_DESIGN.md §3) ---
//
// Replaces the intrinsic STANCE_ZONES bonuses when `combat.zone_matrix_v2` is on.
// The whole zone interaction lives in the pair (attack, opponent block):
//
//   attack \ block   | open zone                          | blocked (attack == opp.block)
//   -----------------+------------------------------------+------------------------------------
//   head             | guaranteed crit × HEAD_CRIT_MULT   | × HEAD_BLOCKED_MULT + defender counters
//   chest            | × 1 (normal crit roll)             | × CHEST_BLOCKED_MULT
//   legs             | × LEGS_OPEN_MULT, opens opponent   | × LEGS_BLOCKED_MULT
//
// "Opens opponent" = the opponent's block does not apply on the NEXT round.
// Numbers come from scripts/zone_matrix_sim.py: mixed equilibrium on both sides
// (block 50/21/29, attack 14/50/36), a head-spammer loses to a turtle bot (20%),
// an adaptive reader beats a head-spammer (100%). Tune via live-config keys
// `combat.zone.*` without a deploy.
export const ZONE_MATRIX = {
  HEAD_CRIT_MULT: 1.8,
  HEAD_BLOCKED_MULT: 0.35,
  HEAD_COUNTER_MULT: 0.15,   // × defender's own auto-attack hit, dealt back to the attacker
  CHEST_BLOCKED_MULT: 0.6,
  LEGS_OPEN_MULT: 0.85,
  LEGS_BLOCKED_MULT: 0.5,
} as const;

// Zone-policy noise: share of rounds in which a bot personality / ghost picks
// uniformly instead of following its pattern. Keeps patterns readable but not
// a deterministic puzzle.
export const ZONE_POLICY = {
  PERSONALITY_NOISE: 0.12,
  GHOST_NOISE: 0.15,
  /** Rounds of recorded data before a ghost is trusted over a fallback personality. */
  GHOST_MIN_ROUNDS: 6,
  /** Exponential decay applied to the profile counts after every match (≈30-round memory). */
  GHOST_DECAY: 0.85,
  /** Tail of recent rounds exposed to the client as the read-strip. */
  PATTERN_TAIL: 8,
} as const;

// Dice combat (docs/06_game_systems/DICE_RUNES_DESIGN.md). Two d6 per fighter —
// attack + guard, faces head/head/chest/chest/legs/legs. Same zone = block.
// Prototype sims: smart Focus use ≈53% vs smart, ≈16% never spending; ~7 rounds.
// Tune live via game_config `dice.*` (see getDiceConfig in live-config.ts).
export const DICE = {
  HEAD_MULT: 1.6,        // head into an open zone = crit
  CHEST_MULT: 1.0,
  LEGS_MULT: 0.9,        // legs also sweep: defender's guard is off next round
  FOCUS_START: 2,
  FOCUS_PER_ROUND: 1,
  FOCUS_MAX: 5,
  REROLL_COST: 2,
  SET_FACE_COST: 4,
  MAX_ROUNDS: 15,
  FATIGUE_START_ROUND: 10,
  FATIGUE_PER_ROUND: 0.15,
  DAMAGE_VARIANCE: 0.1,
  /** Global scale on the per-strike hit so a duel lands in ~6–9 rounds. */
  DAMAGE_SCALE: 1.4,
  /** Decision window the client shows per round (server does not enforce it). */
  WINDOW_MS: 8000,
  /** Boss phase 2 (≤ this HP share) rolls a second attack die… */
  BOSS_PHASE2_HP: 0.5,
  /** …which strikes at this share of a normal hit. */
  BOSS_SECOND_DIE_MULT: 0.6,
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

// --- Equipment Upgrade Costs (Economy v2 — power-law endgame gold sink) ---
//
// Mirrors the LIVE route formula in item-balance.ts `getUpgradeCost`
// ('exponential' mode): cost to reach +N = BASE × N^EXPONENT. This file used
// to say 150 × 1.4^N (a true exponential, ~10.5k for +1..+10) while the route
// charged 150 × N^1.4 (~17.6k) — and the economy simulator imports THIS one,
// so it under-estimated the sink by ~40% (2026-10-14 balance audit). Same
// numbers as the admin seed; if you change one, change all three.
export const UPGRADE_COSTS = {
  BASE: 150,
  EXPONENT: 1.4,
} as const;

/** Gold cost for upgrading to +N: 150 × N^1.4 (same curve as the live route). */
export function upgradeCost(plusLevel: number): number {
  return Math.round(UPGRADE_COSTS.BASE * Math.pow(plusLevel, UPGRADE_COSTS.EXPONENT));
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
  BASE_ACTIVE_SLOTS: 3,   // Slot count granted by default.
  MAX_ACTIVE_SLOTS: 4,    // Hard cap after the premium unlock.
  PREMIUM_ACTIVE_SLOT_GEM_COST: 100, // One-time gem cost to unlock the 4th slot.
  // Talents v2 (2026-04-19): one free respec per rolling 7-day window. See
  // docs/06_game_systems/SKILL_TREE_DESIGN_V2.md §9. Window is measured from
  // Character.lastFreeRespecAt; null or >= 7 days old ⇒ free path.
  FREE_RESPEC_PER_WEEK: 1,
  FREE_RESPEC_WINDOW_DAYS: 7,
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
