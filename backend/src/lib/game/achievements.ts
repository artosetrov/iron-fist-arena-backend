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
 *
 * Supports two modes per update:
 * - `absolute: false` (default) — progress += increment
 * - `absolute: true` — progress = increment (for streaks, ratings, levels)
 *
 * Loads all relevant achievements in one query, computes updates in memory,
 * then batch-writes all changes in a single transaction (eliminates N+1).
 */
export async function updateMultipleAchievements(
  prisma: PrismaClient,
  characterId: string,
  updates: { key: string; increment: number; absolute?: boolean }[],
): Promise<void> {
  // Filter to valid catalog keys only
  const validUpdates = updates.filter(u => ACHIEVEMENT_CATALOG[u.key]);
  if (validUpdates.length === 0) return;

  const keys = validUpdates.map(u => u.key);

  // Single query: load all relevant achievement rows at once
  const existing = await prisma.achievement.findMany({
    where: {
      characterId,
      achievementKey: { in: keys },
    },
  });

  const existingMap = new Map(existing.map(a => [a.achievementKey, a]));

  // Compute all writes in memory
  const dbUpdates: ReturnType<typeof prisma.achievement.update>[] = [];
  const dbCreates: ReturnType<typeof prisma.achievement.create>[] = [];

  for (const { key, increment, absolute } of validUpdates) {
    const catalogEntry = ACHIEVEMENT_CATALOG[key];
    const row = existingMap.get(key);

    if (row) {
      // Already completed — skip
      if (row.completed) continue;

      const rawProgress = absolute ? increment : row.progress + increment;
      const newProgress = Math.min(rawProgress, catalogEntry.target);
      const isNowComplete = newProgress >= catalogEntry.target;

      // Skip update if nothing changed
      if (newProgress === row.progress && !isNowComplete) continue;

      dbUpdates.push(
        prisma.achievement.update({
          where: { id: row.id },
          data: {
            progress: newProgress,
            completed: isNowComplete,
            completedAt: isNowComplete ? new Date() : null,
          },
        })
      );
    } else {
      // Create new achievement row
      const rawProgress = absolute ? increment : increment;
      const newProgress = Math.min(rawProgress, catalogEntry.target);
      const isNowComplete = newProgress >= catalogEntry.target;

      dbCreates.push(
        prisma.achievement.create({
          data: {
            characterId,
            achievementKey: key,
            progress: newProgress,
            target: catalogEntry.target,
            completed: isNowComplete,
            completedAt: isNowComplete ? new Date() : null,
          },
        })
      );
    }
  }

  // Single transaction for all writes
  const ops = [...dbUpdates, ...dbCreates];
  if (ops.length > 0) {
    await prisma.$transaction(ops);
  }
}
