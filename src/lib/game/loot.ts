// =============================================================================
// loot.ts — Item drop system
// =============================================================================

import { DROP_CHANCES, RARITY_DISTRIBUTION } from './balance';
import { PrismaClient } from '@prisma/client';
import { randomUUID } from 'crypto';

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
 * Generate base stats for a dropped item based on its level and rarity.
 */
function generateBaseStats(
  itemType: ItemType,
  rarity: Rarity,
  itemLevel: number,
): Record<string, number> {
  const rarityMult: Record<Rarity, number> = {
    common: 1.0,
    uncommon: 1.3,
    rare: 1.6,
    epic: 2.0,
    legendary: 2.5,
  };
  const mult = rarityMult[rarity];
  const base = Math.max(1, Math.round(itemLevel * 2 * mult));

  // Different item types emphasize different stats
  switch (itemType) {
    case 'weapon':
      return { str: base, agi: Math.round(base * 0.3) };
    case 'helmet':
      return { vit: Math.round(base * 0.8), wis: Math.round(base * 0.4) };
    case 'chest':
      return { vit: base, end: Math.round(base * 0.5) };
    case 'gloves':
      return { str: Math.round(base * 0.6), agi: Math.round(base * 0.6) };
    case 'legs':
      return { vit: Math.round(base * 0.7), end: Math.round(base * 0.5) };
    case 'boots':
      return { agi: base, end: Math.round(base * 0.3) };
    case 'accessory':
      return { luk: base, cha: Math.round(base * 0.5) };
    case 'amulet':
      return { int: base, wis: Math.round(base * 0.5) };
    case 'belt':
      return { end: base, vit: Math.round(base * 0.3) };
    case 'relic':
      return { int: Math.round(base * 0.7), wis: Math.round(base * 0.7) };
    case 'necklace':
      return { cha: base, luk: Math.round(base * 0.4) };
    case 'ring':
      return { luk: Math.round(base * 0.5), str: Math.round(base * 0.5) };
    default:
      return { str: base };
  }
}

/**
 * Roll a rarity taking player level into account.
 * Higher levels slightly increase the chance of rare+ drops.
 * The level bonus shifts weight from common towards rarer tiers.
 */
function rollRarity(playerLevel: number): Rarity {
  // Level bonus: each level above 1 gives +0.2% shift towards rare+
  const levelBonus = Math.max(0, (playerLevel - 1) * 0.2);

  // Build adjusted weights
  const weights: Record<Rarity, number> = {
    common: Math.max(RARITY_DISTRIBUTION.common - levelBonus, 10),
    uncommon: RARITY_DISTRIBUTION.uncommon,
    rare: RARITY_DISTRIBUTION.rare + levelBonus * 0.4,
    epic: RARITY_DISTRIBUTION.epic + levelBonus * 0.35,
    legendary: RARITY_DISTRIBUTION.legendary + levelBonus * 0.25,
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
 *
 * @param playerLevel  The player's current level
 * @param difficulty   Source difficulty key (e.g. 'pvp', 'training', 'dungeon_easy', 'boss')
 * @returns            A DroppedItem if the roll succeeds, or null
 */
export function rollDropChance(
  playerLevel: number,
  difficulty: string,
): DroppedItem | null {
  const chance = DROP_CHANCES[difficulty] ?? 0;

  if (Math.random() > chance) {
    return null; // No drop
  }

  const rarity = rollRarity(playerLevel);
  const itemType = rollItemType();

  // Item level scales with player level (+-2 range)
  const levelVariance = Math.floor(Math.random() * 5) - 2; // -2 to +2
  const itemLevel = Math.max(1, playerLevel + levelVariance);

  return {
    rarity,
    itemType,
    itemLevel,
  };
}

/**
 * Persist a dropped item to the database: creates an Item record and an
 * EquipmentInventory entry for the character.
 *
 * @returns The loot response object ready to send to the client.
 */
export async function persistLoot(
  prisma: PrismaClient,
  characterId: string,
  drop: DroppedItem,
): Promise<LootResponseItem> {
  const name = generateItemName(drop.itemType, drop.rarity);
  const baseStats = generateBaseStats(drop.itemType, drop.rarity, drop.itemLevel);
  const catalogId = `loot_${randomUUID()}`;

  // Rarity-based sell price
  const sellPriceByRarity: Record<Rarity, number> = {
    common: 10,
    uncommon: 25,
    rare: 60,
    epic: 150,
    legendary: 400,
  };
  const sellPrice = sellPriceByRarity[drop.rarity] * drop.itemLevel;

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
 *
 * @returns LootResponseItem if drop succeeded, or null
 */
export async function rollAndPersistLoot(
  prisma: PrismaClient,
  characterId: string,
  playerLevel: number,
  difficulty: string,
): Promise<LootResponseItem | null> {
  const drop = rollDropChance(playerLevel, difficulty);
  if (!drop) return null;
  return persistLoot(prisma, characterId, drop);
}
