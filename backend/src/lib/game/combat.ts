// =============================================================================
// combat.ts — Turn-based combat engine
// baseDamage now reads class scaling from GameConfig via item-balance engine.
// =============================================================================

import { STANCE_ZONES, BATTLE_FATIGUE, ZONE_MATRIX, type BodyZone } from './balance';
import { getCombatConfig } from './live-config';
import {
  pickZones,
  policyForCharacter,
  type ZonePolicy,
  type ZoneRoundContext,
} from './zone-policy';
import { getClassDamageFormula } from './item-balance';
import {
  selectSkill,
  calculateSkillDamage,
  putOnCooldown,
  tickCooldowns,
  type SkillDefinition,
  type SkillCooldownState,
} from './skills';
import { emptyPassiveBonuses, type PassiveBonuses } from './passives';

// --- Types ---

export type CharacterClassType = 'warrior' | 'rogue' | 'mage' | 'tank';
export type DamageType = 'physical' | 'magical' | 'true_damage' | 'poison';

export interface CharacterStats {
  id: string;
  name: string;
  class: CharacterClassType;
  level: number;
  str: number;
  agi: number;
  vit: number;
  end: number;
  int: number;
  wis: number;
  luk: number;
  cha: number;
  maxHp: number;
  currentHp?: number;
  armor: number;
  magicResist: number;
  avatar?: string | null;
  combatStance?: Record<string, unknown> | null;
  equippedSkills?: SkillDefinition[];
  passiveBonuses?: PassiveBonuses;
  /**
   * BUG-44/45/46 (QA 2026-04-10) — tutorial targets (e.g. Straw Dummy).
   * When true in `runCombat`, the character never takes an attack turn: they
   * only receive damage from the opponent. Used for "lifeless target" enemies
   * where lore says they shouldn't fight back (Training Camp stage 1).
   * NOT to be confused with stun/CC effects, which are per-turn and temporary.
   */
  isPassiveTarget?: boolean;
  /**
   * Combat v2 — how this side picks zones when no human is choosing
   * (classic auto-resolve, and the opponent side of interactive combat).
   * Absent → a stable personality derived from `id` (see zone-policy.ts).
   */
  zonePolicy?: ZonePolicy;
}

/**
 * Combat v2 — one word per strike for the client. `miss`/`dodge` are the
 * pre-hit whiffs that already existed; `blocked` means the attack went into
 * the defender's block zone (reduced damage, head also eats a counter).
 * `none` = the side never swung this round (fell before its initiative).
 */
export type StrikeOutcome = 'crit' | 'hit' | 'blocked' | 'miss' | 'dodge' | 'none';

export interface Turn {
  turnNumber: number;
  attackerId: string;
  damage: number;
  isCrit: boolean;
  isDodge: boolean;
  /**
   * W3.D1 — CHA-driven pre-hit whiff (distinct from dodge).
   * True when the attacker missed entirely due to defender's CHA unnerving them.
   * Backward-compatible: omitted on old turns/clients default to `undefined`/false.
   */
  isMiss?: boolean;
  defenderHpAfter: number;
  skillUsed?: string;
  skillKey?: string;
  damageType?: DamageType;
  healAmount?: number;
  targetZone?: string;
  defendZone?: string;
  stanceSwitch?: boolean; // True if stance was auto-rotated this turn
  /** Combat v2 — aggregated verdict for the UI. Absent on v1 turns. */
  outcome?: StrikeOutcome;
  /** Combat v2 — damage the DEFENDER dealt back (head into block). Already applied by the caller. */
  counterDamage?: number;
  /** Combat v2 — legs landed: defender's block does not apply next round. */
  opensDefender?: boolean;
}

// Mid-battle stance rotation: every N turns, attack/defense zones shift
const STANCE_ROTATION_INTERVAL = 3;
const ZONE_CYCLE: BodyZone[] = ['head', 'chest', 'legs'];

export interface CombatResult {
  winnerId: string;
  loserId: string;
  turns: Turn[];
  totalTurns: number;
  finalHp: Record<string, number>;
}

// --- Zone-based stance computation ---

interface StanceModifiers {
  offense: number;
  defense: number;
  crit: number;
  dodge: number;
}

interface ParsedZoneStance {
  attack: BodyZone;
  defense: BodyZone;
}

const DEFAULT_ZONE_STANCE: ParsedZoneStance = { attack: 'chest', defense: 'chest' };

function parseZoneStance(combatStance: Record<string, unknown> | null | undefined): ParsedZoneStance {
  if (!combatStance) return DEFAULT_ZONE_STANCE;
  const attack = combatStance.attack;
  const defense = combatStance.defense;
  const valid: readonly string[] = STANCE_ZONES.VALID_ZONES;
  return {
    attack: (typeof attack === 'string' && valid.includes(attack)) ? attack as BodyZone : 'chest',
    defense: (typeof defense === 'string' && valid.includes(defense)) ? defense as BodyZone : 'chest',
  };
}

/**
 * Compute effective stance modifiers given own zone stance and opponent's zone stance.
 * Zone matching creates strategic interaction between fighters.
 */
