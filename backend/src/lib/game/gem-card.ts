import { prisma } from '@/lib/prisma'
import { MONTHLY_GEM_CARD } from './balance'

/**
 * Lazy daily payout for the Monthly Gem Card.
 *
 * One conditional UPDATE claims "today" for the card (UTC day, atomic — two
 * concurrent /game/init calls cannot both match), then the gems are credited.
 * Returns the gems granted (0 when nothing was due). Safe to call on every
 * launch.
 */
export async function grantDailyGemCard(userId: string): Promise<number> {
  const claimed = await prisma.$executeRawUnsafe(
    `UPDATE "daily_gem_cards"
        SET "last_claimed_at" = NOW(),
            "days_remaining"  = "days_remaining" - 1
      WHERE "user_id" = $1
        AND "days_remaining" > 0
        AND "expires_at" > NOW()
        AND "last_claimed_at" < date_trunc('day', NOW() AT TIME ZONE 'UTC') AT TIME ZONE 'UTC'`,
    userId,
  )
  if (claimed !== 1) return 0

  await prisma.user.update({
    where: { id: userId },
    data: { gems: { increment: MONTHLY_GEM_CARD.DAILY_GEMS } },
  })
  return MONTHLY_GEM_CARD.DAILY_GEMS
}
