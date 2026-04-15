import { ConsumableType } from '@prisma/client'
import { getGameConfig } from '@/lib/game/config'

// Direct-sale consumables in the regular shop. Other consumable enum members
// (e.g. protection_scroll, legendary_shard) are granted by rewards/offers and
// must never be purchasable through /shop/buy-consumable.
export const DIRECT_PURCHASE_CONSUMABLES: readonly ConsumableType[] = [
  'stamina_potion_small',
  'stamina_potion_medium',
  'stamina_potion_large',
  'health_potion_small',
  'health_potion_medium',
  'health_potion_large',
] as const

const DIRECT_PURCHASE_CONSUMABLE_SET = new Set<ConsumableType>(DIRECT_PURCHASE_CONSUMABLES)

// Fallback values are aligned with the seeded item catalog and current
// transactional shop pricing. GameConfig remains the primary live source.
const DEFAULT_CONSUMABLE_PRICES: Record<ConsumableType, number> = {
  stamina_potion_small: 100,
  stamina_potion_medium: 250,
  stamina_potion_large: 500,
  health_potion_small: 150,
  health_potion_medium: 350,
  health_potion_large: 700,
  protection_scroll: 0,
  legendary_shard: 0,
}

export function isDirectPurchaseConsumableType(value: string): value is ConsumableType {
  return DIRECT_PURCHASE_CONSUMABLE_SET.has(value as ConsumableType)
}

export async function getConsumablePrice(type: ConsumableType): Promise<number> {
  return getGameConfig<number>(
    `consumable.price.${type}`,
    DEFAULT_CONSUMABLE_PRICES[type],
  )
}

export async function getConsumablePriceMap(
  types: readonly ConsumableType[] = DIRECT_PURCHASE_CONSUMABLES,
): Promise<Map<ConsumableType, number>> {
  const entries = await Promise.all(
    types.map(async (type) => [type, await getConsumablePrice(type)] as const)
  )
  return new Map(entries)
}
