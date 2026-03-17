// =============================================================================
// loot.ts — Item drop system (config-driven via item-balance engine)
// =============================================================================

import { INVENTORY } from './balance';
import { getDropChancesConfig, getRarityDistributionConfig, getInventoryConfig } from './live-config';
import { PrismaClient } from '@prisma/client';
import { randomUUID } from 'crypto';
import { generateBalancedBaseStats, calculateSellPrice, getDropTuningConfig, getRarityMultipliers } from './item-balance';

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
  itemLevel: number;
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
}

// Note: MAX_INVENTORY_SLOTS is now loaded from live-config, see getMaxInventorySlots()
/**
 * Get the maximum inventory slots from live config.
 * Cache this if calling frequently in a single request.
 */
async function getMaxInventorySlots(): Promise<number> {
  const config = await getInventoryConfig();
  return config.MAX_SLOTS;
}

// All possible equipment slot types
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

// Ordered rarities for the distribution roll
const RARITIES: Rarity[] = ['common', 'uncommon', 'rare', 'epic', 'legendary'];

// --- Item Name Tables ---

const RARITY_PREFIXES: Record<Rarity, string[]> = {
  common: ['Worn', 'Old', 'Simple', 'Crude', 'Plain'],
  uncommon: ['Sturdy', 'Refined', 'Fine', 'Polished', 'Solid'],
  rare: ['Enchanted', 'Arcane', 'Mystic', 'Runic', 'Blessed'],
  epic: ['Infernal', 'Celestial', 'Draconic', 'Shadow', 'Void'],
  legendary: ['Ancient', 'Eternal', 'Divine', 'Abyssal', 'Primordial'],
};

const ITEM_TYPE_NAMES: Record<ItemType, string[]> = {
  weapon: ['Blade', 'Sword', 'Axe', 'Mace', 'Staff', 'Dagger', 'Warhammer'],
  helmet: ['Helm', 'Crown', 'Hood', 'Circlet', 'Visor'],
  chest: ['Chestplate', 'Robe', 'Cuirass', 'Vest', 'Hauberk'],
  gloves: ['Gauntlets', 'Grips', 'Handguards', 'Bracers', 'Mitts'],
  legs: ['Greaves', 'Leggings', 'Tassets', 'Cuisses', 'Legguards'],
  boots: ['Treads', 'Sabatons', 'Striders', 'Boots', 'Sandals'],
  accessory: ['Trinket', 'Charm', 'Token', 'Emblem', 'Sigil'],
  amulet: ['Amulet', 'Pendant', 'Talisman', 'Locket', 'Medallion'],
  belt: ['Belt', 'Sash', 'Girdle', 'Cord', 'Waistguard'],
  relic: ['Relic', 'Artifact', 'Idol', 'Totem', 'Orb'],
  necklace: ['Necklace', 'Chain', 'Collar', 'Choker', 'Torque'],
  ring: ['Ring', 'Band', 'Loop', 'Signet', 'Circle'],
};

// --- Helpers ---

function pickRandom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

/**
 * Generate a name for a dropped item based on its rarity and type.
 */
export function generateItemName(itemType: ItemType, rarity: Rarity): string {
  const prefix = pickRandom(RARITY_PREFIXES[rarity]);
  const name = pickRandom(ITEM_TYPE_NAMES[itemType]);
  return `${prefix} ${name}`;
}

/**
 * Roll a rarity taking player level into account.
 * Now reads level rarity bonus config from the database.
 */
async function rollRarity(playerLevel: number): Promise<Rarity> {
  const dropTuning = await getDropTuningConfig();
  const rarityDist = await getRarityDistributionConfig();
  const levelBonus = Math.max(0, (playerLevel - 1) * dropTuning.levelRarityBonusPerLevel);
  const distribution = dropTuning.levelRarityBonusDistribution;

  // Build adjusted weights
  const weights: Record<Rarity, number> = {
    common: Math.max(rarityDist.common - levelBonus, 10),
    uncommon: rarityDist.uncommon,
    rare: rarityDist.rare + levelBonus * (distribution.rare ?? 0.4),
    epic: rarityDist.epic + levelBonus * (distribution.epic ?? 0.35),
    legendary: rarityDist.legendary + levelBonus * (distribution.legendary ?? 0.25),
  };

  // Normalise to sum
  const totalWeight = Object.values(weights).reduce((a, b) => a + b, 0);
  let roll = Math.random() * totalWeight;

  for (const rarity of RARITIES) {
    roll -= weights[rarity];
    if (roll <= 0) {
      return rarity;
    }
  }

  return 'common';
}

/**
 * Pick a random item type.
 */
function rollItemType(): ItemType {
  return ITEM_TYPES[Math.floor(Math.random() * ITEM_TYPES.length)];
}

// --- Public API ---

/**
 * Attempt to generate a dropped item after an activity.
 * Now reads drop chances from live config with LUK bonus and drop cap from item-balance config.
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

  // Item level scales with player level (configurable variance)
  const variance = dropTuning.levelVariance;
  const levelVariance = Math.floor(Math.random() * (variance * 2 + 1)) - variance;
  const itemLevel = Math.max(1, playerLevel + levelVariance);

  return {
    rarity,
    itemType,
    itemLevel,
  };
}

/**
 * Persist a dropped item to the database.
 * Now uses the balance engine for stat generation and sell price.
 */
export async function persistLoot(
  prisma: PrismaClient,
  characterId: string,
  drop: DroppedItem,
): Promise<LootResponseItem | null> {
  // Check inventory capacity before creating the item
  const maxSlots = await getMaxInventorySlots();
  const inventoryCount = await prisma.equipmentInventory.count({
    where: { characterId },
  });
  if (inventoryCount >= maxSlots) {
    return null; // Inventory full — drop is lost
  }

  const name = generateItemName(drop.itemType, drop.rarity);
  const baseStats = await generateBalancedBaseStats(drop.itemType, drop.rarity, drop.itemLevel);
  const catalogId = `loot_${randomUUID()}`;
  const sellPrice = await calculateSellPrice(drop.rarity, drop.itemLevel);

  // Create Item + EquipmentInventory in an interactive transaction
  const result = await prisma.$transaction(async (tx) => {
    const item = await tx.item.create({
      data: {
        catalogId,
        itemName: name,
        itemType: drop.itemType,
        rarity: drop.rarity,
        itemLevel: drop.itemLevel,
        baseStats,
        sellPrice,
        description: `A ${drop.rarity} ${drop.itemType} dropped in combat.`,
      },
    });

    const equipment = await tx.equipmentInventory.create({
      data: {
        characterId,
        itemId: item.id,
        upgradeLevel: 0,
        durability: 100,
        maxDurability: 100,
        isEquipped: false,
      },
    });

    return { item, equipment };
  });

  return {
    id: result.equipment.id,
    name,
    type: drop.itemType,
    item_type: drop.itemType,
    rarity: drop.rarity,
    item_level: drop.itemLevel,
    upgrade_level: 0,
    base_stats: baseStats,
  };
}

/**
 * Roll for loot and persist if successful. Convenience wrapper.
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
  return persistLoot(prisma, characterId, drop);
}
