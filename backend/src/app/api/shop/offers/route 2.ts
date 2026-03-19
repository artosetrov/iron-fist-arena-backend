import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ConsumableType } from '@prisma/client'

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
        select: { id: true, userId: true, level: true, gold: true, currentXp: true },
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

    // Purchase limit check
    if (offer.maxPurchases > 0 && offer.purchases.length >= offer.maxPurchases) {
      return NextResponse.json({ error: 'Purchase limit reached' }, { status: 400 })
    }

    // Currency check
    const userRecord = await prisma.user.findUnique({
      where: { id: user.id },
      select: { gems: true },
    })
    if (!userRecord) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    if (offer.currency === 'gold' && character.gold < offer.salePrice) {
      return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
    }
    if (offer.currency === 'gems' && userRecord.gems < offer.salePrice) {
      return NextResponse.json({ error: 'Not enough gems' }, { status: 400 })
    }

    // Build transaction operations
    const contents = offer.contents as OfferContent[]
    const ops: any[] = []

    // 1. Deduct currency
    if (offer.currency === 'gold') {
      ops.push(
        prisma.character.update({
          where: { id: character_id },
          data: { gold: { decrement: offer.salePrice } },
        })
      )
    } else {
      ops.push(
        prisma.user.update({
          where: { id: user.id },
          data: { gems: { decrement: offer.salePrice } },
        })
      )
    }

    // 2. Grant contents
    let goldGrant = 0
    let gemsGrant = 0
    let xpGrant = 0

    for (const item of contents) {
      switch (item.type) {
        case 'gold':
          goldGrant += item.quantity
          break
        case 'gems':
          gemsGrant += item.quantity
          break
        case 'xp':
          xpGrant += item.quantity
          break
        case 'consumable':
          if (item.id) {
            ops.push(
              prisma.consumableInventory.upsert({
                where: {
                  characterId_consumableType: {
                    characterId: character_id,
                    consumableType: item.id as ConsumableType,
                  },
                },
                update: { quantity: { increment: item.quantity } },
                create: {
                  characterId: character_id,
                  consumableType: item.id as ConsumableType,
                  quantity: item.quantity,
                },
              })
            )
          }
          break
        // item type would need item creation logic — skip for now, handled via mail
      }
    }

    if (goldGrant > 0) {
      ops.push(
        prisma.character.update({
          where: { id: character_id },
          data: { gold: { increment: goldGrant } },
        })
      )
    }
    if (gemsGrant > 0) {
      ops.push(
        prisma.user.update({
          where: { id: user.id },
          data: { gems: { increment: gemsGrant } },
        })
      )
    }
    if (xpGrant > 0) {
      ops.push(
        prisma.character.update({
          where: { id: character_id },
          data: { currentXp: { increment: xpGrant } },
        })
      )
    }

    // 3. Record purchase
    ops.push(
      prisma.shopOfferPurchase.create({
        data: {
          offerId: offer_id,
          characterId: character_id,
          price: offer.salePrice,
          currency: offer.currency,
        },
      })
    )

    await prisma.$transaction(ops)

    // Return updated balances
    const [updatedChar, updatedUser] = await Promise.all([
      prisma.character.findUnique({
        where: { id: character_id },
        select: { gold: true, currentXp: true },
      }),
      prisma.user.findUnique({
        where: { id: user.id },
        select: { gems: true },
      }),
    ])

    return NextResponse.json({
      success: true,
      gold: updatedChar?.gold ?? 0,
      gems: updatedUser?.gems ?? 0,
      xp: updatedChar?.currentXp ?? 0,
    })
  } catch (error) {
    console.error('purchase offer error:', error)
    return NextResponse.json({ error: 'Failed to purchase offer' }, { status: 500 })
  }
}
