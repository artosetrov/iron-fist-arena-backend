import { prisma } from '@/lib/prisma'
import { getUpgradeStatBonus } from '@/lib/game/item-balance'
import { TWO_HANDED_CATALOG_IDS } from '@/lib/game/item-constants'
import { buildEffectiveItemStats } from '@/lib/game/item-stats'

/**
 * Builds the canonical inventory payload — the exact same shape that
 * GET /api/inventory returns. Used by equip/unequip (and any other
 * mutation endpoints) so the iOS client can merge a single authoritative
 * snapshot instead of juggling partial responses.
 *
 * Shape: { equipment: [...with effectiveStats+isTwoHanded], consumables, inventorySlots }
 *
 * BUG-62 (2026-04-11): equip/unequip previously returned only
 * `{ equipment }`, which forced the client to locally preserve
 * consumables on every merge. Any divergence between the optimistic
 * prediction and the server's answer silently wiped consumables until
 * the next full load. Returning the full snapshot here is the only
 * robust fix.
 */
export async function buildInventoryResponse(characterId: string) {
  const [character, equipment, consumables] = await Promise.all([
    prisma.character.findUnique({
      where: { id: characterId },
      select: { inventorySlots: true },
    }),
    prisma.equipmentInventory.findMany({
      where: { characterId },
      include: {
        item: {
          select: {
            id: true, itemName: true, itemType: true, rarity: true, itemLevel: true,
            baseStats: true, setName: true, specialEffect: true, uniquePassive: true,
            imageUrl: true, imageKey: true, classRestriction: true, description: true,
            catalogId: true, buyPrice: true, sellPrice: true,
          },
        },
      },
      orderBy: { acquiredAt: 'desc' },
    }),
    prisma.consumableInventory.findMany({
      where: { characterId },
      orderBy: { consumableType: 'asc' },
    }),
  ])

  const upgradeStatBonus = await getUpgradeStatBonus()
  const equipmentWithEffectiveStats = equipment.map((eq) => {
    const effectiveStats = buildEffectiveItemStats(
      eq.item.baseStats,
      eq.rolledStats,
      eq.upgradeLevel,
      upgradeStatBonus,
    )
    const isTwoHanded =
      eq.item.itemType === 'weapon' && TWO_HANDED_CATALOG_IDS.has(eq.item.catalogId)
    return { ...eq, effectiveStats, isTwoHanded }
  })

  return {
    equipment: equipmentWithEffectiveStats,
    consumables,
    inventorySlots: character?.inventorySlots ?? 28,
  }
}
