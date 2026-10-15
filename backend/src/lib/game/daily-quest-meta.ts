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
  pvp_wins: { title: 'Warrior', description: (t) => (t === 1 ? 'Win a PvP battle' : `Win ${t} PvP battles`), icon: 'building-arena' },
  dungeons_complete: { title: 'Dungeon Crawler', description: (t) => (t === 1 ? 'Complete a dungeon' : `Complete ${t} dungeons`), icon: 'building-dungeon' },
  gold_spent: { title: 'Big Spender', description: (t) => `Spend ${t} gold`, icon: 'building-shop' },
  item_upgrade: { title: 'Blacksmith', description: (t) => (t === 1 ? 'Upgrade an item' : `Upgrade ${t} items`), icon: 'item-upgrade' },
  consumable_use: { title: 'Alchemist', description: (t) => (t === 1 ? 'Use a consumable' : `Use ${t} consumables`), icon: 'health-potion-medium' },
  shell_game_play: { title: 'Shell Game', description: (t) => (t === 1 ? 'Play the shell game' : `Play the shell game ${t} times`), icon: 'shell-cup' },
  gold_mine_collect: { title: 'Gold Miner', description: (t) => (t === 1 ? 'Collect from the gold mine' : `Collect from the gold mine ${t} times`), icon: 'building-gold-mine' },
}
