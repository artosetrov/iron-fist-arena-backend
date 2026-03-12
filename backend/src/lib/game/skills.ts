// =============================================================================
// skills.ts — Skill selection and damage calculation for combat
// =============================================================================

import type { CharacterStats, DamageType } from './combat'
import type { PassiveBonuses } from './passives'

// --- Types ---

export interface SkillDefinition {
  id: string
  skillKey: string
  name: string
  damageBase: number
  damageScaling: Record<string, number> | null // e.g. { "int": 1.8, "wis": 0.5 }
  damageType: DamageType
  targetType: 'single_enemy' | 'self_buff' | 'aoe'
  cooldown: number // turns to wait before reuse (0 = usable every turn)
  effectJson: unknown
  rank: number
  rankScaling: number // e.g. 0.1 = +10% per rank above 1
}

export interface SkillCooldownState {
  [skillId: string]: number // turns remaining until available
}

export interface SkillDamageResult {
  rawDamage: number
  damageType: DamageType
  skillName: string
  skillKey: string
}

// --- Skill Selection ---

/**
 * Select the best available skill for this turn.
 * Skills are ordered by slot index (implicit via array order).
 * Picks the first skill whose cooldown is 0 (ready to use).
 *
 * @returns The skill to use, or null if all are on cooldown (auto-attack fallback).
 */
export function selectSkill(
  equippedSkills: SkillDefinition[],
  cooldownState: SkillCooldownState,
): SkillDefinition | null {
  if (!equippedSkills || equippedSkills.length === 0) return null

  for (const skill of equippedSkills) {
    const remaining = cooldownState[skill.id] ?? 0
    if (remaining <= 0) {
      return skill
    }
  }

  return null // All on cooldown — auto-attack
}

// --- Skill Damage Calculation ---

/**
 * Calculate raw damage for a skill.
 *
 * Formula:
 *   baseDamage = skill.damageBase + sum(characterStat * scalingCoefficient)
 *   rankMultiplier = 1 + (rank - 1) * rankScaling
 *   rawDamage = baseDamage * rankMultiplier
 *
 * The caller applies variance, crit, resistance, and class reduction separately.
 */
export function calculateSkillDamage(
  skill: SkillDefinition,
  attacker: CharacterStats,
): SkillDamageResult {
  // Base damage from the skill itself
  let damage = skill.damageBase

  // Add scaling from character stats
  if (skill.damageScaling) {
    const statMap: Record<string, number> = {
      str: attacker.str,
      agi: attacker.agi,
      vit: attacker.vit,
      end: attacker.end,
      int: attacker.int,
      wis: attacker.wis,
      luk: attacker.luk,
      cha: attacker.cha,
    }

    for (const [stat, coefficient] of Object.entries(skill.damageScaling)) {
      const statValue = statMap[stat]
      if (typeof statValue === 'number' && typeof coefficient === 'number') {
        damage += statValue * coefficient
      }
    }
  }

  // Apply rank scaling: each rank above 1 adds rankScaling % bonus
  const rankMultiplier = 1 + (skill.rank - 1) * (skill.rankScaling ?? 0)
  damage = damage * rankMultiplier

  return {
    rawDamage: Math.max(damage, 1),
    damageType: skill.damageType,
    skillName: skill.name,
    skillKey: skill.skillKey,
  }
}

// --- Cooldown Management ---

/**
 * Put a skill on cooldown after it was used.
 * Applies cooldown reduction from passive bonuses (percentage reduction, min 1 turn).
 */
export function putOnCooldown(
  state: SkillCooldownState,
  skill: SkillDefinition,
  passives?: PassiveBonuses,
): void {
  if (skill.cooldown > 0) {
    const cdr = passives?.cooldownReduction ?? 0
    const reduced = Math.max(1, Math.ceil(skill.cooldown * (1 - cdr / 100)))
    state[skill.id] = reduced
  }
}

/**
 * Advance all cooldowns by 1 turn. Call after each full turn pair.
 */
export function tickCooldowns(state: SkillCooldownState): void {
  for (const skillId of Object.keys(state)) {
    if (state[skillId] > 0) {
      state[skillId]--
    }
  }
}
