import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { recalculateDerivedStats } from '@/lib/game/equipment-stats'
import { invalidateSkillCache, invalidatePassiveCache } from '@/lib/game/combat-loader'
import { rateLimit } from '@/lib/rate-limit'
import { STAT_PURCHASE } from '@/lib/game/balance'

// POST — Buy 1 stat point for gems (escalating daily price, daily limit, global cap)
export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`buy-stat-points:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const { id } = await params

    const result = await prisma.$transaction(async (tx) => {
      // Lock character row
      const character = await tx.character.findUnique({
        where: { id },
        select: {
          userId: true,
          statPointsAvailable: true,
          statPurchasesToday: true,
          statPurchasesDate: true,
          statPurchasesTotal: true,
        },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Global cap check
      if (character.statPurchasesTotal >= STAT_PURCHASE.GLOBAL_CAP) {
        throw new Error('GLOBAL_CAP_REACHED')
      }

      // Reset daily counter if new day (UTC)
      const now = new Date()
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
      let purchasesToday = character.statPurchasesToday
      if (!character.statPurchasesDate || character.statPurchasesDate < today) {
        purchasesToday = 0
      }

      // Daily limit check
      if (purchasesToday >= STAT_PURCHASE.DAILY_LIMIT) {
        throw new Error('DAILY_LIMIT_REACHED')
      }

      // Get escalating price
      const price = STAT_PURCHASE.ESCALATION[purchasesToday]
      if (price === undefined) throw new Error('DAILY_LIMIT_REACHED')

      // Check gems on user
      const dbUser = await tx.user.findUnique({
        where: { id: user.id },
        select: { gems: true },
      })
      if (!dbUser || dbUser.gems < price) {
        throw new Error('NOT_ENOUGH_GEMS')
      }

      // Update character: +1 stat point, increment purchase counters
      await tx.character.update({
        where: { id },
        data: {
          statPointsAvailable: { increment: 1 },
          statPurchasesToday: purchasesToday + 1,
          statPurchasesDate: now,
          statPurchasesTotal: { increment: 1 },
        },
      })

      // Deduct gems
      await tx.user.update({
        where: { id: user.id },
        data: { gems: { decrement: price } },
      })

      return {
        purchased: purchasesToday + 1,
        price,
        nextPrice: purchasesToday + 1 < STAT_PURCHASE.DAILY_LIMIT
          ? STAT_PURCHASE.ESCALATION[purchasesToday + 1]
          : null,
        dailyRemaining: STAT_PURCHASE.DAILY_LIMIT - (purchasesToday + 1),
        totalPurchased: character.statPurchasesTotal + 1,
        globalCap: STAT_PURCHASE.GLOBAL_CAP,
      }
    })

    // Post-transaction: recalc + invalidate
    await recalculateDerivedStats(id)
    await invalidateSkillCache(id)
    await invalidatePassiveCache(id)

    const updated = await prisma.character.findUnique({ where: { id } })

    return NextResponse.json({
      character: updated,
      purchase: result,
    })
  } catch (error) {
    if (error instanceof Error) {
      const map: Record<string, { msg: string; status: number }> = {
        NOT_FOUND: { msg: 'Character not found', status: 404 },
        FORBIDDEN: { msg: 'Forbidden', status: 403 },
        NOT_ENOUGH_GEMS: { msg: 'Not enough gems', status: 400 },
        DAILY_LIMIT_REACHED: { msg: 'Daily purchase limit reached', status: 400 },
        GLOBAL_CAP_REACHED: { msg: 'Maximum stat purchases reached', status: 400 },
      }
      const mapped = map[error.message]
      if (mapped) return NextResponse.json({ error: mapped.msg }, { status: mapped.status })
    }
    console.error('buy-stat-points error:', error)
    return NextResponse.json({ error: 'Failed to buy stat points' }, { status: 500 })
  }
}

// GET — Get current purchase status (prices, daily remaining, global progress)
export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const { id } = await params

    const character = await prisma.character.findUnique({
      where: { id },
      select: {
        userId: true,
        statPurchasesToday: true,
        statPurchasesDate: true,
        statPurchasesTotal: true,
        statPointsAvailable: true,
      },
    })
    if (!character) return NextResponse.json({ error: 'Not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    // Reset daily counter if new day
    const now = new Date()
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    let purchasesToday = character.statPurchasesToday
    if (!character.statPurchasesDate || character.statPurchasesDate < today) {
      purchasesToday = 0
    }

    const nextPrice = purchasesToday < STAT_PURCHASE.DAILY_LIMIT
      ? STAT_PURCHASE.ESCALATION[purchasesToday]
      : null

    return NextResponse.json({
      purchasesToday,
      dailyLimit: STAT_PURCHASE.DAILY_LIMIT,
      dailyRemaining: STAT_PURCHASE.DAILY_LIMIT - purchasesToday,
      totalPurchased: character.statPurchasesTotal,
      globalCap: STAT_PURCHASE.GLOBAL_CAP,
      prices: STAT_PURCHASE.ESCALATION,
      nextPrice,
      statPointsAvailable: character.statPointsAvailable,
    })
  } catch (error) {
    console.error('buy-stat-points GET error:', error)
    return NextResponse.json({ error: 'Failed to get purchase status' }, { status: 500 })
  }
}
