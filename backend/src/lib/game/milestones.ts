// =============================================================================
// milestones.ts — Level milestone rewards (one-time per character)
// Targets midgame levels (10, 15, 20, 25, 30, 35, 40, 50) to prevent dead zones
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
    level: 15,
    reward: {
      gold: 1500,
      gems: 25,
      title: 'Veteran',
      description: 'Battle-hardened and ready for greater challenges.',
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
    level: 25,
    reward: {
      gold: 3000,
      gems: 50,
      title: 'Warlord',
      description: 'Your legend spreads across the battlefield.',
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
    level: 35,
    reward: {
      gold: 5000,
      gems: 75,
      title: 'Grandmaster',
      description: 'Mastery of combat achieved. The final trials await.',
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
export async function checkAndAwardMilestones(
  prisma: PrismaClient,
  characterId: string,
  currentLevel: number,
): Promise<{ level: number; reward: MilestoneReward }[]> {
  // Get claimed milestones for this character
  const claimed = await prisma.milestoneClaim.findMany({
    where: { characterId },
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
      // Create claim record
      await tx.milestoneClaim.create({
        data: {
          characterId,
          milestoneLevel: milestone.level,
        },
      })

      totalGold += milestone.reward.gold
      totalGems += milestone.reward.gems
      awarded.push({ level: milestone.level, reward: milestone.reward })
    }

    // Bulk award currencies
    await tx.character.update({
      where: { id: characterId },
      data: {
        gold: { increment: totalGold },
        gems: { increment: totalGems },
      },
    })
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
  const claimed = await prisma.milestoneClaim.findMany({
    where: { characterId },
    select: { milestoneLevel: true },
  })
  const claimedLevels = new Set(claimed.map(c => c.milestoneLevel))

  return {
    milestones: MILESTONES.map(m => ({
      ...m,
      claimed: claimedLevels.has(m.level),
      available: m.level <= currentLevel && !claimedLevels.has(m.level),
    })),
  }
}
