// =============================================================================
// daily-quests.ts — Daily quest progress tracking
// =============================================================================

import type { PrismaClient, QuestType } from '@prisma/client'

/**
 * Increment daily quest progress for a character.
 *
 * - Finds any daily quest for today matching the given quest type.
 * - If found and not yet fully completed, increments progress.
 * - Does nothing if no matching quest exists for today.
 *
 * Call this from game endpoints (PvP, dungeons, minigames, etc.)
 * after the relevant action succeeds.
 */
export async function updateDailyQuestProgress(
  prisma: PrismaClient,
  characterId: string,
  questType: QuestType,
  increment: number = 1,
): Promise<void> {
  const today = new Date().toISOString().slice(0, 10)

  // Atomic increment using raw SQL to prevent race conditions.
  // Multiple concurrent calls (e.g. using 3 consumables quickly) would all read
  // progress=0 with a findFirst+update pattern, resulting in progress=1 instead of 3.
  // This raw UPDATE atomically increments and caps at target in a single statement.
  await prisma.$executeRawUnsafe(
    `UPDATE "daily_quests"
     SET "progress" = LEAST("progress" + $1, "target")
     WHERE "character_id" = $2
       AND "quest_type" = $3::text::"QuestType"
       AND "day" = $4
       AND "progress" < "target"
       AND "completed" = false`,
    increment,
    characterId,
    questType,
    today,
  )
}
