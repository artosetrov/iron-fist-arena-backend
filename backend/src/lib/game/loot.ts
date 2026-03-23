// =============================================================================
// loot.ts — Catalog-based item drop system
//
// Items are NEVER procedurally generated. All drops come from the Item catalog.
// Each catalog item has a dropChance weight (0 = shop-only, >0 = droppable).
// Items without imageKey automatically inherit one from a sibling of the
// same type+rarity that already has art uploaded.
// =============================================================================

import { getDropChancesConfig, getRarityDistributionConfig, getInventoryConfig } from './live-config';
import { PrismaClient } from '@prisma/client';
import { getDropTuningConfig } from './item-balance';

// --- Types ---

export type Rarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary';

export type ItemType =
  | 'weapon'
  | 'helmet'
  | 'chest'
  | 'gloves'
  | 'legs'
  | 'boots'
  | 'accessory'
  | 'amulet'
  | 'belt'
  | 'relic'
  | 'necklace'
  | 'ring';

export interface DroppedItem {
  rarity: Rarity;
  itemType: ItemType;
}

export interface LootResponseItem {
  id: string;
  name: string;
  type: string;
  item_type: string;
  rarity: string;
  item_level: number;
  upgrade_level: number;
  base_stats: Record<string, number>;
  image_key: string | null;
  image_url: string | null;
}

// Ordered rarities for the distribution roll
const RARITIES: Rarity[] = ['common', 'uncommon', 'rare', 'epic', 'legendary'];

// All possible equipment slot types (consumables excluded — never dropped)
const ITEM_TYPES: ItemType[] = [
  'weapon',
  'helmet',
  'chest',
  'gloves',
  'legs',
  'boots',
  'accessory',
  'amulet',
  'belt',
  'relic',
  'necklace',
  'ring',
];

// --- Helpers ---

function pickRandom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

async function getMaxInventorySlots(): Promise<number> {
  const config = await getInventoryConfig();
  return config.MAX_SLOTS;
}

/**
 * Roll a rarity taking player level into account.
 * Reads level rarity bonus config from the database.
 */
async function rollRarity(playerLevel: number): Promise<Rarity> {
  const dropTuning = await getDropTuningConfig();
  const rarityDist = await getRarityDistributionConfig();
  const levelBonus = Math.max(0, (playerLevel - 1) * dropTuning.levelRarityBonusPerLevel);
  const distribution = dropTuning.levelRarityBonusDistribution;

  const weights: Record<Rarity, number> = {
    common: Math.max(rarityDist.common - levelBonus, 10),
    uncommon: rarityDist.uncommon,
    rare: rarityDist.rare + levelBonus * (distribution.rare ?? 0.4),
    epic: rarityDist.epic + levelBonus * (distribution.epic ?? 0.35),
    legendary: rarityDist.legendary + levelBonus * (distribution.legendary ?? 0.25),
  };

  const totalWeight = Object.values(weights).reduce((a, b) => a + b, 0);
  let roll = Math.random() * totalWeight;

  for (const rarity of RARITIES) {
    roll -= weights[rarity];
    if (roll <= 0) return rarity;
  }

  return 'common';
}

/**
 * Pick a random item type.
 */
function rollItemType(): ItemType {
  return ITEM_TYPES[Math.floor(Math.random() * ITEM_TYPES.length)];
}

// --- Catalog item picker ---

/**
 * Find a droppable catalog item matching the rolled rarity + type + player level.
 *
 * Fallback chain:
 *   1. Exact match: same rarity + same itemType, itemLevel ≤ playerLevel + 2
 *   2. Same rarity, any equipment type
 *   3. One rarity tier lower, any equipment type
 *   4. Keep lowering rarity until we find something
 *
 * Within candidates, selection is weighted by the item's `dropChance` field.
 */
async function pickCatalogItem(
  prisma: PrismaClient,
  rarity: Rarity,
  itemType: ItemType,
  playerLevel: number,
) {
  const levelCap = playerLevel + 2;

  // 1. Exact match: same rarity + type
  let candidates = await prisma.item.findMany({
    where: {
      rarity,
      itemType,
      itemLevel: { lte: levelCap },
      dropChance: { gt: 0 },
    },
  });

  // 2. Same rarity, any equipment type
  if (candidates.length === 0) {
    candidates = await prisma.item.findMany({
      where: {
        rarity,
        itemLevel: { lte: levelCap },
        dropChance: { gt: 0 },
        itemType: { not: 'consumable' },
      },
    });
  }

  // 3. Lower rarity fallback
  if (candidates.length === 0) {
    const rarityIdx = RARITIES.indexOf(rarity);
    for (let i = rarityIdx - 1; i >= 0 && candidates.length === 0; i--) {
      candidates = await prisma.item.findMany({
        where: {
          rarity: RARITIES[i],
          itemLevel: { lte: levelCap },
          dropChance: { gt: 0 },
          itemType: { not: 'consumable' },
        },
      });
    }
  }

  if (candidates.length === 0) return null;

  // Weighted random pick by dropChance
  const totalWeight = candidates.reduce((sum, c) => sum + (c.dropChance ?? 1), 0);
  let roll = Math.random() * totalWeight;
  for (const candidate of candidates) {
    roll -= (candidate.dropChance ?? 1);
    if (roll <= 0) return candidate;
  }

  return candidates[candidates.length - 1];
}

// --- Image resolver ---

export interface ResolvedImage {
  imageKey: string | null;
  imageUrl: string | null;
}

