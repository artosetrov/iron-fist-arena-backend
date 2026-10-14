// =============================================================================
// class-compat.ts — which classRestriction values a class may use.
//
// One matrix for loot (loot.ts), equip (/api/inventory/equip) and the shop
// listing (/api/shop/items). Before 2026-10-14 loot used this matrix while
// equip and shop compared the exact class string, which did not matter only
// because no item had a classRestriction. Now weapons do.
//
// Rationale: warrior and tank are both str/vit melee classes and share
// weapons; rogue (agi) and mage (int) gear carries no value for anyone else.
// NULL / empty classRestriction is universal.
// =============================================================================

import type { CharacterClass } from '@prisma/client'

export const CLASS_COMPAT: Record<CharacterClass, CharacterClass[]> = {
  warrior: ['warrior', 'tank'],
  tank: ['warrior', 'tank'],
  rogue: ['rogue'],
  mage: ['mage'],
}

/** classRestriction values a character of `characterClass` may wear (never empty). */
export function wearableRestrictions(characterClass: CharacterClass | string): string[] {
  const compat = CLASS_COMPAT[characterClass as CharacterClass]
  return compat ? [...compat] : [String(characterClass)]
}

export function canClassWear(
  characterClass: CharacterClass | string,
  classRestriction: string | null | undefined,
): boolean {
  const restriction = classRestriction?.trim().toLowerCase()
  if (!restriction) return true
  return wearableRestrictions(characterClass).includes(restriction)
}
