import type { PrismaClient } from '@prisma/client'

/**
 * Award Battle Pass XP to a character's active battle pass.
 * Silently no-ops if there's no active season or no battle pass.
 */
export async function awardBattlePassXp(
  tx: PrismaClient | Parameters<Parameters<PrismaClient['$transaction']>[0]>[0],
  characterId: string,
  amount: number
): Promise<void> {
  const now = new Date()

  const activeSeason = await (tx as PrismaClient).season.findFirst({
    where: { startAt: { lte: now }, endAt: { gte: now } },
  })
  if (!activeSeason) return

  const battlePass = await (tx as PrismaClient).battlePass.findFirst({
    where: { characterId, seasonId: activeSeason.id },
  })
  if (!battlePass) return

  await (tx as PrismaClient).battlePass.update({
    where: { id: battlePass.id },
    data: { bpXp: { increment: amount } },
  })
}
