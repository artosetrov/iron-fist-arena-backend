// =============================================================================
// dungeon-rush.ts — Dungeon Rush room system logic
// =============================================================================

import type { CharacterStats } from './combat'
import type { Enemy } from './dungeon'

// --- Room Types ---

export type RushRoomType = 'combat' | 'elite' | 'miniboss' | 'treasure' | 'event' | 'shop'

export interface RushRoom {
  index: number
  type: RushRoomType
  resolved: boolean
  seed: number
}

// Fixed 12-room layout
const ROOM_LAYOUT: RushRoomType[] = [
  'combat',   // 0
  'event',    // 1
  'combat',   // 2
  'treasure', // 3
  'elite',    // 4
  'miniboss', // 5
  'shop',     // 6
  'combat',   // 7
  'event',    // 8
  'elite',    // 9
  'combat',   // 10
  'miniboss', // 11
]

// --- Buff Definitions ---

export interface RushBuff {
  id: string
  name: string
  stat: string
  value: number
  icon: string
  shopPrice: number
}

export const RUSH_BUFFS: RushBuff[] = [
  { id: 'buff_str_15', name: "Warrior's Might", stat: 'str', value: 15, icon: '🗡️', shopPrice: 100 },
  { id: 'buff_agi_15', name: 'Shadow Step', stat: 'agi', value: 15, icon: '💨', shopPrice: 100 },
  { id: 'buff_armor_20', name: 'Iron Skin', stat: 'armor', value: 20, icon: '🛡️', shopPrice: 100 },
  { id: 'buff_crit_10', name: 'Eagle Eye', stat: 'crit', value: 10, icon: '🎯', shopPrice: 120 },
  { id: 'buff_luk_20', name: "Fortune's Favor", stat: 'luk', value: 20, icon: '🍀', shopPrice: 80 },
  { id: 'buff_maxhp_150', name: "Titan's Vigor", stat: 'maxHp', value: 150, icon: '❤️', shopPrice: 120 },
]

// Heal available in shop
export const RUSH_SHOP_HEAL = {
  name: 'Healing Potion',
  icon: '💧',
  hpPercent: 50, // restores 50% HP
  price: 80,
}

// --- Event Definitions ---

export interface RushEvent {
  id: string
  name: string
  icon: string
  description: string
}

export const RUSH_EVENTS: RushEvent[] = [
  { id: 'healing_spring', name: 'Healing Spring', icon: '💧', description: 'A magical spring restores your health. +30% HP' },
  { id: 'gold_cache', name: 'Hidden Gold Cache', icon: '💰', description: 'You found a hidden stash of gold!' },
  { id: 'ancient_blessing', name: 'Ancient Blessing', icon: '✨', description: 'An ancient power blesses you with a random buff.' },
  { id: 'trapped_chest', name: 'Trapped Chest', icon: '💣', description: 'A trapped chest! You take damage but find gold.' },
  { id: 'wandering_merchant', name: 'Wandering Merchant', icon: '🧙', description: 'A kind merchant gifts you a free buff.' },
  { id: 'dark_shrine', name: 'Dark Shrine', icon: '🔮', description: 'Dark energy empowers your strength. +15 STR' },
  { id: 'lucky_coin', name: 'Lucky Coin', icon: '🍀', description: 'A lucky coin boosts your fortune. +20 LUK' },
  { id: 'rest_camp', name: 'Rest Camp', icon: '🏕️', description: 'You rest by a campfire. +20% HP and some XP.' },
  { id: 'armory_find', name: 'Armory Find', icon: '⚔️', description: 'Hidden weapons sharpen your reflexes. +15 AGI' },
  { id: 'mysterious_potion', name: 'Mysterious Potion', icon: '🧪', description: 'A mysterious potion... could be good or bad.' },
]

// --- State Interface ---

export interface RushState {
  rooms: RushRoom[]
  currentRoomIndex: number
  buffs: { id: string; name: string; stat: string; value: number; icon: string }[]
  currentHpPercent: number
  shopPurchased: number[]
  floorsCleared: number
  totalGoldEarned: number
  totalXpEarned: number
}

// --- Room Generation ---

export function generateRushRooms(): RushRoom[] {
  return ROOM_LAYOUT.map((type, index) => ({
    index,
    type,
    resolved: false,
    seed: Math.floor(Math.random() * 2147483647),
  }))
}

export function createInitialRushState(): RushState {
  return {
    rooms: generateRushRooms(),
    currentRoomIndex: 0,
    buffs: [],
    currentHpPercent: 100,
    shopPurchased: [],
    floorsCleared: 0,
    totalGoldEarned: 0,
    totalXpEarned: 0,
  }
}

// --- Enemy Generation ---

function generateId(): string {
  return `rush_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`
}

