import type { QuestType } from '@prisma/client'

export type QuestMetaEntry = {
  title: string
  description: (target: number) => string
  icon: string
}

export type QuestMetaMap = Record<QuestType, QuestMetaEntry>

/**
 * Human-readable daily-quest copy by type. Fallback for the live-config
 * override in /api/quests/daily, and the only source for screens that just
 * need to name a quest (session summary).
 */
export const QUEST_META: QuestMetaMap = {
  pvp_wins: { title: 'Warrior', description: (t) => `Win ${t} PvP battles`, icon: 'building-arena' },
  dungeons_complete: { title: 'Dungeon Crawler', description: (t) => `Complete ${t} dungeons`, icon: 'building-dungeon' },
  gold_spent: { title: 'Big Spender', description: (t) => `Spend ${t} gold`, icon: 'building-shop' },
  item_upgrade: { title: 'Blacksmith', description: (t) => `Upgrade ${t} items`, icon: 'item-upgrade' },
  consumable_use: { title: 'Alchemist', description: (t) => `Use ${t} consumables`, icon: 'health-potion-medium' },
  shell_game_play: { title: 'Shell Game', description: (t) => `Play shell game ${t} times`, icon: 'shell-cup' },
  gold_mine_collect: { title: 'Gold Miner', description: (t) => `Collect from gold mine ${t} times`, icon: 'building-gold-mine' },
}
