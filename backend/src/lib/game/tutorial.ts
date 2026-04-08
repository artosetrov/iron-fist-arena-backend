/**
 * Tutorial & Onboarding — constants, quest definitions, and helper functions.
 *
 * Tutorial steps: 0=new → 1=weapon_equipped → 2=first_fight_won → 3=completed
 * After step 3, hard guided tutorial is done; NPC quest chain takes over.
 */

// ── Starter weapon mapping per class ──────────────────────────────────
export const STARTER_WEAPON_BY_CLASS: Record<string, string> = {
  warrior: 'wpn_rusty_sword',
  rogue: 'wpn_iron_dagger',
  mage: 'wpn_wooden_staff',
  tank: 'wpn_training_mace',
}

// ── Welcome gift amounts ──────────────────────────────────────────────
export const WELCOME_GIFT = {
  staminaBonus: 50,
  healthPotionCount: 2,
  healthPotionType: 'health_potion_small' as const,
}

// ── Referral bonus multipliers ────────────────────────────────────────
export const REFERRAL_BONUS = {
  /** Extra gold on top of base 500g default */
  extraGold: 250,
  /** Referrer gets this gold when invitee reaches level 5 */
  referrerGold: 500,
  /** Referrer gets this many gems */
  referrerGems: 10,
  /** Max referrals per character */
  maxReferrals: 20,
  /** Invitee level threshold for referrer reward */
  inviteeLevelThreshold: 5,
}

// ── Building unlock levels ────────────────────────────────────────────
export const BUILDING_UNLOCK_LEVELS: Record<string, number> = {
  arena: 1,
  shop: 1,
  dungeon: 3,
  gold_mine: 5,
  tavern: 7,
  battle_pass: 10,
  leaderboard: 10,
  guild: 15,
}

// ── NPC Quest definitions ─────────────────────────────────────────────
export interface TutorialQuestDef {
  id: string
  unlockLevel: number
  title: string
  npcMessage: string
  target: number
  rewards: {
    gold?: number
    item_catalog_id?: string
    consumable_type?: string
    consumable_amount?: number
    instant_mine?: boolean
    bp_levels?: number
  }
}

export const TUTORIAL_QUESTS: TutorialQuestDef[] = [
  {
    id: 'equip_gear',
    unlockLevel: 1,
    title: 'Снаряжение воина',
    npcMessage: 'У тебя есть оружие, но защита хромает. Загляни в Лавку — подбери себе доспех.',
    target: 1, // buy 1 item
    rewards: { gold: 200 },
  },
  {
    id: 'win_3_pvp',
    unlockLevel: 1,
    title: 'Боевая закалка',
    npcMessage: 'Один бой — это начало. Выиграй ещё 3 боя на арене чтобы набраться опыта.',
    target: 3, // win 3 PvP
    rewards: { gold: 300, consumable_type: 'health_potion_medium', consumable_amount: 1 },
  },
  {
    id: 'first_dungeon',
    unlockLevel: 3,
    title: 'Тьма подземелий',
    npcMessage: 'Под городом скрываются подземелья. Победи босса первого этажа.',
    target: 1, // complete dungeon floor 1
    rewards: { gold: 200 },
  },
  {
    id: 'start_mining',
    unlockLevel: 5,
    title: 'Золотая жила',
    npcMessage: 'Шахта приносит золото, пока ты спишь. Запусти добычу.',
    target: 1, // start 1 mining session
    rewards: { instant_mine: true },
  },
  {
    id: 'try_tavern',
    unlockLevel: 7,
    title: 'Испытай удачу',
    npcMessage: 'В таверне играют на золото. Shell Game — угадай где шарик. Попробуй разок.',
    target: 1, // play 1 shell game
    rewards: { gold: 100 },
  },
  {
    id: 'explore_endgame',
    unlockLevel: 10,
    title: 'Путь славы',
    npcMessage: 'Ты вырос. Боевой пропуск хранит сокровища. Таблица лидеров покажет на что ты способен.',
    target: 1, // open BP or leaderboard
    rewards: { bp_levels: 1 },
  },
  {
    id: 'join_guild',
    unlockLevel: 15,
    title: 'Братство',
    npcMessage: 'Одинокий волк далеко не уйдёт. Вступи в гильдию — или создай свою.',
    target: 1, // join a guild
    rewards: { gold: 500 },
  },
]

// ── Helper: generate referral code ────────────────────────────────────
export function generateReferralCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789' // no 0/O/1/I confusion
  let code = ''
  for (let i = 0; i < 8; i++) {
    code += chars[Math.floor(Math.random() * chars.length)]
  }
  return code
}
