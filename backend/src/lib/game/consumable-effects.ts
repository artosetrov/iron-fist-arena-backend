import { ConsumableType } from '@prisma/client'
import { getGameConfig } from '@/lib/game/config'

// Interactive Combat v1 — Phase 4.B
// Shared source of truth for consumable heal/stamina magnitudes. Used by:
//   - POST /api/consumables/use           (out-of-combat potion use)
//   - POST /api/pvp/strike                (in-combat Active Slot fire)
//   - POST /api/pvp/match/start           (magnitude snapshot at match start)
//
// Kept in one place so balance tweaks via GameConfig keys (consumable.hp_restore_percent.*,
// consumable.stamina_restore.*) propagate to both in-combat and out-of-combat paths.

export const STAMINA_POTION_TYPES = new Set<ConsumableType>([
  'stamina_potion_small',
  'stamina_potion_medium',
  'stamina_potion_large',
])

export const HEALTH_POTION_TYPES = new Set<ConsumableType>([
  'health_potion_small',
  'health_potion_medium',
  'health_potion_large',
])

export function isStaminaPotion(type: ConsumableType): boolean {
  return STAMINA_POTION_TYPES.has(type)
}

export function isHealthPotion(type: ConsumableType): boolean {
  return HEALTH_POTION_TYPES.has(type)
}

// Hardcoded fallbacks — overridden by GameConfig keys. Aligned with
// 20260320_seed_consumable_items + ACTIVE_SKILL_PICKER_SPEC §4.
const DEFAULT_STAMINA_RESTORE: Partial<Record<ConsumableType, number>> = {
  stamina_potion_small: 30,
  stamina_potion_medium: 60,
  stamina_potion_large: 999, // effectively full (capped at max_stamina)
}

const DEFAULT_HP_RESTORE_PERCENT: Partial<Record<ConsumableType, number>> = {
  health_potion_small: 25,   // 25% of max HP
  health_potion_medium: 50,  // 50% of max HP
  health_potion_large: 100,  // full restore
}

export async function getStaminaRestore(type: ConsumableType): Promise<number> {
  return getGameConfig<number>(
    `consumable.stamina_restore.${type}`,
    DEFAULT_STAMINA_RESTORE[type] ?? 0,
  )
}

/** Returns heal as a PERCENT (25 = 25%), not a fraction. Matches existing key shape. */
export async function getHpRestorePercent(type: ConsumableType): Promise<number> {
  return getGameConfig<number>(
    `consumable.hp_restore_percent.${type}`,
    DEFAULT_HP_RESTORE_PERCENT[type] ?? 0,
  )
}

/** Returns heal as a FRACTION (0.25 = 25%). Convenience for Active-Slot snapshots. */
export async function getHpRestoreFraction(type: ConsumableType): Promise<number> {
  const pct = await getHpRestorePercent(type)
  return Math.max(0, pct / 100)
}

/** Apply a health-potion heal to a live combat HP value. Clamped to [0, maxHp]. */
export function healHpFromConsumable(
  currentHp: number,
  maxHp: number,
  fraction: number,
): number {
  const amount = Math.floor(maxHp * Math.max(0, fraction))
  return Math.min(maxHp, Math.max(0, currentHp) + amount)
}
