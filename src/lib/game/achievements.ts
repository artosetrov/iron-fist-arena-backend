// =============================================================================
// achievements.ts — Achievement progress tracking (database-backed)
// =============================================================================

import type { PrismaClient } from '@prisma/client';
import { ACHIEVEMENT_CATALOG } from './achievement-catalog';

/**
 * Increment achievement progress for a character.
 *
 * - Finds or creates the achievement row for the given key.
 * - Increments progress by the given amount.
 * - Marks as completed if progress >= target.
 *
 * @param prisma       Prisma client instance
 * @param characterId  The character's UUID
 * @param key          Achievement key (must exist in ACHIEVEMENT_CATALOG)
 * @param increment    Amount to add to progress (default 1)
 */
export async function updateAchievementProgress(
  prisma: PrismaClient,
  characterId: string,
  key: string,
  increment: number = 1,
): Promise<void> {
  const catalogEntry = ACHIEVEMENT_CATALOG[key];
  if (!catalogEntry) {
    console.warn(`[achievements] Unknown achievement key: ${key}`);
    return;
  }

  const existing = await prisma.achievement.findUnique({
    where: {
      characterId_achievementKey: {
        characterId,
        achievementKey: key,
      },
    },
  });

  if (existing) {
    // Already completed — nothing to do
    if (existing.completed) {
      return;
    }

    const newProgress = Math.min(existing.progress + increment, catalogEntry.target);
    const isNowComplete = newProgress >= catalogEntry.target;

    await prisma.achievement.update({
      where: { id: existing.id },
      data: {
        progress: newProgress,
        completed: isNowComplete,
        completedAt: isNowComplete ? new Date() : null,
      },
    });
  } else {
    // Create new achievement row
    const newProgress = Math.min(increment, catalogEntry.target);
    const isNowComplete = newProgress >= catalogEntry.target;

    await prisma.achievement.create({
      data: {
        characterId,
        achievementKey: key,
        progress: newProgress,
        target: catalogEntry.target,
        completed: isNowComplete,
        completedAt: isNowComplete ? new Date() : null,
      },
    });
  }
}

/**
 * Bulk-check multiple achievement keys at once.
 * Useful after a PVP match where several counters might update.
 */
export async function updateMultipleAchievements(
  prisma: PrismaClient,
  characterId: string,
  updates: { key: string; increment: number }[],
): Promise<void> {
  for (const { key, increment } of updates) {
    await updateAchievementProgress(prisma, characterId, key, increment);
  }
}