function computeStanceModifiers(myStance: ParsedZoneStance, opponentStance: ParsedZoneStance): StanceModifiers {
  const atkBonus = STANCE_ZONES.ATTACK_ZONE[myStance.attack];
  const defBonus = STANCE_ZONES.DEFENSE_ZONE[myStance.defense];

  const offenseMismatch = myStance.attack !== opponentStance.defense
    ? STANCE_ZONES.MISMATCH_OFFENSE_BONUS : 0;
  const defenseMatch = opponentStance.attack === myStance.defense
    ? STANCE_ZONES.MATCH_DEFENSE_BONUS : 0;

  return {
    offense: atkBonus.offense + offenseMismatch,
    defense: defBonus.defense + defenseMatch,
    crit: atkBonus.crit,
    dodge: defBonus.dodge,
  };
}

// --- Seeded PRNG (Mulberry32) ---

export type SeededRng = () => number;

/**
 * Create a deterministic PRNG from a 32-bit integer seed.
 * Both server and client use the same algorithm for identical results.
 */
export function createSeededRng(seed: number): SeededRng {
  let s = seed | 0;
  return () => {
    s = (s + 0x6d2b79f5) | 0;
    let t = Math.imul(s ^ (s >>> 15), 1 | s);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// --- Internal helpers ---

// Module-level TTL cache for class damage config (avoids DB hit on every combat)
let _cachedClassDamage: Record<string, { stat: string; multiplier: number; levelBonus: number }> | null = null;
let _classDamageCacheTime = 0;
const CLASS_DAMAGE_CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Pre-load class damage config so we don't hit DB per turn.
 * Module-level TTL cache — re-fetches only after 5 min, not every combat.
 * Parallel Promise.all instead of sequential for loop.
 */
async function loadClassDamageConfig(): Promise<void> {
  const now = Date.now();
  if (_cachedClassDamage && (now - _classDamageCacheTime) < CLASS_DAMAGE_CACHE_TTL_MS) {
    return; // Cache is fresh — skip DB entirely
  }
  const classes = ['warrior', 'tank', 'rogue', 'mage'] as const;
  const formulas = await Promise.all(classes.map((cls) => getClassDamageFormula(cls)));
  _cachedClassDamage = Object.fromEntries(classes.map((cls, i) => [cls, formulas[i]]));
  _classDamageCacheTime = now;
}

/**
 * Calculate base damage for a character based on their class.
 * Reads scaling from cached config.
 */
function baseDamage(c: CharacterStats): number {
  const config = _cachedClassDamage?.[c.class];
  if (config) {
    const statValue = (c as unknown as Record<string, number>)[config.stat] ?? c.str;
    let dmg = statValue * config.multiplier + c.level * config.levelBonus;
    // Secondary stat scaling for classes with dual-stat formulas
    if (c.class === 'mage') dmg += c.wis * 0.25;
    if (c.class === 'tank') dmg += c.vit * 0.3;
    return dmg;
  }
  // Fallback if config not loaded
  switch (c.class) {
    case 'warrior':
      return c.str * 1.5 + c.level * 2;
    case 'tank':
      return c.str * 1.3 + c.vit * 0.3 + c.level * 2;
    case 'rogue':
      return c.agi * 1.5 + c.level * 2;
    case 'mage':
      return c.int * 1.4 + c.wis * 0.25 + c.level * 2;
    default:
      return c.str * 1.5 + c.level * 2;
  }
}

function getAutoAttackDamageType(cls: CharacterClassType): DamageType {
  switch (cls) {
    case 'mage': return 'magical';
    case 'rogue': return 'poison';
    default: return 'physical';
  }
}

interface CombatConfigData {
  MAX_TURNS: number;
  MIN_DAMAGE: number;
  CRIT_MULTIPLIER: number;
  MAX_CRIT_CHANCE: number;
  MAX_DODGE_CHANCE: number;
  ROGUE_DODGE_BONUS: number;
  TANK_DAMAGE_REDUCTION: number;
  DAMAGE_VARIANCE: number;
  POISON_ARMOR_PENETRATION: number;
  CRIT_PER_LUK: number;
  CRIT_PER_AGI: number;
  DODGE_PER_AGI: number;
  DODGE_PER_LUK: number;
  /** Ceiling on the fraction of a hit that armor/MR can absorb (0.75 = 75%). */
  MAX_RESIST_REDUCTION: number;
  // W3.D1 — CHA miss chance (replaces legacy intimidation damage reduction)
  CHA_MISS_PER_POINT: number;
  CHA_MISS_CAP: number;
  // W3.D2 — Rogue Execute: bonus damage vs low-HP defenders
  ROGUE_EXECUTE_HP_THRESHOLD: number;
  ROGUE_EXECUTE_DAMAGE_BONUS: number;
  // Combat v2 — zone matrix. Optional so tests/mocks built before v2 still type-check.
  ZONE_MATRIX_V2?: boolean;
  ZONE?: ZoneMatrixConfig;
}

export interface ZoneMatrixConfig {
  HEAD_CRIT_MULT: number;
  HEAD_BLOCKED_MULT: number;
  HEAD_COUNTER_MULT: number;
  CHEST_BLOCKED_MULT: number;
  LEGS_OPEN_MULT: number;
  LEGS_BLOCKED_MULT: number;
}

const ZERO_STANCE: StanceModifiers = { offense: 0, defense: 0, crit: 0, dodge: 0 };

export function isZoneMatrixV2(config: Pick<CombatConfigData, 'ZONE_MATRIX_V2'>): boolean {
  return config.ZONE_MATRIX_V2 === true;
}

function zoneConfig(config: Pick<CombatConfigData, 'ZONE'>): ZoneMatrixConfig {
  return config.ZONE ?? ZONE_MATRIX;
}

/**
 * Combat v2 — the whole zone interaction in one pure function
 * (docs/06_game_systems/COMBAT_V2_DESIGN.md §3.1). Exported for unit tests.
 *
 * @returns damage multiplier, whether the hit is a forced crit (head into an
 *          open zone), the counter multiplier the defender deals back (head
 *          into block), and whether the defender is opened next round (legs).
 */
export function zoneMatrixEffect(
  attackZone: BodyZone,
  blocked: boolean,
  zone: ZoneMatrixConfig,
): { mult: number; forcedCrit: boolean; counterMult: number; opens: boolean } {
  switch (attackZone) {
    case 'head':
      return blocked
        ? { mult: zone.HEAD_BLOCKED_MULT, forcedCrit: false, counterMult: zone.HEAD_COUNTER_MULT, opens: false }
        : { mult: zone.HEAD_CRIT_MULT, forcedCrit: true, counterMult: 0, opens: false };
    case 'legs':
      return blocked
        ? { mult: zone.LEGS_BLOCKED_MULT, forcedCrit: false, counterMult: 0, opens: false }
        : { mult: zone.LEGS_OPEN_MULT, forcedCrit: false, counterMult: 0, opens: true };
    case 'chest':
    default:
      return blocked
        ? { mult: zone.CHEST_BLOCKED_MULT, forcedCrit: false, counterMult: 0, opens: false }
        : { mult: 1, forcedCrit: false, counterMult: 0, opens: false };
  }
}

/**
 * Multiplier a resist value applies to a hit, floored at `1 − MAX_RESIST_REDUCTION`.
 *
 * `100/(100+resist)` has no floor of its own: at resist 580 (a L50 legendary
 * loadout) it keeps 15% of the hit, and since resist grows with gear while
 * damage grows linearly, late-game fights stopped ending in a kill. The floor
 * means no amount of armor absorbs more than the configured share.
 */
function resistMultiplier(resist: number, config: Pick<CombatConfigData, 'MAX_RESIST_REDUCTION'>): number {
  const effectiveResist = Math.max(0, resist);
  const floor = 1 - Math.min(1, Math.max(0, config.MAX_RESIST_REDUCTION ?? 1));
  return Math.max(floor, 100 / (100 + effectiveResist));
}

function reduceDamageByType(
  raw: number,
  defender: CharacterStats,
  damageType: DamageType,
  config: CombatConfigData,
): number {
  if (damageType === 'true_damage') return raw;
  if (damageType === 'poison') {
    const effectiveArmor = Math.max(0, defender.armor) * (1 - config.POISON_ARMOR_PENETRATION);
    return raw * resistMultiplier(effectiveArmor, config);
  }
  const resist = damageType === 'magical' ? defender.magicResist : defender.armor;
  return raw * resistMultiplier(resist, config);
}

function applyClassReduction(damage: number, defenderClass: CharacterClassType, config: CombatConfigData): number {
  if (defenderClass === 'tank') {
    return damage * config.TANK_DAMAGE_REDUCTION;
  }
  return damage;
}

function critChance(c: CharacterStats, stanceMod: StanceModifiers, config: CombatConfigData): number {
  return Math.min(
    c.luk * config.CRIT_PER_LUK + c.agi * config.CRIT_PER_AGI + stanceMod.crit,
    config.MAX_CRIT_CHANCE,
  );
}

function dodgeChance(defender: CharacterStats, stanceMod: StanceModifiers, config: CombatConfigData): number {
  const classBonus = defender.class === 'rogue' ? config.ROGUE_DODGE_BONUS : 0;
  return Math.min(
    defender.agi * config.DODGE_PER_AGI + defender.luk * config.DODGE_PER_LUK + classBonus + stanceMod.dodge,
    config.MAX_DODGE_CHANCE,
  );
}

/**
 * W3.D1 — CHA miss chance. Defender's CHA unnerves the attacker into whiffing.
 *
 * Pure helper, exported for unit tests. Returns a probability in **percent**
 * (0–`CHA_MISS_CAP`) — caller rolls `rollPercent(rng) < chaMissChance(...)`.
 *
 * Rolled BEFORE dodge in the attack pipeline so it's a pre-hit whiff, distinct
 * from AGI/LUK evasion. Capped so high-CHA builds don't become unhittable.
 */
export function chaMissChance(defenderCha: number, config: Pick<CombatConfigData, 'CHA_MISS_PER_POINT' | 'CHA_MISS_CAP'>): number {
  if (defenderCha <= 0) return 0;
  return Math.min(defenderCha * config.CHA_MISS_PER_POINT, config.CHA_MISS_CAP);
}

/**
 * W3.D2 — Rogue Execute finisher.
 *
 * Pure helper so the rule is unit-testable without spinning up full combat.
 * Applies a flat multiplicative damage bonus to the incoming `damage` when:
 *   1. attacker class is `rogue`
 *   2. defender HP ratio (current / max) is <= threshold
 *
 * Returns the (possibly boosted) damage. Exported for tests.
 */
export function applyRogueExecute(
  damage: number,
  attackerClass: CharacterClassType,
  defenderCurrentHp: number,
  defenderMaxHp: number,
  config: Pick<CombatConfigData, 'ROGUE_EXECUTE_HP_THRESHOLD' | 'ROGUE_EXECUTE_DAMAGE_BONUS'>,
): number {
  if (attackerClass !== 'rogue') return damage;
  if (defenderMaxHp <= 0) return damage;
  const hpRatio = defenderCurrentHp / defenderMaxHp;
  if (hpRatio > config.ROGUE_EXECUTE_HP_THRESHOLD) return damage;
  return damage * (1 + config.ROGUE_EXECUTE_DAMAGE_BONUS);
}

function applyVariance(damage: number, rng: SeededRng, config: CombatConfigData): number {
  const variance = config.DAMAGE_VARIANCE;
  const multiplier = (1 - variance) + rng() * (variance * 2);
  return damage * multiplier;
}

function rollPercent(rng: SeededRng): number {
  return rng() * 100;
}

// --- Dice combat ---

/** No zone bonuses inside the dice snapshot — the dice ARE the zones. */
const NEUTRAL_STANCE: StanceModifiers = { offense: 0, defense: 0, crit: 0, dodge: 0 };

/**
 * Share of a hit that passive damage reduction and the tank's class
 * reduction may absorb together inside the dice snapshot. Was 50 for the
 * passives alone with the class ×0.85 stacked on top: a 49-SP tank tree
 * reached ~×7.3 EHP·damage against ~×3.3 for a rogue (2026-10-16 balance
 * audit §2). One cap over both keeps the tank the sturdiest class without
 * making a full tree a wall.
 */
export const DICE_DAMAGE_REDUCTION_CAP = 35;

/**
 * Dice combat (dice.ts) — the EXPECTED value of one plain classic strike of
 * `attacker` against `defender`, snapshotted once per match. The dice supply
 * the variance; everything the classic engine would roll per hit is folded
 * in here as its expectation:
 *
 *   - class auto-attack, passive flat/percent damage, the defender's resists
 *   - crit chance (LUK/AGI stats + passive flat crit) as `1 + p·(CRIT_MULT−1)`
 *   - the defender's dodge (AGI/LUK + rogue bonus + passive flat dodge) and
 *     CHA miss as `1 − p`
 *   - tank class reduction and passive damage reduction under one cap
 *
 * Until 2026-10-16 the snapshot read only flat/percent damage, DR and
 * lifesteal, so LUK, the AGI dodge/crit, CHA and every passive node that
 * grants crit or dodge did nothing in live PvP — 36 of a rogue's 109 SP.
 * `cooldownReduction` has no dice analogue and stays out.
 */
export async function diceHitProfile(
  attacker: CharacterStats,
  defender: CharacterStats,
): Promise<{ hit: number; lifesteal: number }> {
  await loadClassDamageConfig();
  const config = await getCombatConfig();
  const pa = attacker.passiveBonuses ?? emptyPassiveBonuses();
  const pd = defender.passiveBonuses ?? emptyPassiveBonuses();
  let raw = baseDamage(attacker) + pa.flatDamage;
  raw *= 1 + pa.percentDamage / 100;

  // Crit as expectation. Same inputs and caps as resolveAttack.
  const crit = Math.min(critChance(attacker, NEUTRAL_STANCE, config) + pa.flatCritChance, config.MAX_CRIT_CHANCE);
  raw *= 1 + Math.max(0, crit) / 100 * (config.CRIT_MULTIPLIER - 1);

  let dmg = reduceDamageByType(raw, defender, getAutoAttackDamageType(attacker.class), config);

  // Dodge and CHA miss as expectation — a whiff is a 0, so p whiffs = ×(1−p).
  const dodge = Math.min(dodgeChance(defender, NEUTRAL_STANCE, config) + pd.flatDodgeChance, config.MAX_DODGE_CHANCE);
  dmg *= 1 - Math.max(0, dodge) / 100;
  dmg *= 1 - chaMissChance(defender.cha, config) / 100;

  // Tank class reduction and passive DR share one cap.
  const classReduction = defender.class === 'tank' ? Math.round((1 - config.TANK_DAMAGE_REDUCTION) * 100) : 0;
  const reduction = Math.min(classReduction + Math.max(0, pd.damageReduction), DICE_DAMAGE_REDUCTION_CAP);
  if (reduction > 0) dmg *= 1 - reduction / 100;

  return {
    hit: Math.max(config.MIN_DAMAGE, Math.round(dmg)),
    lifesteal: Math.max(0, Math.min(pa.lifesteal, 50)),
  };
}

// --- Main combat function ---

/**
 * Initialize config-driven combat. Call this before runCombat
 * to load class damage scaling from the database.
 */
export async function initCombatConfig(): Promise<void> {
  await loadClassDamageConfig();
}

/**
 * Resolve a single attack (skill-based or auto-attack).
 * Returns the turn data and the damage dealt.
 */
function resolveAttack(
  turnNumber: number,
  attackerChar: CharacterStats,
  defenderChar: CharacterStats,
  defenderHp: number,
  stanceAtk: StanceModifiers,
  stanceDef: StanceModifiers,
  passivesAtk: PassiveBonuses,
  passivesDef: PassiveBonuses,
  cooldownState: SkillCooldownState,
  rng: SeededRng,
  config: CombatConfigData,
  attackerZone?: string,
  defenderZone?: string,
  defenderOpened: boolean = false,
): { turn: Turn; newDefenderHp: number; healAmount: number; counterDamage: number } {
  // Combat v2: intrinsic zone bonuses are gone — the zone pair decides the
  // outcome below, so the stance modifiers collapse to zero here.
  const v2 = isZoneMatrixV2(config);
  if (v2) {
    stanceAtk = ZERO_STANCE;
    stanceDef = ZERO_STANCE;
  }

  // W3.D1 — CHA miss check FIRST (pre-hit whiff from intimidation presence).
  // Separate from dodge so we can tune CHA independently and surface "MISS" in UX.
  const missPct = chaMissChance(defenderChar.cha, config);
  const isMiss = missPct > 0 && rollPercent(rng) < missPct;

  if (isMiss) {
    return {
      turn: {
        turnNumber,
        attackerId: attackerChar.id,
        damage: 0,
        isCrit: false,
        isDodge: false,
        isMiss: true,
        defenderHpAfter: defenderHp,
        targetZone: attackerZone,
        defendZone: defenderZone,
        ...(v2 ? { outcome: 'miss' as const } : {}),
      },
      newDefenderHp: defenderHp,
      healAmount: 0,
      counterDamage: 0,
    };
  }

  // Dodge check — passive dodge bonus applied
  const totalDodge = dodgeChance(defenderChar, stanceDef, config) + passivesDef.flatDodgeChance;
  const isDodge = rollPercent(rng) < Math.min(totalDodge, config.MAX_DODGE_CHANCE);

  if (isDodge) {
    return {
      turn: {
        turnNumber,
        attackerId: attackerChar.id,
        damage: 0,
        isCrit: false,
        isDodge: true,
        defenderHpAfter: defenderHp,
        targetZone: attackerZone,
        defendZone: defenderZone,
        ...(v2 ? { outcome: 'dodge' as const } : {}),
      },
      newDefenderHp: defenderHp,
      healAmount: 0,
      counterDamage: 0,
    };
  }

  // Try to use a skill
  const skill = selectSkill(attackerChar.equippedSkills ?? [], cooldownState);
  let raw: number;
  let dmgType: DamageType;
  let skillName: string | undefined;
  let skillKeyStr: string | undefined;

  if (skill) {
    putOnCooldown(cooldownState, skill, passivesAtk);

    // Self-buff skills do NOT deal damage — they apply an effect to the caster
    if (skill.targetType === 'self_buff') {
      let selfHeal = 0;
      const effect = skill.effectJson as Record<string, unknown> | null;
      if (effect && typeof effect.heal === 'number') {
        selfHeal = effect.heal;
      }

      return {
        turn: {
          turnNumber,
          attackerId: attackerChar.id,
          damage: 0,
          isCrit: false,
          isDodge: false,
          defenderHpAfter: defenderHp,
          skillUsed: skill.name,
          skillKey: skill.skillKey,
          damageType: skill.damageType,
          healAmount: selfHeal > 0 ? selfHeal : undefined,
          targetZone: attackerZone,
          defendZone: defenderZone,
        },
        newDefenderHp: defenderHp,
        healAmount: selfHeal,
        counterDamage: 0,
      };
    }

    const result = calculateSkillDamage(skill, attackerChar);
    raw = applyVariance(result.rawDamage, rng, config);
    dmgType = result.damageType;
    skillName = result.skillName;
    skillKeyStr = result.skillKey;
  } else {
    // Auto-attack fallback
    raw = applyVariance(baseDamage(attackerChar), rng, config);
    dmgType = getAutoAttackDamageType(attackerChar.class);
  }

  // Apply passive flat/percent damage bonuses
  raw += passivesAtk.flatDamage;
  raw *= 1 + passivesAtk.percentDamage / 100;

  // Resistance reduction
  const reduced = reduceDamageByType(raw, defenderChar, dmgType, config);
  const withClass = applyClassReduction(reduced, defenderChar.class, config);

  // Crit check — passive crit bonus applied
  const totalCrit = critChance(attackerChar, stanceAtk, config) + passivesAtk.flatCritChance;
  const critRoll = rollPercent(rng);
  let isCrit = critRoll < Math.min(totalCrit, config.MAX_CRIT_CHANCE);

  // Combat v2 — zone matrix (COMBAT_V2_DESIGN.md §3.1). Replaces the stance
  // offense/defense step. `blocked` = attack went into the defender's block,
  // unless legs opened the defender last round.
  let zoneMult = 1;
  let counterMult = 0;
  let opensDefender = false;
  let blocked = false;
  if (v2) {
    const atkZone: BodyZone = attackerZone === 'head' || attackerZone === 'legs' ? attackerZone : 'chest';
    blocked = !defenderOpened && attackerZone != null && attackerZone === defenderZone;
    const effect = zoneMatrixEffect(atkZone, blocked, zoneConfig(config));
    zoneMult = effect.mult;
    counterMult = effect.counterMult;
    opensDefender = effect.opens;
    if (atkZone === 'head') isCrit = effect.forcedCrit; // head never rolls: crit in the open, never into a block
  }

  let dmg = isCrit ? withClass * config.CRIT_MULTIPLIER : withClass;
  if (v2) {
    // Forced head crit replaces the multiplier instead of stacking on it.
    if (isCrit && attackerZone === 'head') dmg = withClass * zoneMult;
    else dmg = dmg * zoneMult;
  } else {
    // Stance modifiers (v1)
    dmg = dmg * (1 + stanceAtk.offense / 100);
    dmg = dmg * (1 - stanceDef.defense / 100);
  }

  // W3.D1 — CHA damage reduction removed. CHA now triggers a pre-hit miss roll
  // above (see `chaMissChance`). Stat kept useful without stacking two effects.

  // Defender's passive damage reduction
  if (passivesDef.damageReduction > 0) {
    dmg *= 1 - Math.min(passivesDef.damageReduction, 50) / 100;
  }

  // W3.D2 — Rogue Execute: +% damage vs low-HP defenders (thematic finisher).
  // Applied AFTER all mitigation so the bonus lands on the final floor damage.
  dmg = applyRogueExecute(dmg, attackerChar.class, defenderHp, defenderChar.maxHp, config);

  // Battle fatigue: after turn 10, +10% damage per additional turn (anti-stall)
  if (turnNumber > BATTLE_FATIGUE.FATIGUE_START_TURN) {
    const fatigueTurns = turnNumber - BATTLE_FATIGUE.FATIGUE_START_TURN;
    dmg *= 1 + (fatigueTurns * BATTLE_FATIGUE.FATIGUE_PERCENT_PER_TURN) / 100;
  }

  dmg = Math.max(Math.floor(dmg), config.MIN_DAMAGE);
  const newDefenderHp = Math.max(defenderHp - dmg, 0);

  // Lifesteal
  let healAmount = 0;
  if (passivesAtk.lifesteal > 0) {
    healAmount = Math.floor(dmg * passivesAtk.lifesteal / 100);
  }

  // Combat v2 — head into a block: the defender answers with a counter, sized
  // from THEIR auto-attack against the attacker's resists (no crit, no skills),
  // scaled by fatigue like everything else. Applied to the attacker's HP by the
  // caller (it owns both HP pools); reported here so the log can show it.
  let counterDamage = 0;
  if (v2 && counterMult > 0) {
    const counterRaw = baseDamage(defenderChar) * counterMult;
    let counter = reduceDamageByType(counterRaw, attackerChar, getAutoAttackDamageType(defenderChar.class), config);
    counter = applyClassReduction(counter, attackerChar.class, config);
    if (turnNumber > BATTLE_FATIGUE.FATIGUE_START_TURN) {
      counter *= 1 + ((turnNumber - BATTLE_FATIGUE.FATIGUE_START_TURN) * BATTLE_FATIGUE.FATIGUE_PERCENT_PER_TURN) / 100;
    }
    counterDamage = Math.max(Math.floor(counter), config.MIN_DAMAGE);
  }

  return {
    turn: {
      turnNumber,
      attackerId: attackerChar.id,
      damage: dmg,
      isCrit,
      isDodge: false,
      defenderHpAfter: newDefenderHp,
      skillUsed: skillName,
      skillKey: skillKeyStr,
      damageType: dmgType,
      healAmount: healAmount > 0 ? healAmount : undefined,
      targetZone: attackerZone,
      defendZone: defenderZone,
      ...(v2
        ? {
            outcome: (blocked ? 'blocked' : isCrit ? 'crit' : 'hit') as StrikeOutcome,
            ...(counterDamage > 0 ? { counterDamage } : {}),
            ...(opensDefender ? { opensDefender: true } : {}),
          }
        : {}),
    },
    newDefenderHp,
    healAmount,
    counterDamage,
  };
}

/**
 * Run a full turn-based combat between attacker and defender.
 *
 * Supports skill-based attacks and passive bonuses when present on CharacterStats.
 * Falls back to auto-attack when no skills are equipped (backward compatible).
 * Fetches live combat config from database with balance.ts as fallback.
 *
 * @param seed Optional 32-bit integer seed for deterministic combat.
 *             When provided, both server and client produce identical results.
 */
export async function runCombat(attacker: CharacterStats, defender: CharacterStats, seed?: number): Promise<CombatResult> {
  // Load class damage config and combat config once per combat
  await loadClassDamageConfig();
  const config = await getCombatConfig();

  const rng: SeededRng = seed != null ? createSeededRng(seed) : (() => Math.random());
  const hpA = attacker.currentHp ?? attacker.maxHp;
  const hpD = defender.currentHp ?? defender.maxHp;

  const turns: Turn[] = [];

  const zoneA = parseZoneStance(attacker.combatStance);
  const zoneD = parseZoneStance(defender.combatStance);
  const stanceA = computeStanceModifiers(zoneA, zoneD);
  const stanceD = computeStanceModifiers(zoneD, zoneA);
  const passivesA = attacker.passiveBonuses ?? emptyPassiveBonuses();
  const passivesD = defender.passiveBonuses ?? emptyPassiveBonuses();

  // Initialize cooldown states
  const cooldownA: SkillCooldownState = {};
  const cooldownD: SkillCooldownState = {};

  let first: CharacterStats;
  let second: CharacterStats;
  let stanceFirst: StanceModifiers;
  let stanceSecond: StanceModifiers;
  let passivesFirst: PassiveBonuses;
  let passivesSecond: PassiveBonuses;
  let cooldownFirst: SkillCooldownState;
  let cooldownSecond: SkillCooldownState;
  let hpFirst: number;
  let hpSecond: number;
  let maxHpFirst: number;
  let maxHpSecond: number;
  let zoneFirst: ParsedZoneStance;
  let zoneSecond: ParsedZoneStance;

  if (defender.agi > attacker.agi) {
    first = defender;
    second = attacker;
    stanceFirst = stanceD;
    stanceSecond = stanceA;
    passivesFirst = passivesD;
    passivesSecond = passivesA;
    cooldownFirst = cooldownD;
    cooldownSecond = cooldownA;
    hpFirst = hpD;
    hpSecond = hpA;
    maxHpFirst = defender.maxHp;
    maxHpSecond = attacker.maxHp;
    zoneFirst = zoneD;
    zoneSecond = zoneA;
  } else {
    first = attacker;
    second = defender;
    stanceFirst = stanceA;
    stanceSecond = stanceD;
    passivesFirst = passivesA;
    passivesSecond = passivesD;
    cooldownFirst = cooldownA;
    cooldownSecond = cooldownD;
    hpFirst = hpA;
    hpSecond = hpD;
    maxHpFirst = attacker.maxHp;
    maxHpSecond = defender.maxHp;
    zoneFirst = zoneA;
    zoneSecond = zoneD;
  }

  // Combat v2 — both sides play a zone POLICY every round (ghost / personality)
  // instead of a stance that rotates on a timer. Policies see last round's
  // exchange, so a turtle really does block where it was just hit.
  const v2 = isZoneMatrixV2(config);
  const policyFirst = first.zonePolicy ?? policyForCharacter(first.id, null);
  const policySecond = second.zonePolicy ?? policyForCharacter(second.id, null);
  let openedFirst = false;   // first's block does not apply this round (second landed legs)
  let openedSecond = false;
  let lastFirst: Turn | null = null;
  let lastSecond: Turn | null = null;

  for (let t = 1; t <= config.MAX_TURNS; t++) {
    if (v2) {
      const ctxFirst: ZoneRoundContext = {
        roundIndex: t - 1,
        myHpPct: hpFirst / maxHpFirst,
        oppHpPct: hpSecond / maxHpSecond,
        ...(lastFirst && lastSecond
          ? {
              last: {
                myAttack: zoneFirst.attack, myBlock: zoneFirst.defense,
                oppAttack: zoneSecond.attack, oppBlock: zoneSecond.defense,
                myStrikeBlocked: lastFirst.outcome === 'blocked',
                iTookCrit: lastSecond.isCrit,
                iLandedCrit: lastFirst.isCrit,
              },
            }
          : {}),
      };
      const ctxSecond: ZoneRoundContext = {
        roundIndex: t - 1,
        myHpPct: hpSecond / maxHpSecond,
        oppHpPct: hpFirst / maxHpFirst,
        ...(lastFirst && lastSecond
          ? {
              last: {
                myAttack: zoneSecond.attack, myBlock: zoneSecond.defense,
                oppAttack: zoneFirst.attack, oppBlock: zoneFirst.defense,
                myStrikeBlocked: lastSecond.outcome === 'blocked',
                iTookCrit: lastFirst.isCrit,
                iLandedCrit: lastSecond.isCrit,
              },
            }
          : {}),
      };
      const pickF = pickZones(policyFirst, ctxFirst, rng);
      const pickS = pickZones(policySecond, ctxSecond, rng);
      zoneFirst = { attack: pickF.attack, defense: pickF.block };
      zoneSecond = { attack: pickS.attack, defense: pickS.block };
      stanceFirst = ZERO_STANCE;
      stanceSecond = ZERO_STANCE;
    }

    // --- Mid-battle stance rotation (every 3 turns, v1 only) ---
    if (!v2 && t > 1 && (t - 1) % STANCE_ROTATION_INTERVAL === 0) {
      // Rotate zones: head→chest→legs→head
      const rotateZone = (z: BodyZone): BodyZone => {
        const idx = ZONE_CYCLE.indexOf(z);
        return ZONE_CYCLE[(idx + 1) % ZONE_CYCLE.length];
      };
      zoneFirst = { attack: rotateZone(zoneFirst.attack), defense: rotateZone(zoneFirst.defense) };
      zoneSecond = { attack: rotateZone(zoneSecond.attack), defense: rotateZone(zoneSecond.defense) };
      // Recompute stance modifiers with new zones
      stanceFirst = computeStanceModifiers(zoneFirst, zoneSecond);
      stanceSecond = computeStanceModifiers(zoneSecond, zoneFirst);
    }

    // --- First character attacks second ---
    // BUG-44/45/46 (QA 2026-04-10): if `first` is a passive target (Straw Dummy
    // went first because of agi), skip its swing. Defensive guard — with
    // `str/agi = 0` the dummy currently becomes `second`, but we don't want the
    // rule to silently break if a future tuning pass gives dummies speed.
    let openSecondNext = false;
    let openFirstNext = false;
    lastFirst = null;
    lastSecond = null;
    if (!first.isPassiveTarget) {
      const result = resolveAttack(
        t, first, second, hpSecond,
        stanceFirst, stanceSecond,
        passivesFirst, passivesSecond,
        cooldownFirst, rng,
        config,
        zoneFirst.attack,
        zoneSecond.defense,
        openedSecond,
      );
      turns.push(result.turn);
      lastFirst = result.turn;
      hpSecond = result.newDefenderHp;
      openSecondNext = result.turn.opensDefender === true;

      // Lifesteal heals the attacker
      if (result.healAmount > 0) {
        hpFirst = Math.min(hpFirst + result.healAmount, maxHpFirst);
      }
      // v2: head into a block — the defender's counter lands on the attacker
      if (result.counterDamage > 0) {
        hpFirst = Math.max(hpFirst - result.counterDamage, 0);
      }

      if (hpSecond <= 0) {
        return buildResult(first.id, second.id, turns, { [first.id]: hpFirst, [second.id]: 0 });
      }
      if (hpFirst <= 0) {
        return buildResult(second.id, first.id, turns, { [first.id]: 0, [second.id]: hpSecond });
      }
    }

    // --- Second character attacks first ---
    // BUG-44/45/46 (QA 2026-04-10): passive targets (Straw Dummy) never swing back.
    // Skip the counter-attack entirely so the player can practice combat on a
    // lifeless dummy without risk. They can still die to battle fatigue timeout
    // if they refuse to attack, but not from dummy damage.
    if (!second.isPassiveTarget) {
      const result = resolveAttack(
        t, second, first, hpFirst,
        stanceSecond, stanceFirst,
        passivesSecond, passivesFirst,
        cooldownSecond, rng,
        config,
        zoneSecond.attack,
        zoneFirst.defense,
        openedFirst,
      );
      turns.push(result.turn);
      lastSecond = result.turn;
      hpFirst = result.newDefenderHp;
      openFirstNext = result.turn.opensDefender === true;

      // Lifesteal heals the attacker
      if (result.healAmount > 0) {
        hpSecond = Math.min(hpSecond + result.healAmount, maxHpSecond);
      }
      if (result.counterDamage > 0) {
        hpSecond = Math.max(hpSecond - result.counterDamage, 0);
      }

      if (hpFirst <= 0) {
        return buildResult(second.id, first.id, turns, { [first.id]: 0, [second.id]: hpSecond });
      }
      if (hpSecond <= 0) {
        return buildResult(first.id, second.id, turns, { [first.id]: hpFirst, [second.id]: 0 });
      }
    }

    openedFirst = openFirstNext;
    openedSecond = openSecondNext;

    // Tick cooldowns after each turn pair
    tickCooldowns(cooldownFirst);
    tickCooldowns(cooldownSecond);
  }

  // --- Timeout: whoever has higher HP% wins ---
  const pctFirst = hpFirst / maxHpFirst;
  const pctSecond = hpSecond / maxHpSecond;

  if (pctFirst >= pctSecond) {
    return buildResult(first.id, second.id, turns, { [first.id]: hpFirst, [second.id]: hpSecond });
  } else {
    return buildResult(second.id, first.id, turns, { [first.id]: hpFirst, [second.id]: hpSecond });
  }
}

function buildResult(winnerId: string, loserId: string, turns: Turn[], finalHp: Record<string, number>): CombatResult {
  return {
    winnerId,
    loserId,
    turns,
    totalTurns: turns.length,
    finalHp,
  };
}

// ---------------------------------------------------------------------------
// Interactive Combat v1 — single-strike resolution (additive, feature-flagged)
//
// Used by POST /pvp/strike. Does NOT mutate DB, does NOT consume stamina, does
// NOT award rewards. It resolves ONE deterministic strike given attacker /
// defender zones and current HP, reusing the same `resolveAttack` pipeline
// that `runCombat` uses. The caller (iOS) owns the match state and calls us
// once per strike; when HP hits zero the caller finalizes via a later endpoint.
// ---------------------------------------------------------------------------

export interface SingleStrikeInput {
  attacker: CharacterStats;
  defender: CharacterStats;
  attackerZone: BodyZone;
  defenderZone: BodyZone;
  /**
   * Authoritative HP value the client believes the defender has right now.
   * Server clamps and uses it as the starting HP for this strike.
   */
  defenderHp: number;
  /** 32-bit seed (e.g. hash(matchId + strikeIndex)) for deterministic replay. */
  seed: number;
  /**
   * 1-based round number, for battle fatigue. `runCombat` passes its loop
   * index; interactive PvP used to pass a constant 1, so the anti-stall
   * mechanic (+10%/round after round 10) never fired in the one mode where
   * stalling is worst. Defaults to 1 for callers that have no round concept.
   */
  turn?: number;
  /**
   * Combat v2 — the defender was opened by a legs hit last round: their block
   * does not apply to this strike.
   */
  defenderOpened?: boolean;
  /**
   * Skill cooldowns for the ATTACKER, persisted by the caller across rounds
   * (D4: before this, every strike started with a fresh state and the first
   * equipped skill fired every round). Mutated in place when a skill fires.
   */
  cooldownState?: SkillCooldownState;
}

export interface SingleStrikeResult {
  turn: Turn;
  newDefenderHp: number;
  healAmount: number;
  /** Combat v2 — damage the defender dealt back (head into block). Caller applies it to the attacker. */
  counterDamage: number;
}

export async function resolveSingleStrike(input: SingleStrikeInput): Promise<SingleStrikeResult> {
  await loadClassDamageConfig();
  const config = await getCombatConfig();

  const rng = createSeededRng(input.seed);

  // Build stance modifiers from the zones provided for THIS strike, ignoring
  // whatever persisted stance the character rows may carry. Interactive combat
  // is zone-per-strike, not per-match.
  const atkStance: ParsedZoneStance = { attack: input.attackerZone, defense: input.attackerZone };
  const defStance: ParsedZoneStance = { attack: input.defenderZone, defense: input.defenderZone };
  const stanceAtk = computeStanceModifiers(atkStance, defStance);
  const stanceDef = computeStanceModifiers(defStance, atkStance);

  const passivesAtk = input.attacker.passiveBonuses ?? emptyPassiveBonuses();
  const passivesDef = input.defender.passiveBonuses ?? emptyPassiveBonuses();

  // Cooldowns: the caller (/pvp/strike) persists them per side per match and
  // ticks them once per round. A caller without one gets the legacy
  // fresh-state behaviour (used by tests and one-off previews only).
  const cooldownState: SkillCooldownState = input.cooldownState ?? {};

  const startHp = Math.max(0, Math.floor(input.defenderHp));

  return resolveAttack(
    Math.max(1, Math.floor(input.turn ?? 1)),
    input.attacker,
    input.defender,
    startHp,
    stanceAtk,
    stanceDef,
    passivesAtk,
    passivesDef,
    cooldownState,
    rng,
    config,
    input.attackerZone,
    input.defenderZone,
    input.defenderOpened === true,
  );
}
