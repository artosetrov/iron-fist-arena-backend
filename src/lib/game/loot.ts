// =============================================================================
// loot.ts — Item drop system
// =============================================================================

import { DROP_CHANCES, RARITY_DISTRIBUTION } from './balance';

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

// --- Helpers ---

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
