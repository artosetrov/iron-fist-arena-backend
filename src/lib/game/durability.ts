// =============================================================================
// durability.ts — Degrade equipped items after combat
// =============================================================================

import type { PrismaClient } from '@prisma/client'
import { recalculateDerivedStats } from './equipment-stats'

export interface DurabilityChange {
  id: string
  name: string
  durabilityBefore: number
  durabilityAfter: number
}

export interface DegradeResult {
  degraded: DurabilityChange[]
  anyBroken: boolean
}

/**
 * Reduce durability by 1-3 (random) on every equipped item for a character.
 * Items that reach 0 durability are "broken" and provide no stat bonuses.
 * If any item breaks, derived stats are recalculated to remove their contribution.
 *
 * Call AFTER the main combat transaction in PvP, revenge, dungeon fight, and combat simulate routes.
 */
export async function degradeEquipment(
  prisma: PrismaClient,
  characterId: string,
): Promise<DegradeResult> {
  const equipped = await prisma.equipmentInventory.findMany({
    where: { characterId, isEquipped: true },
    include: { item: { select: { itemName: true } } },
  })

  if (equipped.length === 0) return { degraded: [], anyBroken: false }

  const changes: DurabilityChange[] = []
  let anyBroken = false

  await prisma.$transaction(async (tx) => {
    for (const eq of equipped) {
      const loss = Math.floor(Math.random() * 3) + 1 // 1-3
      const newDurability = Math.max(0, eq.durability - loss)

      if (newDurability !== eq.durability) {
        await tx.equipmentInventory.update({
          where: { id: eq.id },
          data: { durability: newDurability },
        })

        changes.push({
          id: eq.id,
          name: eq.item.itemName,
          durabilityBefore: eq.durability,
          durabilityAfter: newDurability,
        })

        if (newDurability === 0 && eq.durability > 0) {
          anyBroken = true
        }
      }
    }
  })

  // If any item broke, recalculate derived stats (broken items give 0 bonus)
  if (anyBroken) {
    await recalculateDerivedStats(characterId)
  }

  return { degraded: changes, anyBroken }
}
