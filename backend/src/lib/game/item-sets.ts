// =============================================================================
// item-sets.ts — Item set definitions, set bonus calculation, boss-exclusive drops
// =============================================================================

import { PrismaClient } from '@prisma/client'

// --- Set Bonus Types ---

export interface SetBonusEffect {
  stat: string
  value: number
}

export interface SetBonusTier {
  piecesRequired: number
  name: string
  effects: SetBonusEffect[]
}

export interface ItemSetDefinition {
  id: string
  name: string
  description: string
  pieces: string[] // catalog item keys belonging to this set
  bonuses: SetBonusTier[]
}

// --- Set Definitions ---

export const ITEM_SETS: ItemSetDefinition[] = [
  {
    id: 'set_shadow_assassin',
    name: "Shadow Assassin's Regalia",
    description: 'Forged in darkness, grants lethal precision.',
    pieces: ['shadow_helm', 'shadow_chest', 'shadow_gloves', 'shadow_legs', 'shadow_boots'],
    bonuses: [
      { piecesRequired: 2, name: '2-Piece', effects: [{ stat: 'agi', value: 15 }, { stat: 'crit', value: 5 }] },
      { piecesRequired: 3, name: '3-Piece', effects: [{ stat: 'str', value: 10 }, { stat: 'dodge', value: 3 }] },
      { piecesRequired: 5, name: '5-Piece', effects: [{ stat: 'agi', value: 25 }, { stat: 'crit', value: 12 }, { stat: 'str', value: 15 }] },
    ],
  },
  {
    id: 'set_iron_bastion',
    name: 'Iron Bastion',
    description: 'Unbreakable armor of the ancient guardians.',
    pieces: ['bastion_helm', 'bastion_chest', 'bastion_gloves', 'bastion_legs', 'bastion_boots'],
    bonuses: [
      { piecesRequired: 2, name: '2-Piece', effects: [{ stat: 'armor', value: 20 }, { stat: 'vit', value: 10 }] },
      { piecesRequired: 3, name: '3-Piece', effects: [{ stat: 'maxHp', value: 150 }, { stat: 'end', value: 8 }] },
      { piecesRequired: 5, name: '5-Piece', effects: [{ stat: 'armor', value: 40 }, { stat: 'maxHp', value: 300 }, { stat: 'vit', value: 20 }] },
    ],
  },
  {
    id: 'set_arcane_scholar',
    name: "Arcane Scholar's Vestments",
    description: 'Woven with threads of pure magic.',
    pieces: ['arcane_helm', 'arcane_chest', 'arcane_gloves', 'arcane_legs', 'arcane_boots'],
    bonuses: [
      { piecesRequired: 2, name: '2-Piece', effects: [{ stat: 'int', value: 15 }, { stat: 'wis', value: 10 }] },
      { piecesRequired: 3, name: '3-Piece', effects: [{ stat: 'magicResist', value: 15 }, { stat: 'int', value: 10 }] },
      { piecesRequired: 5, name: '5-Piece', effects: [{ stat: 'int', value: 30 }, { stat: 'wis', value: 20 }, { stat: 'magicResist', value: 25 }] },
    ],
  },
  {
    id: 'set_berserker',
    name: "Berserker's Wrath",
    description: 'Blood-soaked gear that grows stronger with battle.',
    pieces: ['berserker_helm', 'berserker_chest', 'berserker_gloves', 'berserker_legs', 'berserker_boots'],
    bonuses: [
      { piecesRequired: 2, name: '2-Piece', effects: [{ stat: 'str', value: 20 }, { stat: 'agi', value: 5 }] },
      { piecesRequired: 3, name: '3-Piece', effects: [{ stat: 'crit', value: 8 }, { stat: 'str', value: 10 }] },
      { piecesRequired: 5, name: '5-Piece', effects: [{ stat: 'str', value: 35 }, { stat: 'crit', value: 15 }, { stat: 'maxHp', value: 200 }] },
    ],
  },
  {
    id: 'set_fortune_seeker',
    name: "Fortune Seeker's Ensemble",
    description: 'Lady Luck smiles on those who wear this set.',
    pieces: ['fortune_helm', 'fortune_chest', 'fortune_gloves', 'fortune_legs', 'fortune_amulet'],
    bonuses: [
      { piecesRequired: 2, name: '2-Piece', effects: [{ stat: 'luk', value: 15 }, { stat: 'cha', value: 5 }] },
      { piecesRequired: 3, name: '3-Piece', effects: [{ stat: 'luk', value: 20 }, { stat: 'goldBonus', value: 10 }] },
      { piecesRequired: 5, name: '5-Piece', effects: [{ stat: 'luk', value: 40 }, { stat: 'cha', value: 15 }, { stat: 'dropBonus', value: 5 }] },
    ],
  },
  // Wanderer's Charm — early-game CHA/LUK set (drops from floor 3+ bosses)
  {
    id: 'set_wanderers_charm',
    name: "Wanderer's Charm",
    description: 'Trinkets blessed by travelling fortune-tellers. A stepping stone to true luck.',
    pieces: ['charm_ring', 'charm_amulet', 'charm_belt'],
    bonuses: [
      { piecesRequired: 2, name: '2-Piece', effects: [{ stat: 'cha', value: 8 }, { stat: 'luk', value: 8 }] },
      { piecesRequired: 3, name: '3-Piece', effects: [{ stat: 'cha', value: 15 }, { stat: 'luk', value: 15 }, { stat: 'goldBonus', value: 3 }, { stat: 'dropBonus', value: 2 }] },
    ],
  },
]

