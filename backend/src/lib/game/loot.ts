// =============================================================================
// loot.ts — Catalog-based item drop system (Loot Relevance v1)
//
// Items are NEVER procedurally generated. All drops come from the Item catalog.
// Each catalog item has a dropChance weight (0 = shop-only, >0 = droppable).
//
// Relevance filters (Phase 5):
//   1. Strict class filter via compatibility matrix
//        warrior ↔ tank (physical / str-vit armored classes share gear)
//        rogue   isolated (agi-based)
//        mage    isolated (int-based)
//        classRestriction = NULL → universal, always allowed
//   2. Gear-aware filter at α = 0.9 — a candidate must not be weaker than
//      0.9 × the power score of the currently equipped item in the same slot.
//      Consumables / accessory-style slots with no equipped item always pass.
//   3. Pity thresholds: trashLootStreak counter on Character increments every
//      time a roll fails all filters (and gets shard-converted). At thresholds
//      5 / 10 / 15 the *next* roll gets rarity bumps (+1 / +2 / +2). Streak
//      resets to 0 on any accepted item drop.
//   4. Shard fallback (Phase 6): when no catalog item passes filters even
//      after rarity bumps, convert to a rarity-matched shard currency tick
//      instead of an empty drop.
//
// Image fallback still works the same way (own art → sibling art).
// =============================================================================

import { getDropChancesConfig, getRarityDistributionConfig } from './live-config';
import { PrismaClient, CharacterClass, Prisma } from '@prisma/client';

/**
 * Accepts either a full PrismaClient or a transaction client (the arg of
 * prisma.$transaction). Every helper that touches Prisma models in this file
 * takes this type so the whole loot pipeline can run inside one transaction.
 */
type PrismaLike = PrismaClient | Prisma.TransactionClient;
import { getDropTuningConfig, calculateItemPowerScore } from './item-balance';

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

export type LootShardTier = 'common' | 'rare' | 'epic' | 'legendary';

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
  sell_price: number;
  /** Shard fallback marker — when set, client should show shard UI instead of an item card. */
  shard?: { tier: LootShardTier; amount: number } | null;
}

// Ordered rarities for the distribution roll (low → high)
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

// --- Class compatibility matrix ---
//
// Which classRestriction values a given character class can wear. NULL is
// universal and always allowed — handled separately in SQL with an OR clause.
// Keeping this as a const lets admin tools / balance sims import it directly.
//
// Rationale: warrior and tank are both str/vit melee classes, so they share
// armor. Rogue and mage have their own unique stat profiles (agi / int) and
// their gear does not carry meaningful value for anyone else.
export const CLASS_COMPAT: Record<CharacterClass, CharacterClass[]> = {
  warrior: ['warrior', 'tank'],
  tank: ['warrior', 'tank'],
  rogue: ['rogue'],
  mage: ['mage'],
};

// --- Pity thresholds ---
//
// When the trashLootStreak reaches one of these, the NEXT rarity roll is
// bumped up by the corresponding number of tiers (clamped to legendary).
// Defaults: 5 → +1, 10 → +2, 15 → +2 (15 is the escalation plateau — if a
// player is still getting irrelevant loot 15 rolls in a row, the shard
// fallback kicks in and starts paying out in the highest tier available).
const PITY_THRESHOLDS: Array<{ streak: number; rarityBump: number }> = [
  { streak: 15, rarityBump: 2 },
  { streak: 10, rarityBump: 2 },
  { streak: 5, rarityBump: 1 },
];

// --- Gear-aware filter ---
//
// A candidate must satisfy:   candidatePower >= α × equippedPower
// α = 0.9 (strict). The lower α, the more generous the filter (0.0 = accept
// anything, 1.0 = must strictly beat current). 0.9 is "basically-as-good-or-
// better" — it allows sidegrades at the edge while still rejecting garbage.
const GEAR_AWARE_ALPHA = 0.9;

// --- Helpers ---

function pickRandom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

function bumpRarity(rarity: Rarity, bump: number): Rarity {
  const idx = RARITIES.indexOf(rarity);
  const bumped = Math.min(RARITIES.length - 1, Math.max(0, idx + bump));
  return RARITIES[bumped];
}

function pityBumpForStreak(streak: number): number {
  for (const tier of PITY_THRESHOLDS) {
    if (streak >= tier.streak) return tier.rarityBump;
  }
  return 0;
}

function rarityToShardTier(rarity: Rarity): LootShardTier {
  // uncommon folds into common (no dedicated shard sink)
  switch (rarity) {
    case 'common':
    case 'uncommon':
      return 'common';
    case 'rare':
      return 'rare';
    case 'epic':
      return 'epic';
    case 'legendary':
      return 'legendary';
  }
}

