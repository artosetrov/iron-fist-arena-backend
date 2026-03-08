// =============================================================================
// combat.ts — Turn-based combat engine
// =============================================================================

import { COMBAT } from './balance';

// --- Types ---

export type CharacterClassType = 'warrior' | 'rogue' | 'mage' | 'tank';

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
}

export interface Turn {
  turnNumber: number;
  attackerId: string;
  damage: number;
  isCrit: boolean;
  isDodge: boolean;
  defenderHpAfter: number;
}

export interface CombatResult {
  winnerId: string;
  loserId: string;
  turns: Turn[];
  totalTurns: number;
}

// --- Stance definitions ---

/**
 * Combat stances modify damage dealt, damage taken, crit, and dodge.
 * Format: { offense: number, defense: number, crit: number, dodge: number }
 * Values are additive percentages (e.g. offense: 10 means +10% damage).
 */
interface StanceModifiers {
  offense: number;  // % bonus to damage dealt
  defense: number;  // % reduction to damage taken
  crit: number;     // flat addition to crit chance
  dodge: number;    // flat addition to dodge chance
}

const DEFAULT_STANCE: StanceModifiers = { offense: 0, defense: 0, crit: 0, dodge: 0 };

function parseStance(combatStance: Record<string, unknown> | null | undefined): StanceModifiers {
  if (!combatStance) return DEFAULT_STANCE;
  return {
    offense: typeof combatStance.offense === 'number' ? combatStance.offense : 0,
    defense: typeof combatStance.defense === 'number' ? combatStance.defense : 0,
    crit: typeof combatStance.crit === 'number' ? combatStance.crit : 0,
    dodge: typeof combatStance.dodge === 'number' ? combatStance.dodge : 0,
  };
}

// --- Internal helpers ---

/**
 * Calculate base damage for a character based on their class.
 * - warrior:  str * 1.5 + level * 2
 * - tank:     str * 1.2 + level * 2  (lower damage, compensated by 15% damage reduction)
 * - rogue:    agi * 1.5 + level * 2
 * - mage:     int * 1.5 + level * 2
 */
function baseDamage(c: CharacterStats): number {
  switch (c.class) {
    case 'warrior':
      return c.str * 1.5 + c.level * 2;
    case 'tank':
      return c.str * 1.2 + c.level * 2;
    case 'rogue':
      return c.agi * 1.5 + c.level * 2;
    case 'mage':
      return c.int * 1.5 + c.level * 2;
    default:
      return c.str * 1.5 + c.level * 2;
  }
}

/**
 * Whether this class deals magic damage (uses magicResist) or physical (uses armor).
 */
function isMagicDamage(cls: CharacterClassType): boolean {
  return cls === 'mage';
}

/**
 * Apply damage reduction.
 * physical: damage * (100 / (100 + armor))
 * magical:  damage * (100 / (100 + magicResist))
 */
function reduceDamage(raw: number, defender: CharacterStats, attackerClass: CharacterClassType): number {
  const resist = isMagicDamage(attackerClass) ? defender.magicResist : defender.armor;
  return raw * (100 / (100 + resist));
}

/**
 * Tank class damage reduction: takes 15% less damage from all sources.
 */
function applyClassReduction(damage: number, defenderClass: CharacterClassType): number {
  if (defenderClass === 'tank') {
    return damage * COMBAT.TANK_DAMAGE_REDUCTION;
  }
  return damage;
}

/**
 * Crit chance = min(luk * 0.5 + agi * 0.3, MAX_CRIT_CHANCE)%
 */
function critChance(c: CharacterStats, stanceMod: StanceModifiers): number {
  return Math.min(c.luk * 0.5 + c.agi * 0.3 + stanceMod.crit, COMBAT.MAX_CRIT_CHANCE);
}

/**
 * Dodge chance = min(agi * 0.3, MAX_DODGE_CHANCE)%
 * Rogues get a class bonus to dodge.
 */
function dodgeChance(defender: CharacterStats, stanceMod: StanceModifiers): number {
  const classBonus = defender.class === 'rogue' ? COMBAT.ROGUE_DODGE_BONUS : 0;
  return Math.min(defender.agi * 0.3 + classBonus + stanceMod.dodge, COMBAT.MAX_DODGE_CHANCE);
}

/**
 * Apply damage variance: ±10% randomness to base damage.
 */
function applyVariance(damage: number): number {
  const variance = COMBAT.DAMAGE_VARIANCE;
  const multiplier = (1 - variance) + Math.random() * (variance * 2);
  return damage * multiplier;
}

function rollPercent(): number {
  return Math.random() * 100;
}