// --- Boss-Exclusive Drop Definitions ---

export interface BossExclusiveDrop {
  bossId: string  // dungeon boss identifier
  bossName: string
  itemKey: string // catalog item key
  dropChance: number // 0-100%
  minFloor: number // minimum dungeon floor to drop
}

export const BOSS_EXCLUSIVE_DROPS: BossExclusiveDrop[] = [
  // Dungeon bosses drop set pieces
  { bossId: 'warden_depths', bossName: 'Warden of the Depths', itemKey: 'bastion_helm', dropChance: 15, minFloor: 5 },
  { bossId: 'warden_depths', bossName: 'Warden of the Depths', itemKey: 'bastion_chest', dropChance: 10, minFloor: 5 },
  { bossId: 'lord_shadows', bossName: 'Lord of Shadows', itemKey: 'shadow_helm', dropChance: 15, minFloor: 5 },
  { bossId: 'lord_shadows', bossName: 'Lord of Shadows', itemKey: 'shadow_chest', dropChance: 10, minFloor: 5 },
  { bossId: 'bone_king', bossName: 'The Bone King', itemKey: 'berserker_helm', dropChance: 15, minFloor: 5 },
  { bossId: 'bone_king', bossName: 'The Bone King', itemKey: 'berserker_chest', dropChance: 10, minFloor: 5 },
  { bossId: 'abyssal_overlord', bossName: 'Abyssal Overlord', itemKey: 'arcane_helm', dropChance: 12, minFloor: 8 },
  { bossId: 'abyssal_overlord', bossName: 'Abyssal Overlord', itemKey: 'arcane_chest', dropChance: 8, minFloor: 8 },
  { bossId: 'champion_decay', bossName: 'Champion of Decay', itemKey: 'fortune_helm', dropChance: 12, minFloor: 8 },
  { bossId: 'champion_decay', bossName: 'Champion of Decay', itemKey: 'fortune_amulet', dropChance: 8, minFloor: 8 },
  { bossId: 'iron_tyrant', bossName: 'The Iron Tyrant', itemKey: 'bastion_gloves', dropChance: 12, minFloor: 10 },
  { bossId: 'iron_tyrant', bossName: 'The Iron Tyrant', itemKey: 'bastion_legs', dropChance: 10, minFloor: 10 },
  // Wanderer's Charm — early-game CHA/LUK set (floor 3+ bosses)
  { bossId: 'warden_depths', bossName: 'Warden of the Depths', itemKey: 'charm_ring', dropChance: 15, minFloor: 3 },
  { bossId: 'lord_shadows', bossName: 'Lord of Shadows', itemKey: 'charm_amulet', dropChance: 15, minFloor: 3 },
  { bossId: 'bone_king', bossName: 'The Bone King', itemKey: 'charm_belt', dropChance: 15, minFloor: 3 },
  // Rush miniboss exclusive drops
  { bossId: 'rush_miniboss', bossName: 'Rush Miniboss', itemKey: 'shadow_gloves', dropChance: 8, minFloor: 6 },
  { bossId: 'rush_miniboss', bossName: 'Rush Miniboss', itemKey: 'berserker_gloves', dropChance: 8, minFloor: 6 },
  { bossId: 'rush_miniboss', bossName: 'Rush Miniboss', itemKey: 'arcane_gloves', dropChance: 8, minFloor: 6 },
]

