// =============================================================================
// milestones.ts — Level milestone rewards (one-time per ACCOUNT)
//
// Major milestones (10, 15, 20, 25, 30, 35, 40, 50) carry a title and the big
// payout. The 2026-10-14 balance batch tripled the XP curve, which turned the
// gaps between them (16–19, 22–24, 26–29, 31–34, 36–39, 41–44, 46–49) into
// multi-day stretches where a level-up gave 3 stat points and nothing else.
// Minor milestones (12, 18, 22, 27, 32, 37, 42, 45, 47) fill those gaps with a
// small, gem-leaning drip, so the ladder pays out every 2–3 levels. They carry
// no title. Totals over 1→50: majors 34 500 gold / 520 gems, minors
// 13 000 gold / 185 gems — the minor drip is ~38% of the majors' gold,
// deliberately small so the ladder does not become a gold faucet
// (gold surplus was the audit's finding; gems were the scarce currency).
// =============================================================================

import { PrismaClient } from '@prisma/client'

export interface MilestoneReward {
  gold: number
  gems: number
  title?: string  // flavor title unlocked at this milestone
  description: string
}

export interface MilestoneDefinition {
  level: number
  reward: MilestoneReward
}

// --- Milestone Definitions ---

export const MILESTONES: MilestoneDefinition[] = [
  {
    level: 10,
    reward: {
      gold: 1000,
      gems: 20,
      title: 'Adventurer',
      description: 'You have proven yourself worthy. The realm takes notice.',
    },
  },
  {
    level: 12,
    reward: {
      gold: 400,
      gems: 10,
      description: 'The road ahead is long. A small purse for the journey.',
    },
  },
  {
    level: 15,
    reward: {
      gold: 1500,
      gems: 25,
      title: 'Veteran',
      description: 'Battle-hardened and ready for greater challenges.',
    },
  },
  {
    level: 18,
    reward: {
      gold: 600,
      gems: 10,
      description: 'Scars are starting to tell a story.',
    },
  },
  {
    level: 20,
    reward: {
      gold: 2500,
      gems: 40,
      title: 'Champion',
      description: 'A true champion emerges from the ranks.',
    },
  },
  {
    level: 22,
    reward: {
      gold: 800,
      gems: 15,
      description: 'The arena remembers your name now.',
    },
  },
  {
    level: 25,
    reward: {
      gold: 3000,
      gems: 50,
      title: 'Warlord',
      description: 'Your legend spreads across the battlefield.',
    },
  },
  {
    level: 27,
    reward: {
      gold: 1000,
      gems: 15,
      description: 'Steel sharpened, resolve sharper.',
    },
  },
  {
    level: 30,
    reward: {
      gold: 4000,
      gems: 60,
      title: 'Overlord',
      description: 'Few dare challenge your authority.',
    },
  },
  {
    level: 32,
    reward: {
      gold: 1200,
      gems: 20,
      description: 'Halfway to the summit, and still climbing.',
    },
  },
  {
    level: 35,
    reward: {
      gold: 5000,
      gems: 75,
      title: 'Grandmaster',
      description: 'Mastery of combat achieved. The final trials await.',
    },
  },
  {
    level: 37,
    reward: {
      gold: 1500,
      gems: 20,
      description: 'Lesser fighters step aside when you pass.',
    },
  },
  {
    level: 40,
    reward: {
      gold: 7500,
      gems: 100,
      title: 'Mythic',
      description: 'Your name is whispered in legends.',
    },
  },
  {
    level: 42,
    reward: {
      gold: 2000,
      gems: 25,
      description: 'Beyond mythic, the air grows thin.',
    },
  },
  {
    level: 45,
    reward: {
      gold: 2500,
      gems: 30,
      description: 'The last stretch. Nothing is given here.',
    },
  },
  {
    level: 47,
    reward: {
      gold: 3000,
      gems: 40,
      description: 'Ascension is within reach.',
    },
  },
  {
    level: 50,
    reward: {
      gold: 10000,
      gems: 150,
      title: 'Ascended',
      description: 'You have transcended mortal limits.',
    },
  },
]

/**
 * Check and award pending milestone rewards after a level-up.
 * Returns the list of milestones claimed (usually 0 or 1).
 */
function isUniqueViolation(error: unknown): boolean {
  return typeof error === 'object' && error !== null && (error as { code?: string }).code === 'P2002'
}

export async function checkAndAwardMilestones(
  prisma: PrismaClient,
  characterId: string,
  currentLevel: number,
): Promise<{ level: number; reward: MilestoneReward }[]> {
  // Get character's userId for gem awards
  const char = await prisma.character.findUnique({
    where: { id: characterId },
    select: { userId: true },
  })
  if (!char) return []

  // Claimed milestones for this ACCOUNT. Rewards are account currency, so a
  // second character crossing L10 must not pay the wallet again.
  const claimed = await prisma.milestoneClaim.findMany({
    where: { userId: char.userId },
    select: { milestoneLevel: true },
  })
  const claimedLevels = new Set(claimed.map(c => c.milestoneLevel))

  // Find all unclaimed milestones at or below current level
  const pendingMilestones = MILESTONES.filter(
    m => m.level <= currentLevel && !claimedLevels.has(m.level),
  )

  if (pendingMilestones.length === 0) return []

  // Award all pending milestones in one transaction
  const awarded: { level: number; reward: MilestoneReward }[] = []

  await prisma.$transaction(async (tx) => {
    let totalGold = 0
    let totalGems = 0

    for (const milestone of pendingMilestones) {
      // Create claim record. The (user, level) unique is the real guard: two
      // characters of one account levelling at the same moment (two devices)
      // both pass the read above, and the second insert must lose quietly
      // rather than fail that fight's level-up.
      try {
        await tx.milestoneClaim.create({
          data: {
            userId: char.userId,
            characterId,
            milestoneLevel: milestone.level,
          },
        })
      } catch (error) {
        if (isUniqueViolation(error)) continue
        throw error
      }

      totalGold += milestone.reward.gold
      totalGems += milestone.reward.gems
      awarded.push({ level: milestone.level, reward: milestone.reward })
    }

    // Bulk award gold and gems to user (account-level currency)
    const currencyUpdate: Record<string, { increment: number }> = {}
    if (totalGold > 0) currencyUpdate.gold = { increment: totalGold }
    if (totalGems > 0) currencyUpdate.gems = { increment: totalGems }
    if (Object.keys(currencyUpdate).length > 0) {
      await tx.user.update({
        where: { id: char.userId },
        data: currencyUpdate,
      })
    }
  })

  return awarded
}

/**
 * Get all milestones with claim status for a character.
 */
export async function getMilestoneStatus(
  prisma: PrismaClient,
  characterId: string,
  currentLevel: number,
): Promise<{
  milestones: (MilestoneDefinition & { claimed: boolean; available: boolean })[]
}> {
  const char = await prisma.character.findUnique({
    where: { id: characterId },
    select: { userId: true },
  })
  const claimed = char
    ? await prisma.milestoneClaim.findMany({
        where: { userId: char.userId },
        select: { milestoneLevel: true },
      })
    : []
  const claimedLevels = new Set(claimed.map(c => c.milestoneLevel))

  return {
    milestones: MILESTONES.map(m => ({
      ...m,
      claimed: claimedLevels.has(m.level),
      available: m.level <= currentLevel && !claimedLevels.has(m.level),
    })),
  }
}
