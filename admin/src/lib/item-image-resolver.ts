// =============================================================================
// item-image-resolver.ts — Admin-side borrowed-art fallback
//
// When an item has no imageKey/imageUrl of its own, borrow the asset of a
// sibling item that shares the same itemType + rarity. This keeps the admin
// catalog visually complete while new art is still being uploaded.
//
// Pick is deterministic per item.id so the same item always shows the same
// borrowed image (stable UI across refreshes).
// =============================================================================

import type { PrismaClient } from '@prisma/client'

export interface ResolvableItem {
  id: string
  imageKey: string | null
  imageUrl: string | null
  itemType: string
  rarity: string
}

export type ResolvedItem<T extends ResolvableItem> = T & {
  imageBorrowed: boolean
  imageBorrowedFromId: string | null
}

interface Donor {
  id: string
  itemType: string
  rarity: string
  imageKey: string | null
  imageUrl: string | null
}

/**
 * Deterministic string hash (djb2 variant). Same input → same output.
 * Used to pick a stable donor for each item.
 */
function stableHash(s: string): number {
  let h = 5381
  for (let i = 0; i < s.length; i++) {
    h = ((h << 5) + h + s.charCodeAt(i)) | 0
  }
  return Math.abs(h)
}

/**
 * Batch-resolve images for a list of items.
 *
 * Fallback chain per missing field (imageKey, imageUrl):
 *   1. Item's own value
 *   2. Sibling with same itemType + same rarity that has art
 *   3. Sibling with same itemType (any rarity) that has art
 *
 * Returns items with resolved imageKey/imageUrl plus flags:
 *   - imageBorrowed: true if at least one field was substituted
 *   - imageBorrowedFromId: donor item id (for admin "borrowed from X" hint)
 */
export async function resolveImagesForItems<T extends ResolvableItem>(
  prisma: PrismaClient,
  items: T[],
): Promise<ResolvedItem<T>[]> {
  // Fast path — nothing to resolve
  if (items.length === 0) return []

  // Single DB round-trip: all items that have at least one of imageKey/imageUrl
  const donors: Donor[] = await prisma.item.findMany({
    where: {
      OR: [
        { imageKey: { not: null } },
        { imageUrl: { not: null } },
      ],
    },
    select: {
      id: true,
      itemType: true,
      rarity: true,
      imageKey: true,
      imageUrl: true,
    },
  })

  // Build two lookup maps: by "type:rarity" (preferred) and by type only
  const byTypeRarity = new Map<string, Donor[]>()
  const byType = new Map<string, Donor[]>()

  for (const d of donors) {
    const keyTR = `${d.itemType}:${d.rarity}`
    const bucketTR = byTypeRarity.get(keyTR)
    if (bucketTR) bucketTR.push(d)
    else byTypeRarity.set(keyTR, [d])

    const bucketT = byType.get(d.itemType)
    if (bucketT) bucketT.push(d)
    else byType.set(d.itemType, [d])
  }

  return items.map((item): ResolvedItem<T> => {
    // Already has both fields — nothing to borrow
    if (item.imageKey && item.imageUrl) {
      return { ...item, imageBorrowed: false, imageBorrowedFromId: null }
    }

    // Pick donor pool (preferred: same type + same rarity)
    const preferredPool = byTypeRarity.get(`${item.itemType}:${item.rarity}`)
    const fallbackPool = byType.get(item.itemType)

    const pool = (preferredPool && preferredPool.length > 0 ? preferredPool : fallbackPool) ?? []

    // Exclude self (item could itself be a donor for one field)
    const valid = pool.filter((d) => d.id !== item.id)
    if (valid.length === 0) {
      return { ...item, imageBorrowed: false, imageBorrowedFromId: null }
    }

    // Deterministic pick
    const donor = valid[stableHash(item.id) % valid.length]

    const borrowedKey = !item.imageKey && donor.imageKey !== null
    const borrowedUrl = !item.imageUrl && donor.imageUrl !== null

    return {
      ...item,
      imageKey: item.imageKey ?? donor.imageKey,
      imageUrl: item.imageUrl ?? donor.imageUrl,
      imageBorrowed: borrowedKey || borrowedUrl,
      imageBorrowedFromId: borrowedKey || borrowedUrl ? donor.id : null,
    }
  })
}

/**
 * Single-item convenience wrapper. Useful for detail/edit pages.
 */
export async function resolveImageForItem<T extends ResolvableItem>(
  prisma: PrismaClient,
  item: T,
): Promise<ResolvedItem<T>> {
  const [resolved] = await resolveImagesForItems(prisma, [item])
  return resolved
}