const RUSH_ENEMY_NAMES = [
  'Dungeon Rat', 'Goblin Scout', 'Skeleton Warrior', 'Cave Troll',
  'Dark Imp', 'Undead Soldier', 'Shadow Wolf', 'Cursed Bandit',
  'Feral Ghoul', 'Stone Golem', 'Flame Sprite', 'Ice Wraith',
]

const RUSH_ELITE_NAMES = [
  'Elite Guard', 'Veteran Knight', 'Shadow Assassin', 'Arcane Sentinel',
  'Iron Juggernaut', 'Plague Brute', 'Void Stalker', 'Crimson Reaver',
]

const RUSH_BOSS_NAMES = [
  'Warden of the Depths', 'Lord of Shadows', 'The Bone King',
  'Abyssal Overlord', 'Champion of Decay', 'The Iron Tyrant',
]

/**
 * Generate an enemy for a rush room based on room index and type.
 * Combat: 1.0x multiplier
 * Elite: 1.5x multiplier
 * Miniboss: 2.0x multiplier
 */
export function generateRushEnemy(roomIndex: number, roomType: RushRoomType, seed: number): Enemy {
  const effectiveLevel = Math.round((roomIndex + 1) * 1.5)

  let statMultiplier: number
  let name: string

  switch (roomType) {
    case 'elite':
      statMultiplier = 1.5
      name = RUSH_ELITE_NAMES[seed % RUSH_ELITE_NAMES.length]
      break
    case 'miniboss':
      statMultiplier = 2.0
      name = RUSH_BOSS_NAMES[seed % RUSH_BOSS_NAMES.length]
      break
    default: // combat
      statMultiplier = 1.0
      name = RUSH_ENEMY_NAMES[seed % RUSH_ENEMY_NAMES.length]
      break
  }

  return {
    id: generateId(),
    name,
    level: effectiveLevel,
    maxHp: Math.round((150 + effectiveLevel * 40) * statMultiplier),
    str: Math.round((8 + effectiveLevel * 2) * statMultiplier),
    agi: Math.round((6 + effectiveLevel * 1.5) * statMultiplier),
    armor: Math.round((5 + effectiveLevel * 1.8) * statMultiplier),
    magicResist: Math.round((4 + effectiveLevel * 1.3) * statMultiplier),
    isBoss: roomType === 'miniboss',
  }
}

// --- Reward Formulas ---

export interface RushRewards {
  gold: number
  xp: number
  lootDifficulty: string
}

export function getRoomRewards(roomIndex: number, roomType: RushRoomType): RushRewards {
  switch (roomType) {
    case 'combat':
      return {
        gold: 50 + roomIndex * 15,
        xp: 35 + roomIndex * 12,
        lootDifficulty: 'dungeon_normal', // 30%
      }
    case 'elite':
      return {
        gold: 75 + roomIndex * 20,
        xp: 50 + roomIndex * 15,
        lootDifficulty: 'dungeon_hard', // 40%
      }
    case 'miniboss':
      return {
        gold: 100 + roomIndex * 25,
        xp: 70 + roomIndex * 18,
        lootDifficulty: 'boss', // 75%
      }
    default:
      return { gold: 0, xp: 0, lootDifficulty: 'dungeon_normal' }
  }
}

/** Gold from a treasure room */
export function treasureGoldReward(roomIndex: number): number {
  return 60 + roomIndex * 20
}

// --- Buff Application ---

/**
 * Apply rush buffs to player CharacterStats before combat.
 * Buffs modify stats additively. Does not stack same buff.
 */
export function applyRushBuffs(
  stats: CharacterStats,
  buffs: { stat: string; value: number }[],
): CharacterStats {
  const modified = { ...stats }

  for (const buff of buffs) {
    switch (buff.stat) {
      case 'str':
        modified.str += buff.value
        break
      case 'agi':
        modified.agi += buff.value
        break
      case 'armor':
        modified.armor += buff.value
        break
      case 'luk':
        modified.luk += buff.value
        break
      case 'maxHp':
        modified.maxHp += buff.value
        break
      // 'crit' is handled specially — we store it and apply in combat via stance
      case 'crit':
        // Add crit via combatStance modification
        {
          const stance = (modified.combatStance ?? {}) as Record<string, unknown>
          const existing = typeof stance.crit === 'number' ? stance.crit : 0
          modified.combatStance = { ...stance, crit: existing + buff.value }
        }
        break
    }
  }

  return modified
}

// --- Event Resolution ---

export interface EventResult {
  eventId: string
  eventName: string
  eventIcon: string
  description: string
  hpChange: number // percent change (+30 means +30% of maxHP)
  goldReward: number
  xpReward: number
  buffGranted: { id: string; name: string; stat: string; value: number; icon: string } | null
}

