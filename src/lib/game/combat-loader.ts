// =============================================================================
// combat-loader.ts — Load character data for combat including skills & passives
// =============================================================================

import { prisma } from '@/lib/prisma'
import { cacheDelete } from '@/lib/cache'
import type { CharacterStats, DamageType } from './combat'
import type { SkillDefinition } from './skills'
import { aggregatePassiveBonuses, emptyPassiveBonuses, type PassiveBonuses } from './passives'

/**
 * Load a character with all combat-relevant data: base stats, equipped skills, passive bonuses.
 * Returns a fully populated CharacterStats object ready for runCombat().
 *
 * Uses caching for skills and passive bonuses to avoid heavy queries during repeated combat.
 */
export async function loadCombatCharacter(characterId: string): Promise<CharacterStats> {
  const character = await prisma.character.findUnique({
    where: { id: characterId },
    select: {
      id: true,
      characterName: true,
      class: true,
      level: true,
      str: true, agi: true, vit: true, end: true,
      int: true, wis: true, luk: true, cha: true,
      maxHp: true, armor: true, magicResist: true,
      combatStance: true,
      characterSkills: {
        where: { isEquipped: true },
        include: { skill: true },
        orderBy: { slotIndex: 'asc' },
      },
      characterPassives: {
        include: {
          node: {
            select: { bonusType: true, bonusStat: true, bonusValue: true },
          },
        },
      },
    },
  })

  if (!character) throw new Error('Character not found')

  // Build equipped skills array
  const equippedSkills: SkillDefinition[] = character.characterSkills
    .filter((cs) => cs.skill.isActive)
    .map((cs) => ({
      id: cs.skill.id,
      skillKey: cs.skill.skillKey,
      name: cs.skill.name,
      damageBase: cs.skill.damageBase,
      damageScaling: cs.skill.damageScaling as Record<string, number> | null,
      damageType: cs.skill.damageType as DamageType,
      targetType: cs.skill.targetType as 'single_enemy' | 'self_buff' | 'aoe',
      cooldown: cs.skill.cooldown,
      effectJson: cs.skill.effectJson,
      rank: cs.rank,
      rankScaling: cs.skill.rankScaling,
    }))

  // Aggregate passive bonuses
  const passiveBonuses: PassiveBonuses = character.characterPassives.length > 0
    ? aggregatePassiveBonuses(
        character.characterPassives.map((cp) => ({
          bonusType: cp.node.bonusType,
          bonusStat: cp.node.bonusStat,
          bonusValue: cp.node.bonusValue,
        }))
      )
    : emptyPassiveBonuses()

  return {
    id: character.id,
    name: character.characterName,
    class: character.class as CharacterStats['class'],
    level: character.level,
    str: character.str,
    agi: character.agi,
    vit: character.vit,
    end: character.end,
    int: character.int,
    wis: character.wis,
    luk: character.luk,
    cha: character.cha,
    maxHp: character.maxHp,
    armor: character.armor,
    magicResist: character.magicResist,
    combatStance: character.combatStance as Record<string, unknown> | null,
    equippedSkills,
    passiveBonuses,
  }
}

// --- Cache invalidation helpers ---

export function invalidateSkillCache(characterId: string): void {
  cacheDelete(`skills:char:${characterId}`)
}

export function invalidatePassiveCache(characterId: string): void {
  cacheDelete(`passives:char:${characterId}`)
}