/**
 * Resolve art for an item. Checks imageKey first, then imageUrl.
 * If the item has its own art — use it. Otherwise, borrow from a
 * sibling of the same type+rarity that already has art uploaded.
 * Last resort: any item of the same type with art (any rarity).
 *
 * Fallback chain per field:
 *   1. Own imageKey / imageUrl
 *   2. Same type + same rarity sibling with art
 *   3. Same type, any rarity sibling with art
 */
export async function resolveImage(
  prisma: PrismaClient,
  item: { imageKey: string | null; imageUrl: string | null; itemType: string; rarity: string },
): Promise<ResolvedImage> {
  // If item already has both fields — nothing to resolve
  if (item.imageKey && item.imageUrl) {
    return { imageKey: item.imageKey, imageUrl: item.imageUrl };
  }

  // If item has at least one of its own fields, keep it; only resolve the missing one
  let resolvedKey = item.imageKey;
  let resolvedUrl = item.imageUrl;

  // We need to find a sibling with art if either field is missing
  if (!resolvedKey || !resolvedUrl) {
    // 1. Same type + same rarity siblings with art (imageKey OR imageUrl)
    const siblings = await prisma.item.findMany({
      where: {
        itemType: item.itemType as ItemType,
        rarity: item.rarity as Rarity,
        OR: [
          { imageKey: { not: null } },
          { imageUrl: { not: null } },
        ],
      },
      select: { imageKey: true, imageUrl: true },
    });

    if (siblings.length > 0) {
      const donor = pickRandom(siblings);
      if (!resolvedKey) resolvedKey = donor.imageKey;
      if (!resolvedUrl) resolvedUrl = donor.imageUrl;
    }

    // 2. Fallback: same type, any rarity, with art
    if (!resolvedKey && !resolvedUrl) {
      const anyRarity = await prisma.item.findMany({
        where: {
          itemType: item.itemType as ItemType,
          OR: [
            { imageKey: { not: null } },
            { imageUrl: { not: null } },
          ],
        },
        select: { imageKey: true, imageUrl: true },
      });

      if (anyRarity.length > 0) {
        const donor = pickRandom(anyRarity);
        if (!resolvedKey) resolvedKey = donor.imageKey;
        if (!resolvedUrl) resolvedUrl = donor.imageUrl;
      }
    }
  }

  return { imageKey: resolvedKey, imageUrl: resolvedUrl };
}

/** @deprecated Use resolveImage() instead — kept for backwards compatibility */
export async function resolveImageKey(
  prisma: PrismaClient,
  item: { imageKey: string | null; itemType: string; rarity: string },
): Promise<string | null> {
  const resolved = await resolveImage(prisma, { ...item, imageUrl: null });
  return resolved.imageKey;
}

// --- Public API ---

/**
 * Attempt a drop after an activity. Returns a DroppedItem with rarity + type
 * if the RNG check passes, or null if nothing drops.
 */
export async function rollDropChance(
  playerLevel: number,
  difficulty: string,
  luk: number = 0,
): Promise<DroppedItem | null> {
  const dropTuning = await getDropTuningConfig();
  const dropChances = await getDropChancesConfig();
  const baseChance = dropChances[difficulty as keyof typeof dropChances] ?? 0;
  const lukBonus = luk * dropTuning.lukBonusPerPoint;
  const chance = Math.min(baseChance + lukBonus, dropTuning.dropChanceCap);

  if (Math.random() > chance) {
    return null; // No drop
  }

  const rarity = await rollRarity(playerLevel);
  const itemType = rollItemType();

  return { rarity, itemType };
}

/**
 * Pick a catalog item and add it to the character's inventory.
 * No new Item rows are created — the EquipmentInventory references
 * an existing catalog Item.
 */
export async function persistLoot(
  prisma: PrismaClient,
  characterId: string,
  drop: DroppedItem,
  playerLevel: number,
): Promise<LootResponseItem | null> {
  // Check inventory capacity
  const maxSlots = await getMaxInventorySlots();
  const inventoryCount = await prisma.equipmentInventory.count({
    where: { characterId },
  });
  if (inventoryCount >= maxSlots) {
    return null; // Inventory full — drop is lost
  }

  // Find a matching catalog item
  const catalogItem = await pickCatalogItem(prisma, drop.rarity, drop.itemType, playerLevel);
  if (!catalogItem) return null;

  // Resolve art (own art → sibling art of same type+rarity → any rarity)
  const resolvedImage = await resolveImage(prisma, {
    imageKey: catalogItem.imageKey,
    imageUrl: catalogItem.imageUrl,
    itemType: catalogItem.itemType,
    rarity: catalogItem.rarity,
  });

  // Create inventory entry pointing to the shared catalog item
  const equipment = await prisma.equipmentInventory.create({
    data: {
      characterId,
      itemId: catalogItem.id,
      upgradeLevel: 0,
      durability: 100,
      maxDurability: 100,
      isEquipped: false,
    },
  });

  return {
    id: equipment.id,
    name: catalogItem.itemName,
    type: catalogItem.itemType,
    item_type: catalogItem.itemType,
    rarity: catalogItem.rarity,
    item_level: catalogItem.itemLevel,
    upgrade_level: 0,
    base_stats: (catalogItem.baseStats ?? {}) as Record<string, number>,
    image_key: resolvedImage.imageKey,
    image_url: resolvedImage.imageUrl,
  };
}

/**
 * Roll for loot and persist if successful. Convenience wrapper.
 * Signature unchanged — all callers keep working without modification.
 */
export async function rollAndPersistLoot(
  prisma: PrismaClient,
  characterId: string,
  playerLevel: number,
  difficulty: string,
  luk: number = 0,
): Promise<LootResponseItem | null> {
  const drop = await rollDropChance(playerLevel, difficulty, luk);
  if (!drop) return null;
  return persistLoot(prisma, characterId, drop, playerLevel);
}
