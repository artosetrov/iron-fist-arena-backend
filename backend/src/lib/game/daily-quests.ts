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

  const quest = await prisma.dailyQuest.findFirst({
    where: {
      characterId,
      questType,
      day: today,
    },
  })

  if (!quest) return // no quest of this type today
  if (quest.progress >= quest.target) return // already complete

  const newProgress = Math.min(quest.progress + increment, quest.target)

  await prisma.dailyQuest.update({
    where: { id: quest.id },
    data: { progress: newProgress },
  })
}
