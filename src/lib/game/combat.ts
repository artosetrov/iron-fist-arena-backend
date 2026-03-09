// =============================================================================
// combat.ts — Turn-based combat engine
// baseDamage now reads class scaling from GameConfig via item-balance engine.
// =============================================================================

import { COMBAT } from './balance';
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
  armor: number;
  magicResist: number;
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
}

export interface CombatResult {
  winnerId: string;
  loserId: string;
  turns: Turn[];
  totalTurns: number;
}

// --- Stance definitions ---

interface StanceModifiers {
  offense: number;
  defense: number;
  crit: number;
  dodge: number;
}

const DEFAULT_STANCE: StanceModifiers = { offense: 0, defense: 0, crit: 0, dodge: 0 };

function parseStance(combatStance: Record<string, unknown> | null | undefined): StanceModifiers {
  if (!combatStance) return DEFAULT_STANCE;
  return {
    offense: Math.min(100, Math.max(0, typeof combatStance.offense === 'number' ? combatStance.offense : 0)),
    defense: Math.min(100, Math.max(0, typeof combatStance.defense === 'number' ? combatStance.defense : 0)),
    crit: typeof combatStance.crit === 'number' ? combatStance.crit : 0,
    dodge: typeof combatStance.dodge === 'number' ? combatStance.dodge : 0,
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
    if (c.class === 'mage') dmg += c.wis * 0.5;
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
      return c.int * 1.2 + c.wis * 0.5 + c.level * 2;
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

function reduceDamageByType(
  raw: number,
  defender: CharacterStats,
  damageType: DamageType,
): number {
  if (damageType === 'true_damage') return raw;
  if (damageType === 'poison') {
    const effectiveArmor = Math.max(0, defender.armor) * (1 - COMBAT.POISON_ARMOR_PENETRATION);
    return raw * (100 / (100 + effectiveArmor));
  }
  const resist = damageType === 'magical' ? defender.magicResist : defender.armor;
  const effectiveResist = Math.max(0, resist);
  return raw * (100 / (100 + effectiveResist));
}

function applyClassReduction(damage: number, defenderClass: CharacterClassType): number {
  if (defenderClass === 'tank') {
    return damage * COMBAT.TANK_DAMAGE_REDUCTION;
  }
  return damage;
}

function critChance(c: CharacterStats, stanceMod: StanceModifiers): number {
  return Math.min(
    c.luk * COMBAT.CRIT_PER_LUK + c.agi * COMBAT.CRIT_PER_AGI + stanceMod.crit,
    COMBAT.MAX_CRIT_CHANCE,
  );
}

function dodgeChance(defender: CharacterStats, stanceMod: StanceModifiers): number {
  const classBonus = defender.class === 'rogue' ? COMBAT.ROGUE_DODGE_BONUS : 0;
  return Math.min(
    defender.agi * COMBAT.DODGE_PER_AGI + defender.luk * COMBAT.DODGE_PER_LUK + classBonus + stanceMod.dodge,
    COMBAT.MAX_DODGE_CHANCE,
  );
}

/** CHA intimidation: attacker's CHA reduces defender's outgoing damage. */
function chaIntimidation(attackerCha: number): number {
  return Math.min(attackerCha * COMBAT.CHA_INTIMIDATION_PER_POINT, COMBAT.CHA_INTIMIDATION_CAP) / 100;
}

function applyVariance(damage: number, rng: SeededRng): number {
  const variance = COMBAT.DAMAGE_VARIANCE;
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
): { turn: Turn; newDefenderHp: number; healAmount: number } {
  // Dodge check — passive dodge bonus applied
  const totalDodge = dodgeChance(defenderChar, stanceDef) + passivesDef.flatDodgeChance;
  const isDodge = rollPercent(rng) < Math.min(totalDodge, COMBAT.MAX_DODGE_CHANCE);

  if (isDodge) {
    return {
      turn: {
        turnNumber,
        attackerId: attackerChar.id,
        damage: 0,
        isCrit: false,
        isDodge: true,
        defenderHpAfter: defenderHp,
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
        },
        newDefenderHp: defenderHp,
        healAmount: selfHeal,
      };
    }

    const result = calculateSkillDamage(skill, attackerChar);
    raw = applyVariance(result.rawDamage, rng);
    dmgType = result.damageType;
    skillName = result.skillName;
    skillKeyStr = result.skillKey;
  } else {
    // Auto-attack fallback
    raw = applyVariance(baseDamage(attackerChar), rng);
    dmgType = getAutoAttackDamageType(attackerChar.class);
  }

  // Apply passive flat/percent damage bonuses
  raw += passivesAtk.flatDamage;
  raw *= 1 + passivesAtk.percentDamage / 100;

  // Resistance reduction
  const reduced = reduceDamageByType(raw, defenderChar, dmgType);
  const withClass = applyClassReduction(reduced, defenderChar.class);

  // Crit check — passive crit bonus applied
  const totalCrit = critChance(attackerChar, stanceAtk) + passivesAtk.flatCritChance;
  const isCrit = rollPercent(rng) < Math.min(totalCrit, COMBAT.MAX_CRIT_CHANCE);
  let dmg = isCrit ? withClass * COMBAT.CRIT_MULTIPLIER : withClass;

  // Stance modifiers
  dmg = dmg * (1 + stanceAtk.offense / 100);
  dmg = dmg * (1 - stanceDef.defense / 100);

  // CHA intimidation: defender's CHA reduces attacker's damage
  const intimReduction = chaIntimidation(defenderChar.cha);
  if (intimReduction > 0) {
    dmg *= 1 - intimReduction;
  }

  // Defender's passive damage reduction
  if (passivesDef.damageReduction > 0) {
    dmg *= 1 - Math.min(passivesDef.damageReduction, 50) / 100;
  }

  dmg = Math.max(Math.floor(dmg), COMBAT.MIN_DAMAGE);
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
    },
    newDefenderHp,
    healAmount,
  };
}

