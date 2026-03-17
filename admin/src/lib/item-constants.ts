// Item types matching Prisma ItemType enum
export const ITEM_TYPES = [
  'weapon', 'helmet', 'chest', 'gloves', 'legs', 'boots',
  'accessory', 'amulet', 'belt', 'relic', 'necklace', 'ring', 'consumable',
] as const

export const RARITIES = ['common', 'uncommon', 'rare', 'epic', 'legendary'] as const

export const CLASS_RESTRICTIONS = ['none', 'warrior', 'mage', 'rogue'] as const

export const RARITY_COLORS: Record<string, string> = {
  common: 'bg-zinc-600/20 text-zinc-400 border-zinc-600',
  uncommon: 'bg-green-600/20 text-green-400 border-green-600',
  rare: 'bg-blue-600/20 text-blue-400 border-blue-600',
  epic: 'bg-purple-600/20 text-purple-400 border-purple-600',
  legendary: 'bg-orange-600/20 text-orange-400 border-orange-600',
}

export const RARITY_TEXT_COLORS: Record<string, string> = {
  common: 'text-zinc-400',
  uncommon: 'text-green-400',
  rare: 'text-blue-400',
  epic: 'text-purple-400',
  legendary: 'text-orange-400',
}

export const RARITY_BORDER_COLORS: Record<string, string> = {
  common: 'border-zinc-600',
  uncommon: 'border-green-600',
  rare: 'border-blue-600',
  epic: 'border-purple-600',
  legendary: 'border-orange-500',
}

// Catalog ID auto-generation
export const TYPE_PREFIXES: Record<string, string> = {
  weapon: 'wpn', helmet: 'hlm', chest: 'chs', gloves: 'glv',
  legs: 'lgs', boots: 'bts', accessory: 'acc', amulet: 'aml',
  belt: 'blt', relic: 'rlc', necklace: 'nkl', ring: 'rng',
  consumable: 'csm',
}

export function generateCatalogId(itemType: string, itemName: string): string {
  const prefix = TYPE_PREFIXES[itemType] ?? itemType.slice(0, 3)
  const slug = itemName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_|_$/g, '')
  return `${prefix}_${slug}`
}

// Base stat fields displayed in the Stats tab
// Must match backend StatKey: str, agi, vit, end, int, wis, luk, cha
export const STAT_KEYS = [
  { key: 'str', label: 'Strength' },
  { key: 'agi', label: 'Agility' },
  { key: 'vit', label: 'Vitality' },
  { key: 'end', label: 'Endurance' },
  { key: 'int', label: 'Intelligence' },
  { key: 'wis', label: 'Wisdom' },
  { key: 'luk', label: 'Luck' },
  { key: 'cha', label: 'Charisma' },
  { key: 'damageMin', label: 'Min Damage' },
  { key: 'damageMax', label: 'Max Damage' },
  { key: 'critChance', label: 'Crit Chance' },
  { key: 'attackSpeed', label: 'Attack Speed' },
  { key: 'defense', label: 'Defense' },
  { key: 'hpBonus', label: 'HP Bonus' },
  { key: 'manaBonus', label: 'Mana Bonus' },
] as const

export const SCALING_TYPES = ['linear', 'exponential', 'custom'] as const

export const UPGRADE_STAT_KEYS = [
  { key: 'damage', label: 'Damage +' },
  { key: 'str', label: 'Strength +' },
  { key: 'agi', label: 'Agility +' },
  { key: 'vit', label: 'Vitality +' },
  { key: 'end', label: 'Endurance +' },
  { key: 'int', label: 'Intelligence +' },
  { key: 'wis', label: 'Wisdom +' },
  { key: 'luk', label: 'Luck +' },
  { key: 'cha', label: 'Charisma +' },
  { key: 'crit', label: 'Crit +' },
  { key: 'defense', label: 'Defense +' },
] as const

export const IMAGE_STYLES = ['RPG Icon', 'Pixel', 'Fantasy Illustration'] as const
export const IMAGE_SIZES = ['64', '128', '256', '512', '1024'] as const

// Form data type
export type ItemFormData = {
  catalogId: string
  itemName: string
  itemType: string
  itemClass: string
  rarity: string
  itemLevel: number
  classRestriction: string
  setName: string
  stats: Record<string, number>
  maxUpgradeLevel: number
  scalingType: string
  upgradeScaling: Record<string, number>
  specialEffect: string
  uniquePassive: string
  buyPrice: number
  sellPrice: number
  dropChance: number
  imageUrl: string
  imageKey: string
  imagePrompt: string
  imageStyle: string
  imageSize: string
  description: string
}

export const EMPTY_FORM: ItemFormData = {
  catalogId: '',
  itemName: '',
  itemType: 'weapon',
  itemClass: '',
  rarity: 'common',
  itemLevel: 1,
  classRestriction: 'none',
  setName: '',
  stats: {},
  maxUpgradeLevel: 10,
  scalingType: 'linear',
  upgradeScaling: {},
  specialEffect: '',
  uniquePassive: '',
  buyPrice: 0,
  sellPrice: 0,
  dropChance: 0,
  imageUrl: '',
  imageKey: '',
  imagePrompt: '',
  imageStyle: '',
  imageSize: '',
  description: '',
}
