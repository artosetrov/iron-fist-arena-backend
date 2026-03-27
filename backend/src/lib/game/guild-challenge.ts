// =============================================================================
// guild-challenge.ts — Server-wide weekly cooperative challenge
// All players contribute to a shared goal (e.g., 500 PvP wins this week)
// =============================================================================

import { PrismaClient } from '@prisma/client'

export type GuildGoalType = 'pvp_wins' | 'gold_earned' | 'dungeons_cleared' | 'items_upgraded' | 'bosses_killed';

export interface GuildChallengeConfig {
  title: string;
  description: string;
  goalType: GuildGoalType;
  goalTarget: number;
  goldReward: number;
  gemReward: number;
  durationDays: number;
}

// Weekly challenge templates — rotated automatically
export const WEEKLY_CHALLENGE_TEMPLATES: GuildChallengeConfig[] = [
  {
    title: 'Warpath',
    description: 'The realm needs warriors! Win PvP battles together.',
    goalType: 'pvp_wins',
    goalTarget: 500,
    goldReward: 2000,
    gemReward: 50,
    durationDays: 7,
  },
  {
    title: 'Gold Rush',
    description: 'Fill the war chest! Earn gold across all activities.',
    goalType: 'gold_earned',
    goalTarget: 100000,
    goldReward: 3000,
    gemReward: 30,
    durationDays: 7,
  },
  {
    title: 'Dungeon Crawl',
    description: 'Explore the depths! Clear dungeon floors together.',
    goalType: 'dungeons_cleared',
    goalTarget: 200,
    goldReward: 2500,
    gemReward: 40,
    durationDays: 7,
  },
  {
    title: 'Arms Race',
    description: 'Strengthen your arsenal! Upgrade items together.',
    goalType: 'items_upgraded',
    goalTarget: 300,
    goldReward: 2000,
    gemReward: 60,
    durationDays: 7,
  },
  {
    title: 'Boss Hunters',
    description: 'Slay the terrors of the deep! Defeat dungeon bosses.',
    goalType: 'bosses_killed',
    goalTarget: 150,
    goldReward: 3000,
    gemReward: 50,
    durationDays: 7,
  },
];

/**
 * Increment the active guild challenge progress.
 * Called from PvP, dungeon, upgrade routes.
 */
export async function incrementGuildChallenge(
  prisma: PrismaClient,
  goalType: GuildGoalType,
  amount: number = 1,
): Promise<void> {
  const now = new Date();

  // Find active challenge matching this goal type
  const challenge = await prisma.guildChallenge.findFirst({
    where: {
      goalType,
      completed: false,
      startAt: { lte: now },
      endAt: { gte: now },
    },
  });

  if (!challenge) return;

  // Atomic increment with cap
  await prisma.$executeRawUnsafe(
    `UPDATE guild_challenges SET current_progress = LEAST(current_progress + $1, goal_target), completed = (current_progress + $1 >= goal_target) WHERE id = $2`,
    amount,
    challenge.id,
  );
}

/**
 * Get the current active guild challenge.
 */
export async function getActiveGuildChallenge(prisma: PrismaClient) {
  const now = new Date();
  return prisma.guildChallenge.findFirst({
    where: {
      startAt: { lte: now },
      endAt: { gte: now },
    },
    orderBy: { startAt: 'desc' },
  });
}

/**
 * Create next week's guild challenge from templates.
 * Should be called by a cron job or admin action.
 */
export async function createWeeklyChallenge(prisma: PrismaClient): Promise<void> {
  const template = WEEKLY_CHALLENGE_TEMPLATES[
    Math.floor(Math.random() * WEEKLY_CHALLENGE_TEMPLATES.length)
  ];

  const now = new Date();
  const endAt = new Date(now.getTime() + template.durationDays * 24 * 60 * 60 * 1000);

  await prisma.guildChallenge.create({
    data: {
      title: template.title,
      description: template.description,
      goalType: template.goalType,
      goalTarget: template.goalTarget,
      currentProgress: 0,
      goldReward: template.goldReward,
      gemReward: template.gemReward,
      startAt: now,
      endAt,
    },
  });
}
