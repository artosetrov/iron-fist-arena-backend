import type { ConsumableType, PrismaClient } from '@prisma/client'
import { logTutorialEvent } from './tutorial-analytics'

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
  /** Starting gold for all new characters (enough to buy first gear) */
  baseGold: 500,
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

const REFERRAL_CODE_PATTERN = /^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8}$/

// ── Building unlock levels ────────────────────────────────────────────
// W2.D4 recalibration (2026-04-10): front-loaded schedule so the player
// receives a new unlock every ~2 levels in the early game. Reduces "empty
// hub" feeling and creates a clear dopamine beat at every level up.
//
// Progression intent:
//   Lv 1 → Arena + Shop (day-1 baseline, already starting)
//   Lv 2 → Achievements (first unlock ceremony fires ~5-10 min in)
//   Lv 4 → Dungeon (first PvE, was Lv3)
//   Lv 6 → Gold Mine (passive income, was Lv5) + Tavern (meta minigame, was Lv7)
//   Lv 8 → Battle Pass (paid progression, was Lv10)
//   Lv 12 → Guild Hall + Leaderboard (social layer, was Lv15)
//   Lv 99 → Black Market (route-less placeholder until a real runtime route ships)
//
// Keep this in sync with:
//   - Hexbound/Hexbound/Views/Components/BuildingLockOverlay.swift (BuildingUnlockConfig)
//   - docs/07_ui_ux/W2_D4_BUILDING_GATING_DESIGN.md
export const BUILDING_UNLOCK_LEVELS: Record<string, number> = {
  arena: 1,
  shop: 1,
  achievements: 2,
  dungeon: 4,
  gold_mine: 6,
  tavern: 6,
  battle_pass: 8,
  leaderboard: 8,
  guild: 12,
  black_market: 99, // route-less placeholder until a real runtime route ships
}

// ── Scripted tutorial fight rewards ───────────────────────────────────
// W2.D3 — first-victory reward package. Enough to feel meaningful, not
// enough to imbalance economy. Grant once, gated by character.tutorialCompleted.
export const TUTORIAL_FIGHT_REWARDS = {
  /** Gold awarded for completing the scripted tutorial fight. */
  gold: 150,
  /** XP awarded — tuned to push Lv1 character to Lv2 immediately. */
  xp: 50,
  /**
   * First-weapon item catalog key — must exist in item-catalog.
   * Same item for all classes for simplicity (an iron sword carries
   * universal "starter gear" energy regardless of class).
   */
  itemCatalogKey: 'wpn_iron_sword_tutorial',
  /** Rate limit window for resolve endpoint (3 attempts per 60s). */
  rateLimit: {
    max: 3,
    windowMs: 60_000,
  },
} as const

/** Whether a building is unlocked at the given character level. */
export function isBuildingUnlocked(buildingKey: string, characterLevel: number): boolean {
  const requiredLevel = BUILDING_UNLOCK_LEVELS[buildingKey]
  if (requiredLevel === undefined) return true // unknown key = default visible
  return characterLevel >= requiredLevel
}

/**
 * List all buildings that unlock at a specific level.
 * Used by /api/character/level-up endpoint to include `unlocks` in response,
 * which drives the LevelUpModal + BuildingUnlockCeremony on iOS.
 */
export function getBuildingsUnlockedAt(characterLevel: number): string[] {
  return Object.entries(BUILDING_UNLOCK_LEVELS)
    .filter((entry) => entry[1] === characterLevel)
    .map((entry) => entry[0])
    .sort()
}

// ── NPC Quest definitions ─────────────────────────────────────────────
export interface TutorialQuestRewards {
  gold?: number
  item_catalog_id?: string
  consumable_type?: ConsumableType
  consumable_amount?: number
  instant_mine?: boolean
  bp_levels?: number
}

export interface TutorialQuestDef {
  id: string
  unlockLevel: number
  title: string
  npcMessage: string
  target: number
  rewards: TutorialQuestRewards
}

type ReferralQualificationCharacterReader = {
  findUnique(args: {
    where: { id: string }
    select: {
      referredBy: true
    }
  }): Promise<{ referredBy: string | null } | null>
  findFirst(args: {
    where: {
      OR: Array<{ id?: string; referralCode?: string }>
    }
    select: {
      id: true
      userId: true
      referralCode: true
    }
  }): Promise<{ id: string; userId: string; referralCode: string | null } | null>
}

type ReferralQualificationUserWriter = {
  update(args: {
    where: { id: string }
    data: {
      gold?: { increment: number }
      gems?: { increment: number }
    }
  }): Promise<unknown>
}

type ReferralQualificationClaimWriter = {
  create(args: {
    data: {
      referrerCharacterId: string
      inviteeCharacterId: string
    }
  }): Promise<unknown>
}