/**
 * Run a full turn-based combat between attacker and defender.
 * NOTE: Call initCombatConfig() once before calling this in API routes.
 *
 * Supports skill-based attacks and passive bonuses when present on CharacterStats.
 * Falls back to auto-attack when no skills are equipped (backward compatible).
 *
 * @param seed Optional 32-bit integer seed for deterministic combat.
 *             When provided, both server and client produce identical results.
 */
export function runCombat(attacker: CharacterStats, defender: CharacterStats, seed?: number): CombatResult {
  const rng: SeededRng = seed != null ? createSeededRng(seed) : (() => Math.random());
  let hpA = attacker.maxHp;
  let hpD = defender.maxHp;

  const turns: Turn[] = [];

  const stanceA = parseStance(attacker.combatStance);
  const stanceD = parseStance(defender.combatStance);
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
  }

  for (let t = 1; t <= COMBAT.MAX_TURNS; t++) {
    // --- First character attacks second ---
    {
      const result = resolveAttack(
        t, first, second, hpSecond,
        stanceFirst, stanceSecond,
        passivesFirst, passivesSecond,
        cooldownFirst, rng,
      );
      turns.push(result.turn);
      hpSecond = result.newDefenderHp;

      // Lifesteal heals the attacker
      if (result.healAmount > 0) {
        hpFirst = Math.min(hpFirst + result.healAmount, maxHpFirst);
      }

      if (hpSecond <= 0) {
        return buildResult(first.id, second.id, turns);
      }
    }

    // --- Second character attacks first ---
    {
      const result = resolveAttack(
        t, second, first, hpFirst,
        stanceSecond, stanceFirst,
        passivesSecond, passivesFirst,
        cooldownSecond, rng,
      );
      turns.push(result.turn);
      hpFirst = result.newDefenderHp;

      // Lifesteal heals the attacker
      if (result.healAmount > 0) {
        hpSecond = Math.min(hpSecond + result.healAmount, maxHpSecond);
      }

      if (hpFirst <= 0) {
        return buildResult(second.id, first.id, turns);
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
    return buildResult(first.id, second.id, turns);
  } else {
    return buildResult(second.id, first.id, turns);
  }
}

function buildResult(winnerId: string, loserId: string, turns: Turn[]): CombatResult {
  return {
    winnerId,
    loserId,
    turns,
    totalTurns: turns.length,
  };
}
