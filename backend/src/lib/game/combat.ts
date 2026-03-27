// =============================================================================
// combat.ts — Turn-based combat engine
// baseDamage now reads class scaling from GameConfig via item-balance engine.
// =============================================================================

import { COMBAT, STANCE_ZONES, BATTLE_FATIGUE, type BodyZone } from './balance';
import { getCombatConfig } from './live-config';
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
}

export interface Turn {
  turnNumber: number;
  attackerId: string;
  damage: number;
  isCrit: boolean;
  isDodge: boolean;
  defenderHpAfter: number;
  skillUsed?: string;
  skillKey?: string;
  damageType?: DamageType;
  healAmount?: number;
  targetZone?: string;
  defendZone?: string;
  stanceSwitch?: boolean; // True if stance was auto-rotated this turn
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

// Cached class damage config (loaded once per combat call)
let _cachedClassDamage: Record<string, { stat: string; multiplier: number; levelBonus: number }> | null = null;

/**
 * Pre-load class damage config so we don't hit DB per turn.
 * Called once at the start of runCombat.
 */
async function loadClassDamageConfig(): Promise<void> {
  const classes = ['warrior', 'tank', 'rogue', 'mage'];
  _cachedClassDamage = {};
  for (const cls of classes) {
    _cachedClassDamage[cls] = await getClassDamageFormula(cls);
  }
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
  CHA_INTIMIDATION_PER_POINT: number;
  CHA_INTIMIDATION_CAP: number;
}

// Cached combat config
let _cachedCombatConfig: CombatConfigData | null = null;

function reduceDamageByType(
  raw: number,
  defender: CharacterStats,
  damageType: DamageType,
  config: CombatConfigData,
): number {
  if (damageType === 'true_damage') return raw;
  if (damageType === 'poison') {
    const effectiveArmor = Math.max(0, defender.armor) * (1 - config.POISON_ARMOR_PENETRATION);
    return raw * (100 / (100 + effectiveArmor));
  }
  const resist = damageType === 'magical' ? defender.magicResist : defender.armor;
  const effectiveResist = Math.max(0, resist);
  return raw * (100 / (100 + effectiveResist));
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

/** CHA intimidation: attacker's CHA reduces defender's outgoing damage. */
function chaIntimidation(attackerCha: number, config: CombatConfigData): number {
  return Math.min(attackerCha * config.CHA_INTIMIDATION_PER_POINT, config.CHA_INTIMIDATION_CAP) / 100;
}

function applyVariance(damage: number, rng: SeededRng, config: CombatConfigData): number {
  const variance = config.DAMAGE_VARIANCE;
  const multiplier = (1 - variance) + rng() * (variance * 2);
  return damage * multiplier;
}

function rollPercent(rng: SeededRng): number {
  return rng() * 100;
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
): { turn: Turn; newDefenderHp: number; healAmount: number } {
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
      },
      newDefenderHp: defenderHp,
      healAmount: 0,
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
  const isCrit = rollPercent(rng) < Math.min(totalCrit, config.MAX_CRIT_CHANCE);
  let dmg = isCrit ? withClass * config.CRIT_MULTIPLIER : withClass;

  // Stance modifiers
  dmg = dmg * (1 + stanceAtk.offense / 100);
  dmg = dmg * (1 - stanceDef.defense / 100);

  // CHA intimidation: defender's CHA reduces attacker's damage
  const intimReduction = chaIntimidation(defenderChar.cha, config);
  if (intimReduction > 0) {
    dmg *= 1 - intimReduction;
  }

  // Defender's passive damage reduction
  if (passivesDef.damageReduction > 0) {
    dmg *= 1 - Math.min(passivesDef.damageReduction, 50) / 100;
  }

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
    },
    newDefenderHp,
    healAmount,
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
  _cachedCombatConfig = config;

  const rng: SeededRng = seed != null ? createSeededRng(seed) : (() => Math.random());
  let hpA = attacker.currentHp ?? attacker.maxHp;
  let hpD = defender.currentHp ?? defender.maxHp;

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

  for (let t = 1; t <= config.MAX_TURNS; t++) {
    // --- Mid-battle stance rotation (every 3 turns) ---
    let stanceSwitched = false;
    if (t > 1 && (t - 1) % STANCE_ROTATION_INTERVAL === 0) {
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
      stanceSwitched = true;
    }

    // --- First character attacks second ---
    {
      const result = resolveAttack(
        t, first, second, hpSecond,
        stanceFirst, stanceSecond,
        passivesFirst, passivesSecond,
        cooldownFirst, rng,
        config,
        zoneFirst.attack,
        zoneSecond.defense,
      );
      turns.push(result.turn);
      hpSecond = result.newDefenderHp;

      // Lifesteal heals the attacker
      if (result.healAmount > 0) {
        hpFirst = Math.min(hpFirst + result.healAmount, maxHpFirst);
      }

      if (hpSecond <= 0) {
        return buildResult(first.id, second.id, turns, { [first.id]: hpFirst, [second.id]: 0 });
      }
    }

    // --- Second character attacks first ---
    {
      const result = resolveAttack(
        t, second, first, hpFirst,
        stanceSecond, stanceFirst,
        passivesSecond, passivesFirst,
        cooldownSecond, rng,
        config,
        zoneSecond.attack,
        zoneFirst.defense,
      );
      turns.push(result.turn);
      hpFirst = result.newDefenderHp;

      // Lifesteal heals the attacker
      if (result.healAmount > 0) {
        hpSecond = Math.min(hpSecond + result.healAmount, maxHpSecond);
      }

      if (hpFirst <= 0) {
        return buildResult(second.id, first.id, turns, { [first.id]: 0, [second.id]: hpSecond });
      }
    }

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