// --- Main combat function ---

/**
 * Run a full turn-based combat between attacker and defender.
 *
 * - AGI determines turn order (higher AGI acts first).
 * - Each turn the acting character attempts to damage the other.
 * - Defender may dodge based on AGI (rogues get a bonus).
 * - On hit, damage has ±10% variance, can crit for 1.5x.
 * - Tanks take 15% less damage from all sources.
 * - Combat stances modify offense/defense/crit/dodge.
 * - Combat ends when one side reaches 0 HP or after MAX_TURNS.
 * - At timeout, whoever has a higher HP% wins.
 */
export function runCombat(attacker: CharacterStats, defender: CharacterStats): CombatResult {
  // Clone HP pools so we don't mutate the originals
  let hpA = attacker.maxHp;
  let hpD = defender.maxHp;

  const turns: Turn[] = [];

  // Parse stance modifiers
  const stanceA = parseStance(attacker.combatStance);
  const stanceD = parseStance(defender.combatStance);

  // Determine order: higher AGI acts first. Ties favour the attacker.
  let first: CharacterStats;
  let second: CharacterStats;
  let stanceFirst: StanceModifiers;
  let stanceSecond: StanceModifiers;
  let hpFirst: number;
  let hpSecond: number;
  let maxHpFirst: number;
  let maxHpSecond: number;

  if (defender.agi > attacker.agi) {
    first = defender;
    second = attacker;
    stanceFirst = stanceD;
    stanceSecond = stanceA;
    hpFirst = hpD;
    hpSecond = hpA;
    maxHpFirst = defender.maxHp;
    maxHpSecond = attacker.maxHp;
  } else {
    first = attacker;
    second = defender;
    stanceFirst = stanceA;
    stanceSecond = stanceD;
    hpFirst = hpA;
    hpSecond = hpD;
    maxHpFirst = attacker.maxHp;
    maxHpSecond = defender.maxHp;
  }

  for (let t = 1; t <= COMBAT.MAX_TURNS; t++) {
    // --- First character attacks second ---
    {
      // Check dodge
      const isDodge = rollPercent() < dodgeChance(second, stanceSecond);

      if (isDodge) {
        turns.push({
          turnNumber: t,
          attackerId: first.id,
          damage: 0,
          isCrit: false,
          isDodge: true,
          defenderHpAfter: hpSecond,
        });
      } else {
        const raw = applyVariance(baseDamage(first));
        const reduced = reduceDamage(raw, second, first.class);
        const withClass = applyClassReduction(reduced, second.class);
        const isCrit = rollPercent() < critChance(first, stanceFirst);
        let dmg = isCrit ? withClass * COMBAT.CRIT_MULTIPLIER : withClass;
        // Apply stance offense bonus
        dmg = dmg * (1 + stanceFirst.offense / 100);
        // Apply stance defense bonus of defender
        dmg = dmg * (1 - stanceSecond.defense / 100);
        dmg = Math.max(Math.floor(dmg), COMBAT.MIN_DAMAGE);
        hpSecond = Math.max(hpSecond - dmg, 0);

        turns.push({
          turnNumber: t,
          attackerId: first.id,
          damage: dmg,
          isCrit,
          isDodge: false,
          defenderHpAfter: hpSecond,
        });
      }

      if (hpSecond <= 0) {
        return buildResult(first.id, second.id, turns);
      }
    }

    // --- Second character attacks first ---
    {
      const isDodge = rollPercent() < dodgeChance(first, stanceFirst);

      if (isDodge) {
        turns.push({
          turnNumber: t,
          attackerId: second.id,
          damage: 0,
          isCrit: false,
          isDodge: true,
          defenderHpAfter: hpFirst,
        });
      } else {
        const raw = applyVariance(baseDamage(second));
        const reduced = reduceDamage(raw, first, second.class);
        const withClass = applyClassReduction(reduced, first.class);
        const isCrit = rollPercent() < critChance(second, stanceSecond);
        let dmg = isCrit ? withClass * COMBAT.CRIT_MULTIPLIER : withClass;
        dmg = dmg * (1 + stanceSecond.offense / 100);
        dmg = dmg * (1 - stanceFirst.defense / 100);
        dmg = Math.max(Math.floor(dmg), COMBAT.MIN_DAMAGE);
        hpFirst = Math.max(hpFirst - dmg, 0);

        turns.push({
          turnNumber: t,
          attackerId: second.id,
          damage: dmg,
          isCrit,
          isDodge: false,
          defenderHpAfter: hpFirst,
        });
      }

      if (hpFirst <= 0) {
        return buildResult(second.id, first.id, turns);
      }
    }
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
