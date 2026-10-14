import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit, shopRateLimit } from '@/lib/rate-limit'
import { GEM_PACKS, GEM_PACK_DAILY_PURCHASE_CAP, getGemPack } from '@/lib/game/gem-packs'
import { currentDailyValue } from '@/lib/game/daily-counter'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'

/**
 * POST /api/shop/buy-gems
 *
 * Buys a gem pack from the shop (spends gold, receives gems).
 *
 * Request body:
 *   { character_id: string, catalog_id: GemPackCatalogId }
 *
 * Response (flat, matches the shape ShopService.updateCharacter(from:) reads):
 *   { gold, gems, goldSpent, gemsReceived, catalogId }
 *
 * Legacy mode: we still accept `{ gems_amount }` from older clients — it is
 * mapped to the matching pack by gems count. New clients should send catalog_id.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await shopRateLimit(user.id)) || !(await rateLimit(`shop-buy-gems:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, catalog_id, gems_amount } = body as {
      character_id?: string
      catalog_id?: string
      gems_amount?: number
    }

    if (!character_id) {
      return NextResponse.json(
        { error: 'character_id is required' },
        { status: 400 }
      )
    }

    // Resolve the pack. Prefer catalog_id; fall back to gems_amount lookup for legacy clients.
    let pack = typeof catalog_id === 'string' ? getGemPack(catalog_id) : null
    if (!pack && typeof gems_amount === 'number' && Number.isInteger(gems_amount)) {
      pack =
        Object.values(GEM_PACKS).find((p) => p.gemsAmount === gems_amount) ?? null
    }

    if (!pack) {
      return NextResponse.json(
        {
          error:
            'Invalid gem pack. Expected catalog_id one of gem_pack_small/medium/large.',
        },
        { status: 400 }
      )
    }

    const goldCost = pack.goldPrice
    const gemsToAdd = pack.gemsAmount

    const result = await prisma.$transaction(async (tx) => {
      // Verify character ownership + level gate
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true, level: true },
      })

      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')
      if (character.level < pack!.requiredLevel) throw new Error('LEVEL_LOCKED')

      // Lock user row, verify balance and the daily cap, then update atomically.
      // The cap is per account and lives on the user row, inside the same
      // lock as the gold check, so two parallel purchases cannot both pass.
      const [userRow] = await tx.$queryRawUnsafe<
        Array<{ id: string; gold: number; gem_pack_purchases_today: number; gem_pack_purchase_date: Date | null }>
      >(
        `SELECT id, gold, gem_pack_purchases_today, gem_pack_purchase_date FROM users WHERE id = $1 FOR UPDATE`,
        user.id
      )

      if (!userRow) throw new Error('USER_NOT_FOUND')

      const now = new Date()
      const boughtToday = currentDailyValue(
        userRow.gem_pack_purchases_today ?? 0,
        userRow.gem_pack_purchase_date,
        now,
      )
      if (boughtToday >= GEM_PACK_DAILY_PURCHASE_CAP) throw new Error('DAILY_CAP')
      if (userRow.gold < goldCost) throw new Error('NOT_ENOUGH_GOLD')

      const updatedUser = await tx.user.update({
        where: { id: user.id },
        data: {
          gold: { decrement: goldCost },
          gems: { increment: gemsToAdd },
          gemPackPurchasesToday: boughtToday + 1,
          gemPackPurchaseDate: now,
        },
        select: { gold: true, gems: true, gemPackPurchasesToday: true },
      })

      return updatedUser
    })

    // Gold spent on gem packs counts toward Big Spender / Spendthrift like any
    // other shop purchase (was missing — AUDIT-2026-10-13 H14). Non-critical.
    await Promise.all([
      updateDailyQuestProgress(prisma, character_id, 'gold_spent', goldCost),
      updateWeeklyChallengeProgress(prisma, character_id, 'gold_spent', goldCost),
    ]).catch((err: unknown) => console.error('buy-gems quest progress error:', err))

    // Flat response — matches every other shop endpoint so ShopService.updateCharacter
    // can read `gold`/`gems` directly without unwrapping a nested `character` object.
    return NextResponse.json({
      gold: result.gold,
      gems: result.gems,
      goldSpent: goldCost,
      gemsReceived: gemsToAdd,
      catalogId: pack.catalogId,
      packsBoughtToday: result.gemPackPurchasesToday,
      packsDailyCap: GEM_PACK_DAILY_PURCHASE_CAP,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND')
        return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN')
        return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'DAILY_CAP')
        return NextResponse.json(
          { error: `You can buy ${GEM_PACK_DAILY_PURCHASE_CAP} gem pack per day.`, packsDailyCap: GEM_PACK_DAILY_PURCHASE_CAP },
          { status: 429 }
        )
      if (error.message === 'LEVEL_LOCKED')
        return NextResponse.json(
          { error: 'Your level is too low for this pack' },
          { status: 403 }
        )
      if (error.message === 'NOT_ENOUGH_GOLD')
        return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
      if (error.message === 'USER_NOT_FOUND')
        return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }
    console.error('buy gems error:', error)
    return NextResponse.json({ error: 'Failed to buy gems' }, { status: 500 })
  }
}
