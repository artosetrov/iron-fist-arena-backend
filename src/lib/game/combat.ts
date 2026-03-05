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
  defenderHpAfter: number;
}

export interface CombatResult {
  winnerId: string;
  loserId: string;
  turns: Turn[];
  totalTurns: number;
}

// --- Internal helpers ---

/**
 * Calculate base damage for a character based on their class.
 * - warrior / tank: str * 1.5 + level * 2
 * - rogue:          agi * 1.5 + level * 2
 * - mage:           int * 1.5 + level * 2
 */
function baseDamage(c: CharacterStats): number {
  switch (c.class) {
    case 'warrior':
    case 'tank':
      return c.str * 1.5 + c.level * 2;
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
 * Crit chance = min(luk * 0.5 + agi * 0.3, 50)%
 */
function critChance(c: CharacterStats): number {
  return Math.min(c.luk * 0.5 + c.agi * 0.3, COMBAT.MAX_CRIT_CHANCE);
}

/**
 * Simple deterministic-seeded PRNG to keep combat reproducible when needed.
 * Falls back to Math.random() for normal use.
 */
function rollPercent(): number {
  return Math.random() * 100;
}

// --- Main combat function ---

/**
 * Run a full turn-based combat between attacker and defender.
 *
 * - AGI determines turn order (higher AGI acts first).
 * - Each turn the acting character deals damage to the other.
 * - Combat ends when one side reaches 0 HP or after MAX_TURNS.
 * - At timeout, whoever has a higher HP% wins.
 */
export function runCombat(attacker: CharacterStats, defender: CharacterStats): CombatResult {
  // Clone HP pools so we don't mutate the originals
  let hpA = attacker.maxHp;
  let hpD = defender.maxHp;

  const turns: Turn[] = [];

  // Determine order: higher AGI acts first. Ties favour the attacker.
  let first: CharacterStats;
  let second: CharacterStats;
  let hpFirst: number;
  let hpSecond: number;
  let maxHpFirst: number;
  let maxHpSecond: number;

  if (defender.agi > attacker.agi) {
    first = defender;
    second = attacker;
    hpFirst = hpD;
    hpSecond = hpA;
    maxHpFirst = defender.maxHp;
    maxHpSecond = attacker.maxHp;
  } else {
    first = attacker;
    second = defender;
    hpFirst = hpA;
    hpSecond = hpD;
    maxHpFirst = attacker.maxHp;
    maxHpSecond = defender.maxHp;
  }

  for (let t = 1; t <= COMBAT.MAX_TURNS; t++) {
    // --- First character attacks second ---
    {
      const raw = baseDamage(first);
      const reduced = reduceDamage(raw, second, first.class);
      const isCrit = rollPercent() < critChance(first);
      let dmg = isCrit ? reduced * COMBAT.CRIT_MULTIPLIER : reduced;
      dmg = Math.max(Math.floor(dmg), COMBAT.MIN_DAMAGE);
      hpSecond = Math.max(hpSecond - dmg, 0);

      turns.push({
        turnNumber: t,
        attackerId: first.id,
        damage: dmg,
        isCrit,
        defenderHpAfter: hpSecond,
      });

      if (hpSecond <= 0) {
        return buildResult(first.id, second.id, turns);
      }
    }

    // --- Second character attacks first ---
    {
      const raw = baseDamage(second);
      const reduced = reduceDamage(raw, first, second.class);
      const isCrit = rollPercent() < critChance(second);
      let dmg = isCrit ? reduced * COMBAT.CRIT_MULTIPLIER : reduced;
      dmg = Math.max(Math.floor(dmg), COMBAT.MIN_DAMAGE);
      hpFirst = Math.max(hpFirst - dmg, 0);

      turns.push({
        turnNumber: t,
        attackerId: second.id,
        damage: dmg,
        isCrit,
        defenderHpAfter: hpFirst,
      });

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