function shardColumnForTier(tier: LootShardTier): 'shardsCommon' | 'shardsRare' | 'shardsEpic' | 'shardsLegendary' {
  switch (tier) {
    case 'common':
      return 'shardsCommon';
    case 'rare':
      return 'shardsRare';
    case 'epic':
      return 'shardsEpic';
    case 'legendary':
      return 'shardsLegendary';
  }
}

/**
 * Roll a rarity taking player level AND pity streak into account.
 * The player-level bonus tilts the base distribution toward higher rarities;
 * the pity bump is then applied on top as a flat tier shift.
 */
async function rollRarity(playerLevel: number, trashStreak: number): Promise<Rarity> {
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
  let rolled: Rarity = 'common';
  for (const rarity of RARITIES) {
    roll -= weights[rarity];
    if (roll <= 0) {
      rolled = rarity;
      break;
    }
  }

  // Pity bump on top of the base roll
  const bump = pityBumpForStreak(trashStreak);
  return bumpRarity(rolled, bump);
}

/**
 * Pick a random item type. Uniform — class filter happens at the catalog
 * query stage, so biasing here would double-dip on class preference.
 */
function rollItemType(): ItemType {
  return ITEM_TYPES[Math.floor(Math.random() * ITEM_TYPES.length)];
}

// --- Class-compatible catalog item picker ---

/**
 * Find a droppable catalog item that:
 *   - matches (or is compatible with) the character's class
 *   - matches the rolled itemType (with broader fallbacks)
 *   - is within the player's level band
 *   - passes the gear-aware α filter vs currently equipped item in that slot
 *
 * Fallback chain (each step loosens one constraint):
 *   1. Exact match:   class-compat + same rarity + same itemType + gear-aware pass
 *   2. Same rarity,   any equipment type (class-compat + gear-aware pass)
 *   3. Lower rarity,  same itemType (class-compat + gear-aware pass)
 *   4. Any rarity,    any type, class-compat only
 *
 * Returns null if nothing passes — caller should convert to shard.
 */
