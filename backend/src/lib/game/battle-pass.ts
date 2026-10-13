import type { PrismaClient } from '@prisma/client'
import { prisma } from '@/lib/prisma'

export const SEASON_LENGTH_DAYS = 90

/**
 * Lazy season rollover (AUDIT-2026-10-13 H13).
 *
 * Seasons are seeded for 90 days with no scheduler; on day 91 every
 * battle-pass route answered 404 "No active season" and the building went
 * dark. This finds the active season, and when there is none, creates
 * `Season N+1` starting now (same length, rewards cloned from the most
 * recent season as a template). Serialized with a Postgres advisory lock so
 * concurrent requests cannot create two seasons.
 *
 * Returns null only when there is no previous season to clone from (fresh
 * DB — run `prisma/seed-battle-pass.ts`).
 */
export async function getOrRolloverActiveSeason() {
  const now = new Date()
  const active = await prisma.season.findFirst({
    where: { startAt: { lte: now }, endAt: { gte: now } },
  })
  if (active) return active

  return prisma.$transaction(async (tx) => {
    // Global lock key; released at transaction end.
    await tx.$executeRawUnsafe(`SELECT pg_advisory_xact_lock(7390001)`)

    // Re-check under the lock.
    const again = await tx.season.findFirst({
      where: { startAt: { lte: now }, endAt: { gte: now } },
    })
    if (again) return again

    const latest = await tx.season.findFirst({ orderBy: { number: 'desc' } })
    if (!latest) return null

    const endAt = new Date(now.getTime() + SEASON_LENGTH_DAYS * 24 * 60 * 60 * 1000)
    const next = await tx.season.create({
      data: {
        number: latest.number + 1,
        theme: latest.theme,
        startAt: now,
        endAt,
      },
    })

    const rewards = await tx.battlePassReward.findMany({
      where: { seasonId: latest.id },
      select: { bpLevel: true, isPremium: true, rewardType: true, rewardId: true, rewardAmount: true },
    })
    if (rewards.length > 0) {
      await tx.battlePassReward.createMany({
        data: rewards.map((r) => ({ ...r, seasonId: next.id })),
      })
    }

    console.log(`[battle-pass] rolled over to season ${next.number} (${rewards.length} rewards cloned from season ${latest.number})`)
    return next
  })
}

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
