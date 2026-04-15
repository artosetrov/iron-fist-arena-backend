import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { invalidatePassiveCache, invalidateSkillCache } from '@/lib/game/combat-loader'
import { grantRewardEntries } from '@/lib/game/reward-grants'

interface OfferContent {
  type: 'gold' | 'gems' | 'item' | 'consumable' | 'xp'
  id?: string          // item catalogId or consumableType
  quantity: number
}

/**
 * GET /api/shop/offers?character_id=xxx
 * Returns active, time-valid offers the character is eligible for.
 * Includes purchase count so client knows if limit reached.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { id: true, userId: true, level: true },
    })
    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    const now = new Date()

    // Fetch active offers within time window and level range
    const offers = await prisma.shopOffer.findMany({
      where: {
        isActive: true,
        minLevel: { lte: character.level },
        maxLevel: { gte: character.level },
        OR: [
          { startsAt: null },
          { startsAt: { lte: now } },
        ],
        AND: [
          {
            OR: [
              { endsAt: null },
              { endsAt: { gte: now } },
            ],
          },
        ],
      },
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
      include: {
        purchases: {
          where: { characterId },
          select: { id: true },
        },
      },
    })

    const result = offers.map((offer) => ({
      id: offer.id,
      key: offer.key,
      title: offer.title,
      description: offer.description,
      offer_type: offer.offerType,
      contents: offer.contents,
      original_price: offer.originalPrice,
      sale_price: offer.salePrice,
      currency: offer.currency,
      discount_pct: offer.discountPct,
      max_purchases: offer.maxPurchases,
      purchases_made: offer.purchases.length,
      can_purchase: offer.maxPurchases === 0 || offer.purchases.length < offer.maxPurchases,
      image_key: offer.imageKey,
      tags: offer.tags,
      starts_at: offer.startsAt?.toISOString() ?? null,
      ends_at: offer.endsAt?.toISOString() ?? null,
    }))

    return NextResponse.json({ offers: result })
  } catch (error) {
    console.error('shop offers error:', error)
    return NextResponse.json({ error: 'Failed to fetch offers' }, { status: 500 })
  }
}

/**
 * POST /api/shop/offers
 * Purchase an offer. Body: { character_id, offer_id }
 * Validates eligibility, deducts currency, grants contents atomically.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, offer_id } = body

    if (!character_id || !offer_id) {
      return NextResponse.json({ error: 'character_id and offer_id are required' }, { status: 400 })
    }

    // Load character + offer in parallel
    const [character, offer] = await Promise.all([
      prisma.character.findUnique({
        where: { id: character_id },
        select: { id: true, userId: true, level: true },
      }),
      prisma.shopOffer.findUnique({
        where: { id: offer_id },
        include: {
          purchases: {
            where: { characterId: character_id },
            select: { id: true },
          },
        },
      }),
    ])

    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (!offer || !offer.isActive) {
      return NextResponse.json({ error: 'Offer not found or inactive' }, { status: 404 })
    }

    // Time window check
    const now = new Date()
    if (offer.startsAt && offer.startsAt > now) {
      return NextResponse.json({ error: 'Offer not yet available' }, { status: 400 })
    }
    if (offer.endsAt && offer.endsAt < now) {
      return NextResponse.json({ error: 'Offer expired' }, { status: 400 })
    }

    // Level check
    if (character.level < offer.minLevel || character.level > offer.maxLevel) {
      return NextResponse.json({ error: 'Level requirement not met' }, { status: 400 })
    }

    // Pre-flight purchase limit check (non-authoritative — real check inside transaction)
    if (offer.maxPurchases > 0 && offer.purchases.length >= offer.maxPurchases) {
      return NextResponse.json({ error: 'Purchase limit reached' }, { status: 400 })
    }

    // Pre-flight currency check
    const userRecord = await prisma.user.findUnique({
      where: { id: user.id },
      select: { gold: true, gems: true },
    })
    if (!userRecord) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    if (offer.currency === 'gold' && userRecord.gold < offer.salePrice) {
      return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
    }
    if (offer.currency === 'gems' && userRecord.gems < offer.salePrice) {
      return NextResponse.json({ error: 'Not enough gems' }, { status: 400 })
    }

    // Interactive transaction with row-level locking to prevent race conditions
    const contents = offer.contents as unknown as OfferContent[]

    const result = await prisma.$transaction(async (tx) => {
      // Re-check purchase limit inside transaction with row lock
      if (offer.maxPurchases > 0) {
        // Lock character row to serialize concurrent purchase attempts
        await tx.$queryRaw`SELECT id FROM characters WHERE id = ${character_id} FOR UPDATE`

        const purchaseCount = await tx.shopOfferPurchase.count({
          where: { offerId: offer_id, characterId: character_id },
        })
        if (purchaseCount >= offer.maxPurchases) {
          throw new Error('PURCHASE_LIMIT_REACHED')
        }
      }

      // Re-check currency inside transaction (authoritative)
      const freshUser = await tx.user.findUnique({
        where: { id: user.id },
        select: { gold: true, gems: true },
      })

      if (offer.currency === 'gold' && (freshUser?.gold ?? 0) < offer.salePrice) {
        throw new Error('INSUFFICIENT_GOLD')
      }
      if (offer.currency === 'gems' && (freshUser?.gems ?? 0) < offer.salePrice) {
        throw new Error('INSUFFICIENT_GEMS')
      }

      // 1. Deduct currency
      if (offer.currency === 'gold') {
        await tx.user.update({
          where: { id: user.id },
          data: { gold: { decrement: offer.salePrice } },
        })
      } else {
        await tx.user.update({
          where: { id: user.id },
          data: { gems: { decrement: offer.salePrice } },
        })
      }

      const rewardResult = await grantRewardEntries(tx, {
        userId: user.id,
        characterId: character_id,
        rewards: contents,
      })

      // 3. Record purchase
      await tx.shopOfferPurchase.create({
        data: {
          offerId: offer_id,
          characterId: character_id,
          price: offer.salePrice,
          currency: offer.currency,
        },
      })

      return rewardResult
    }, { isolationLevel: 'Serializable', timeout: 10000 })

    if (result.levelUpResult?.leveledUp) {
      await invalidateSkillCache(character_id)
      await invalidatePassiveCache(character_id)
    }

    return NextResponse.json({
      success: true,
      gold: result.gold,
      gems: result.gems,
      xp: result.xp,
      leveled_up: result.levelUpResult?.leveledUp ?? false,
      new_level: result.levelUpResult?.newLevel,
      stat_points_awarded: result.levelUpResult?.statPointsAwarded,
    })
  } catch (error) {
    // Handle known transaction errors with proper HTTP codes
    if (error instanceof Error && error.message === 'PURCHASE_LIMIT_REACHED') {
      return NextResponse.json({ error: 'Purchase limit reached' }, { status: 400 })
    }
    if (error instanceof Error && error.message === 'INSUFFICIENT_GOLD') {
      return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
    }
    if (error instanceof Error && error.message === 'INSUFFICIENT_GEMS') {
      return NextResponse.json({ error: 'Not enough gems' }, { status: 400 })
    }
    if (error instanceof Error && error.message === 'INVENTORY_FULL') {
      return NextResponse.json({ error: 'Inventory is full' }, { status: 400 })
    }
    console.error('purchase offer error:', error)
    return NextResponse.json({ error: 'Failed to purchase offer' }, { status: 500 })
  }
}