// --- Set Bonus Calculation ---

/**
 * Calculate active set bonuses based on equipped items.
 * Returns accumulated stat bonuses from all active set tiers.
 */
export function calculateSetBonuses(
  equippedItemKeys: string[],
): { setId: string; setName: string; equippedCount: number; totalPieces: number; activeBonuses: SetBonusTier[]; totalEffects: SetBonusEffect[] }[] {
  const result: { setId: string; setName: string; equippedCount: number; totalPieces: number; activeBonuses: SetBonusTier[]; totalEffects: SetBonusEffect[] }[] = []

  for (const set of ITEM_SETS) {
    const equippedCount = set.pieces.filter(key => equippedItemKeys.includes(key)).length
    if (equippedCount === 0) continue

    const activeBonuses = set.bonuses.filter(b => equippedCount >= b.piecesRequired)
    const totalEffects: SetBonusEffect[] = []

    // Aggregate effects from all active tiers
    for (const bonus of activeBonuses) {
      for (const effect of bonus.effects) {
        const existing = totalEffects.find(e => e.stat === effect.stat)
        if (existing) {
          existing.value += effect.value
        } else {
          totalEffects.push({ ...effect })
        }
      }
    }

    result.push({
      setId: set.id,
      setName: set.name,
      equippedCount,
      totalPieces: set.pieces.length,
      activeBonuses,
      totalEffects,
    })
  }

  return result
}

/**
 * Get flat stat bonuses map from set bonuses for a character's equipped items.
 * Uses the Item catalog's setName field to identify set membership.
 */
export async function getCharacterSetBonuses(
  prisma: PrismaClient,
  characterId: string,
): Promise<Record<string, number>> {
  // Fetch equipped items with their catalog item's catalogId (used as key)
  const equippedItems = await prisma.equipmentInventory.findMany({
    where: { characterId, isEquipped: true },
    include: { item: { select: { catalogId: true, setName: true } } },
  })

  const keys = equippedItems
    .map(i => i.item.catalogId)
    .filter((k): k is string => !!k)
  const setBonuses = calculateSetBonuses(keys)

  const statMap: Record<string, number> = {}
  for (const setBonus of setBonuses) {
    for (const effect of setBonus.totalEffects) {
      statMap[effect.stat] = (statMap[effect.stat] ?? 0) + effect.value
    }
  }

  return statMap
}

/**
 * Roll for boss-exclusive drops.
 * Returns the catalog item key if the roll succeeds, null otherwise.
 */
export function rollBossExclusiveDrop(
  bossId: string,
  floor: number,
  luck: number = 0,
): string | null {
  const possibleDrops = BOSS_EXCLUSIVE_DROPS.filter(
    d => d.bossId === bossId && floor >= d.minFloor,
  )

  if (possibleDrops.length === 0) return null

  // Luck bonus: +0.5% per LUK point, capped at +25%
  const luckBonus = Math.min(luck * 0.5, 25)

  for (const drop of possibleDrops) {
    const effectiveChance = drop.dropChance + luckBonus
    const roll = Math.random() * 100
    if (roll < effectiveChance) {
      return drop.itemKey
    }
  }

  return null
}

/**
 * Get set info for a specific item key (for display in item detail).
 */
export function getItemSetInfo(catalogKey: string): {
  setId: string
  setName: string
  pieces: string[]
  bonuses: SetBonusTier[]
} | null {
  const set = ITEM_SETS.find(s => s.pieces.includes(catalogKey))
  if (!set) return null
  return {
    setId: set.id,
    setName: set.name,
    pieces: set.pieces,
    bonuses: set.bonuses,
  }
}