export type ReferralQualificationExecutor = {
  character: ReferralQualificationCharacterReader
  user: ReferralQualificationUserWriter
  referralRewardClaim: ReferralQualificationClaimWriter
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

// ── Helper: update tutorial quest progress (fire-and-forget) ─────────
/**
 * Increment tutorial quest progress for a character.
 *
 * - Finds the TutorialQuest row matching characterId + questId.
 * - If found and not yet completed, atomically increments progress.
 * - Auto-marks as completed when progress >= target.
 * - Does nothing if quest doesn't exist yet (quest auto-created at unlock level).
 * - Silently swallows errors (non-critical path).
 *
 * Call this from game endpoints after the relevant action succeeds,
 * OUTSIDE the main transaction (same pattern as updateDailyQuestProgress).
 */
export async function updateTutorialQuestProgress(
  prisma: PrismaClient,
  characterId: string,
  questId: string,
  increment: number = 1,
): Promise<void> {
  try {
    // Atomic increment using raw SQL to prevent race conditions
    await prisma.$executeRawUnsafe(
      `UPDATE "tutorial_quests"
       SET "progress" = LEAST("progress" + $1, "target"),
           "is_completed" = CASE WHEN LEAST("progress" + $1, "target") >= "target" THEN true ELSE false END,
           "completed_at" = CASE WHEN LEAST("progress" + $1, "target") >= "target" AND "completed_at" IS NULL THEN NOW() ELSE "completed_at" END
       WHERE "character_id" = $2
         AND "quest_id" = $3
         AND "is_completed" = false`,
      increment,
      characterId,
      questId,
    )
  } catch (error) {
    // Non-critical: log but don't throw
    console.error(`tutorial quest progress error [${questId}]:`, error)
  }
}

// ── Helper: generate referral code ────────────────────────────────────
export function generateReferralCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789' // no 0/O/1/I confusion
  let code = ''
  for (let i = 0; i < 8; i++) {
    code += chars[Math.floor(Math.random() * chars.length)]
  }
  return code
}

export function normalizeReferralCode(code: string): string {
  return code.toUpperCase().trim()
}

export function getReferralLinkValues(referrerId: string, referralCode: string): string[] {
  return Array.from(new Set([referrerId, normalizeReferralCode(referralCode)]))
}

export function isReferralCodeLike(value: string | null | undefined): boolean {
  return typeof value === 'string' && REFERRAL_CODE_PATTERN.test(value.trim().toUpperCase())
}

export interface ReferralQualificationReward {
  referrerCharacterId: string
  referrerReferralCode: string | null
  goldAwarded: number
  gemsAwarded: number
}

export async function awardReferralQualificationIfEligible(
  tx: ReferralQualificationExecutor,
  inviteeCharacterId: string,
  newLevel: number,
): Promise<ReferralQualificationReward | null> {
  if (newLevel < REFERRAL_BONUS.inviteeLevelThreshold) {
    return null
  }

  const invitee = await tx.character.findUnique({
    where: { id: inviteeCharacterId },
    select: { referredBy: true },
  })

  if (!invitee?.referredBy) {
    return null
  }

  const referrerLookup = normalizeReferralCode(invitee.referredBy)
  const referrer = await tx.character.findFirst({
    where: {
      OR: [
        { id: invitee.referredBy },
        { referralCode: referrerLookup },
      ],
    },
    select: {
      id: true,
      userId: true,
      referralCode: true,
    },
  })

  if (!referrer || referrer.id === inviteeCharacterId) {
    return null
  }

  try {
    await tx.referralRewardClaim.create({
      data: {
        referrerCharacterId: referrer.id,
        inviteeCharacterId,
      },
    })
  } catch (error) {
    const duplicateCode = (error as { code?: string } | null)?.code
    if (duplicateCode === 'P2002') {
      return null
    }
    throw error
  }

  const currencyUpdate: {
    gold?: { increment: number }
    gems?: { increment: number }
  } = {}
  if (REFERRAL_BONUS.referrerGold > 0) {
    currencyUpdate.gold = { increment: REFERRAL_BONUS.referrerGold }
  }
  if (REFERRAL_BONUS.referrerGems > 0) {
    currencyUpdate.gems = { increment: REFERRAL_BONUS.referrerGems }
  }

  if (Object.keys(currencyUpdate).length > 0) {
    await tx.user.update({
      where: { id: referrer.userId },
      data: currencyUpdate,
    })
  }

  logTutorialEvent({
    event: 'referral_qualified',
    characterId: inviteeCharacterId,
    referrerCharacterId: referrer.id,
    referrerCode: referrer.referralCode,
    qualifiedLevel: newLevel,
    rewardGold: REFERRAL_BONUS.referrerGold,
    rewardGems: REFERRAL_BONUS.referrerGems,
  })

  return {
    referrerCharacterId: referrer.id,
    referrerReferralCode: referrer.referralCode,
    goldAwarded: REFERRAL_BONUS.referrerGold,
    gemsAwarded: REFERRAL_BONUS.referrerGems,
  }
}