export function resolveEvent(roomIndex: number, seed: number): EventResult {
  const eventIndex = seed % RUSH_EVENTS.length
  const event = RUSH_EVENTS[eventIndex]
  const result: EventResult = {
    eventId: event.id,
    eventName: event.name,
    eventIcon: event.icon,
    description: event.description,
    hpChange: 0,
    goldReward: 0,
    xpReward: 0,
    buffGranted: null,
  }

  switch (event.id) {
    case 'healing_spring':
      result.hpChange = 30
      break
    case 'gold_cache':
      result.goldReward = 80 + roomIndex * 10
      break
    case 'ancient_blessing': {
      // Random buff from pool
      const buffIdx = (seed >> 8) % RUSH_BUFFS.length
      const buff = RUSH_BUFFS[buffIdx]
      result.buffGranted = { id: buff.id, name: buff.name, stat: buff.stat, value: buff.value, icon: buff.icon }
      break
    }
    case 'trapped_chest':
      result.hpChange = -15
      result.goldReward = 50 + roomIndex * 15
      break
    case 'wandering_merchant': {
      // Free random buff
      const buffIdx = (seed >> 4) % RUSH_BUFFS.length
      const buff = RUSH_BUFFS[buffIdx]
      result.buffGranted = { id: buff.id, name: buff.name, stat: buff.stat, value: buff.value, icon: buff.icon }
      break
    }
    case 'dark_shrine':
      result.buffGranted = { id: 'buff_str_15', name: "Warrior's Might", stat: 'str', value: 15, icon: '🗡️' }
      break
    case 'lucky_coin':
      result.buffGranted = { id: 'buff_luk_20', name: "Fortune's Favor", stat: 'luk', value: 20, icon: '🍀' }
      break
    case 'rest_camp':
      result.hpChange = 20
      result.xpReward = 15
      break
    case 'armory_find':
      result.buffGranted = { id: 'buff_agi_15', name: 'Shadow Step', stat: 'agi', value: 15, icon: '💨' }
      break
    case 'mysterious_potion': {
      // 60% good (+40% HP), 40% bad (-10% HP)
      const roll = (seed >> 12) % 100
      if (roll < 60) {
        result.hpChange = 40
        result.description = 'The potion heals your wounds! +40% HP'
      } else {
        result.hpChange = -10
        result.description = 'The potion burns! -10% HP'
      }
      break
    }
  }

  return result
}

// --- Shop Generation ---

export interface ShopItem {
  slot: number
  type: 'buff' | 'heal'
  buffId?: string
  name: string
  icon: string
  description: string
  price: number
  stat?: string
  value?: number
}

export function generateShopItems(seed: number): ShopItem[] {
  const items: ShopItem[] = []

  // Slot 0: random buff
  const buff1Idx = seed % RUSH_BUFFS.length
  const buff1 = RUSH_BUFFS[buff1Idx]
  items.push({
    slot: 0,
    type: 'buff',
    buffId: buff1.id,
    name: buff1.name,
    icon: buff1.icon,
    description: `+${buff1.value} ${buff1.stat}`,
    price: buff1.shopPrice,
    stat: buff1.stat,
    value: buff1.value,
  })

  // Slot 1: another buff (different from slot 0)
  const buff2Idx = (seed >> 8) % RUSH_BUFFS.length
  const adjustedIdx = buff2Idx === buff1Idx ? (buff2Idx + 1) % RUSH_BUFFS.length : buff2Idx
  const buff2 = RUSH_BUFFS[adjustedIdx]
  items.push({
    slot: 1,
    type: 'buff',
    buffId: buff2.id,
    name: buff2.name,
    icon: buff2.icon,
    description: `+${buff2.value} ${buff2.stat}`,
    price: buff2.shopPrice,
    stat: buff2.stat,
    value: buff2.value,
  })

  // Slot 2: heal
  items.push({
    slot: 2,
    type: 'heal',
    name: RUSH_SHOP_HEAL.name,
    icon: RUSH_SHOP_HEAL.icon,
    description: `Restore ${RUSH_SHOP_HEAL.hpPercent}% HP`,
    price: RUSH_SHOP_HEAL.price,
  })

  return items
}

// --- HP Management ---

/** Apply HP change as a percentage (capped at 100, min 1) */
export function adjustHpPercent(current: number, change: number): number {
  return Math.max(1, Math.min(100, current + change))
}

/** Calculate effective HP for combat given maxHp and currentHpPercent */
export function effectiveHp(maxHp: number, hpPercent: number): number {
  return Math.max(1, Math.round(maxHp * hpPercent / 100))
}

/** Calculate new HP% after combat given remaining HP and max HP */
export function hpPercentAfterCombat(remainingHp: number, maxHp: number): number {
  return Math.max(1, Math.min(100, Math.round(remainingHp / maxHp * 100)))
}

// --- Helpers ---

export function isCombatRoom(type: RushRoomType): boolean {
  return type === 'combat' || type === 'elite' || type === 'miniboss'
}

export const TOTAL_RUSH_ROOMS = ROOM_LAYOUT.length
