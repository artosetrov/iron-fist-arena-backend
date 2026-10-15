import { randomUUID } from 'node:crypto'
import { prisma } from '@/lib/prisma'
import { MONTHLY_GEM_CARD } from './balance'

const DAY_MS = 24 * 60 * 60 * 1000

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

/**
 * Start a Monthly Gem Card, or extend the active one by `MONTHLY_GEM_CARD.DAYS`.
 *
 * Until 2026-10-15 a repeat purchase reset the card to 30 days and silently
 * discarded whatever the player had left. Now an active card keeps its days
 * and its claim state (today's payout stays claimable); an expired or used-up
 * card starts over, claimed for today — the instant gems are day one.
 *
 * A single INSERT … ON CONFLICT, so two concurrent purchases cannot both read
 * the old row and lose an extension (backend/CLAUDE.md → Atomic Increments).
 * SET expressions see the pre-update row, so every CASE tests the same state.
 * Returned unexecuted, for the purchase's `$transaction([...])`.
 */
export function startOrExtendGemCard(userId: string) {
  const days = MONTHLY_GEM_CARD.DAYS
  return prisma.$executeRaw`
    INSERT INTO "daily_gem_cards"
      ("id", "user_id", "purchased_at", "expires_at", "last_claimed_at", "days_remaining")
    VALUES
      (${randomUUID()}, ${userId}, NOW(), NOW() + make_interval(days => ${days}::int), NOW(), ${days}::int)
    ON CONFLICT ("user_id") DO UPDATE SET
      "purchased_at" = NOW(),
      "days_remaining" = CASE
        WHEN "daily_gem_cards"."expires_at" > NOW() AND "daily_gem_cards"."days_remaining" > 0
        THEN "daily_gem_cards"."days_remaining" + ${days}::int
        ELSE ${days}::int
      END,
      "expires_at" = CASE
        WHEN "daily_gem_cards"."expires_at" > NOW() AND "daily_gem_cards"."days_remaining" > 0
        THEN "daily_gem_cards"."expires_at" + make_interval(days => ${days}::int)
        ELSE NOW() + make_interval(days => ${days}::int)
      END,
      "last_claimed_at" = CASE
        WHEN "daily_gem_cards"."expires_at" > NOW() AND "daily_gem_cards"."days_remaining" > 0
        THEN "daily_gem_cards"."last_claimed_at"
        ELSE NOW()
      END`
}

export interface GemCardStatus {
  active: boolean
  /** Daily payouts still ahead: claims left, capped by the days until expiry. */
  daysRemaining: number
  expiresAt: string | null
}

/** Where the player's Monthly Gem Card stands, for the shop. */
export async function getGemCardStatus(userId: string, now: Date = new Date()): Promise<GemCardStatus> {
  const card = await prisma.dailyGemCard.findUnique({
    where: { userId },
    select: { expiresAt: true, daysRemaining: true },
  })
  if (!card || card.daysRemaining <= 0 || card.expiresAt.getTime() <= now.getTime()) {
    return { active: false, daysRemaining: 0, expiresAt: null }
  }
  const daysToExpiry = Math.ceil((card.expiresAt.getTime() - now.getTime()) / DAY_MS)
  return {
    active: true,
    daysRemaining: Math.min(card.daysRemaining, daysToExpiry),
    expiresAt: card.expiresAt.toISOString(),
  }
}
