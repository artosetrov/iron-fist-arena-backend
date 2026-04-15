import { ConsumableType } from '@prisma/client'
import { cacheDelete } from '@/lib/cache'

export const ACTIVE_SLOT_CONSUMABLES: readonly ConsumableType[] = [
  'health_potion_small',
  'health_potion_medium',
  'health_potion_large',
] as const

export function activeSlotsCacheKey(characterId: string): string {
  return `active-slots:char:${characterId}`
}

export async function invalidateActiveSlotsCache(characterId: string): Promise<void> {
  await cacheDelete(activeSlotsCacheKey(characterId))
}