async function pickRelevantCatalogItem(
  prisma: PrismaLike,
  rarity: Rarity,
  itemType: ItemType,
  playerLevel: number,
  characterClass: CharacterClass,
  equippedPowerBySlot: Record<string, number>,
) {
  const levelCap = playerLevel + 2;
  const compatClasses = CLASS_COMPAT[characterClass] ?? [characterClass];

  // Fallback ladder: each entry is a where clause. We iterate in order and
  // try the gear-aware filter against each candidate pool.
  type LootCandidate = {
    id: string;
    itemName: string;
    itemType: string;
    rarity: string;
    itemLevel: number;
    baseStats: unknown;
    imageKey: string | null;
    imageUrl: string | null;
    sellPrice: number;
    dropChance: number | null;
  };

  type PoolFilter = {
    rarity: Rarity;
    itemType?: ItemType;
  };

  const tryPool = async (filter: PoolFilter): Promise<LootCandidate | null> => {
    // classRestriction is a plain string column (not enum) — include NULL via OR.
    // We must NOT exclude consumables when a concrete itemType is requested —
    // passing `itemType: 'weapon'` is already narrower than `{ not: 'consumable' }`.
    const pool = await prisma.item.findMany({
      where: {
        rarity: filter.rarity,
        ...(filter.itemType
          ? { itemType: filter.itemType }
          : { itemType: { not: 'consumable' } }),
        itemLevel: { lte: levelCap },
        dropChance: { gt: 0 },
        OR: [
          { classRestriction: null },
          { classRestriction: { in: compatClasses as unknown as string[] } },
        ],
      },
      select: {
        id: true,
        itemName: true,
        itemType: true,
        rarity: true,
        itemLevel: true,
        baseStats: true,
        imageKey: true,
        imageUrl: true,
        sellPrice: true,
        dropChance: true,
      },
    });

    if (pool.length === 0) return null;

    // Gear-aware filter — keep candidates whose power >= α × equipped power.
    // Slots with no equipped item always pass (equippedPower = 0).
    const passing: LootCandidate[] = [];
    for (const c of pool) {
      const equippedPower = equippedPowerBySlot[c.itemType] ?? 0;
      if (equippedPower <= 0) {
        passing.push(c);
        continue;
      }
      const candidatePower = await calculateItemPowerScore(
        (c.baseStats as Record<string, number>) ?? {},
        c.rarity as Rarity,
        0,
        c.itemType as ItemType,
      );
      if (candidatePower >= GEAR_AWARE_ALPHA * equippedPower) {
        passing.push(c);
      }
    }
    if (passing.length === 0) return null;

    // Weighted pick by dropChance
    const totalWeight = passing.reduce((sum, c) => sum + (c.dropChance ?? 1), 0);
    let roll = Math.random() * totalWeight;
    for (const c of passing) {
      roll -= c.dropChance ?? 1;
      if (roll <= 0) return c;
    }
    return passing[passing.length - 1];
  };

  // 1. Exact
  let result = await tryPool({ rarity, itemType });
  if (result) return result;

  // 2. Same rarity, any slot
  result = await tryPool({ rarity });
  if (result) return result;

  // 3. Lower rarity, same slot (step down one tier at a time)
  const rarityIdx = RARITIES.indexOf(rarity);
  for (let i = rarityIdx - 1; i >= 0; i--) {
    result = await tryPool({ rarity: RARITIES[i], itemType });
    if (result) return result;
  }

  // 4. Lower rarity, any slot — last gasp before shard fallback
  for (let i = rarityIdx - 1; i >= 0; i--) {
    result = await tryPool({ rarity: RARITIES[i] });
    if (result) return result;
  }

  return null;
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
 */
export async function resolveImage(
  prisma: PrismaLike,
  item: { imageKey: string | null; imageUrl: string | null; itemType: string; rarity: string },
): Promise<ResolvedImage> {
  if (item.imageKey && item.imageUrl) {
    return { imageKey: item.imageKey, imageUrl: item.imageUrl };
  }

  let resolvedKey = item.imageKey;
  let resolvedUrl = item.imageUrl;

  if (!resolvedKey || !resolvedUrl) {
    const siblings = await prisma.item.findMany({
      where: {
        itemType: item.itemType as ItemType,
        rarity: item.rarity as Rarity,
        OR: [{ imageKey: { not: null } }, { imageUrl: { not: null } }],
      },
      select: { imageKey: true, imageUrl: true },
    });

    if (siblings.length > 0) {
      const donor = pickRandom(siblings);
      if (!resolvedKey) resolvedKey = donor.imageKey;
      if (!resolvedUrl) resolvedUrl = donor.imageUrl;
    }

    if (!resolvedKey && !resolvedUrl) {
      const anyRarity = await prisma.item.findMany({
        where: {
          itemType: item.itemType as ItemType,
          OR: [{ imageKey: { not: null } }, { imageUrl: { not: null } }],
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
  prisma: PrismaLike,
  item: { imageKey: string | null; itemType: string; rarity: string },
): Promise<string | null> {
  const resolved = await resolveImage(prisma, { ...item, imageUrl: null });
  return resolved.imageKey;
}

// --- Public API ---

/**
 * Attempt a drop after an activity. Returns a DroppedItem with rarity + type
 * if the RNG check passes, or null if nothing drops. Pity is NOT applied here
 * — pity only affects rarity once a drop is guaranteed to happen.
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
    return null;
  }

  // Pity-aware rarity roll happens inside rollAndPersistLoot where we have
  // the character's trashLootStreak. Here we just return a placeholder type
  // and rarity is overridden downstream.
  const rarity = await rollRarity(playerLevel, 0);
  const itemType = rollItemType();

  return { rarity, itemType };
}

/**
 * Pick a class-relevant, gear-aware catalog item and add it to the
 * character's inventory. Returns null on inventory full / character not found
 * / no matching item (caller should then shard-fallback).
 *
 * NOTE: this function does NOT manage trashLootStreak — that's the job of
 * rollAndPersistLoot so the state machine lives in one place.
 */
export async function persistLoot(
  prisma: PrismaLike,
  characterId: string,
  drop: DroppedItem,
  playerLevel: number,
): Promise<LootResponseItem | null> {
  // Fetch character with class + trashLootStreak + equipped items so we can
  // apply the relevance filters. One query with includes vs N queries later.
  const character = await prisma.character.findUnique({
    where: { id: characterId },
    select: {
      id: true,
      class: true,
      inventorySlots: true,
      trashLootStreak: true,
      equipment: {
        where: { isEquipped: true },
        select: {
          upgradeLevel: true,
          item: {
            select: { itemType: true, rarity: true, baseStats: true },
          },
        },
      },
    },
  });
  if (!character) return null;

  const inventoryCount = await prisma.equipmentInventory.count({
    where: { characterId },
  });
  if (inventoryCount >= character.inventorySlots) {
    return null; // Inventory full
  }

  // Build equipped-power map per slot — one score per slot the character
  // currently has gear in. Slots with no equipped item stay at 0 (which
  // means "anything passes" in the gear-aware filter).
  const equippedPowerBySlot: Record<string, number> = {};
  for (const eq of character.equipment) {
    const power = await calculateItemPowerScore(
      (eq.item.baseStats as Record<string, number>) ?? {},
      eq.item.rarity as Rarity,
      eq.upgradeLevel,
      eq.item.itemType as ItemType,
    );
    // Multiple items in one slot should never happen but be defensive.
    equippedPowerBySlot[eq.item.itemType] = Math.max(
      equippedPowerBySlot[eq.item.itemType] ?? 0,
      power,
    );
  }

  // Apply pity bump to drop.rarity BEFORE looking up candidates.
  const pityBump = pityBumpForStreak(character.trashLootStreak);
  const effectiveRarity = bumpRarity(drop.rarity, pityBump);

  const catalogItem = await pickRelevantCatalogItem(
    prisma,
    effectiveRarity,
    drop.itemType,
    playerLevel,
    character.class,
    equippedPowerBySlot,
  );

  if (!catalogItem) {
    // No relevant item found — caller handles shard fallback.
    return null;
  }

  // Resolve art (own → same type+rarity sibling → any rarity sibling)
  const resolvedImage = await resolveImage(prisma, {
    imageKey: catalogItem.imageKey,
    imageUrl: catalogItem.imageUrl,
    itemType: catalogItem.itemType,
    rarity: catalogItem.rarity,
  });

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
    base_stats: (catalogItem.baseStats as Record<string, number>) ?? {},
    image_key: resolvedImage.imageKey,
    image_url: resolvedImage.imageUrl,
    sell_price: catalogItem.sellPrice,
    shard: null,
  };
}

/**
 * Max value for trashLootStreak. Beyond 15, pity behavior doesn't change
 * (the +2 rarity bump is already at its plateau), so we clamp to prevent
 * the counter from growing unbounded. Also keeps analytics histograms
 * bounded for future telemetry work.
 */
const STREAK_CAP = 15;

/**
 * Roll for loot, apply all relevance filters, and either grant an item or
 * convert to a shard tick. Updates trashLootStreak accordingly.
 *
 * Wrapped in prisma.$transaction so the read (findUnique), the conditional
 * write (persistLoot OR shard increment), and the streak update are atomic.
 * Prevents race conditions between concurrent fight requests from the same
 * character (double pity bump, lost streak reset, stale-read desync).
 *
 * Signature unchanged — all existing callers keep working.
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

  // Narrow PrismaClient here (not PrismaLike) because $transaction is only
  // on the full client. All helpers below accept PrismaLike so they work
  // with the tx client inside the callback.
  return prisma.$transaction(async (tx) => {
    // Read character + inventory count inside the tx so we see consistent
    // state and concurrent writers are serialized by row-level locks on
    // the character row (implicit via the update below).
    const character = await tx.character.findUnique({
      where: { id: characterId },
      select: { inventorySlots: true, trashLootStreak: true },
    });
    if (!character) return null;

    const inventoryCount = await tx.equipmentInventory.count({
      where: { characterId },
    });
    const inventoryFull = inventoryCount >= character.inventorySlots;

    // --- Try to grant an actual item first ---
    if (!inventoryFull) {
      const item = await persistLoot(tx, characterId, drop, playerLevel);
      if (item) {
        // Accepted drop → reset streak (only write if we actually need to,
        // to avoid unnecessary row-version bumps on the hot path)
        if (character.trashLootStreak > 0) {
          await tx.character.update({
            where: { id: characterId },
            data: { trashLootStreak: 0 },
          });
        }
        return item;
      }
    }

    // --- Phase 6: shard fallback ---
    // persistLoot returned null due to no relevant item (or inventory full).
    // Convert to a rarity-matched shard tick and bump the streak, clamped
    // at STREAK_CAP so we don't grow unbounded.
    const tier = rarityToShardTier(drop.rarity);
    const shardColumn = shardColumnForTier(tier);
    const shardAmount = 1;
    const nextStreak = Math.min(STREAK_CAP, character.trashLootStreak + 1);

    await tx.character.update({
      where: { id: characterId },
      data: {
        [shardColumn]: { increment: shardAmount },
        trashLootStreak: { set: nextStreak },
      },
    });

    return {
      id: `shard-${tier}-${Date.now()}`,
      name: `${tier.charAt(0).toUpperCase() + tier.slice(1)} Shard`,
      type: 'shard',
      item_type: 'shard',
      rarity: tier,
      item_level: playerLevel,
      upgrade_level: 0,
      base_stats: {},
      image_key: null,
      image_url: null,
      sell_price: 0,
      shard: { tier, amount: shardAmount },
    };
  });
}
