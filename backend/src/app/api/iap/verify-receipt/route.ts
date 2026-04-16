import { NextRequest, NextResponse } from 'next/server'
import { Prisma } from '@prisma/client'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { IAP_PRODUCTS } from '@/lib/game/balance'
import { verifyAppleTransaction } from '@/lib/apple-iap'

function isDuplicateTransactionError(error: unknown): boolean {
  if (!(error instanceof Prisma.PrismaClientKnownRequestError) || error.code !== 'P2002') {
    return false
  }

  const target = error.meta?.target
  if (typeof target === 'string') {
    return target.includes('transaction_id') || target.includes('transactionId')
  }

  if (Array.isArray(target)) {
    return target.some(
      (entry) =>
        typeof entry === 'string' &&
        (entry.includes('transaction_id') || entry.includes('transactionId'))
    )
  }

  return false
}

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { product_id, transaction_id, receipt_data } = body

    if (!product_id || !transaction_id || !receipt_data) {
      return NextResponse.json(
        { error: 'product_id, transaction_id, and receipt_data are required' },
        { status: 400 }
      )
    }

    const product = IAP_PRODUCTS[product_id]
    if (!product) {
      return NextResponse.json(
        { error: 'Invalid product_id' },
        { status: 400 }
      )
    }

    // Economy v3: reject disabled SKUs (e.g., premium_forever, flat gold packs).
    // Existing owners' entitlements are unaffected — this only blocks NEW receipts.
    // See docs/06_game_systems/ECONOMY_RULES.md R10, R11.
    if (product.enabled === false) {
      return NextResponse.json(
        { error: 'This product is no longer available for purchase.' },
        { status: 410 } // Gone
      )
    }

    // Check for duplicate transaction
    const existingTx = await prisma.iapTransaction.findUnique({
      where: { transactionId: transaction_id },
    })

    if (existingTx) {
      return NextResponse.json(
        { error: 'Transaction already processed' },
        { status: 409 }
      )
    }

    // Verify the transaction with Apple's App Store Server API v2
    const appleResult = await verifyAppleTransaction(transaction_id)
    if (!appleResult.valid) {
      return NextResponse.json(
        { error: appleResult.error || 'Apple verification failed' },
        { status: 403 }
      )
    }

    // If Apple returned transaction info, cross-check product ID
    if (appleResult.transactionInfo) {
      const appleProductId = appleResult.transactionInfo.productId
      // Map our internal product_id to the StoreKit product ID
      const expectedPrefix = `com.hexbound.${product_id.replace(/_/g, '')}`
      const altId = `com.hexbound.${product_id}`
      if (appleProductId !== expectedPrefix && appleProductId !== altId && appleProductId !== product_id) {
        console.warn(`[IAP] Product ID mismatch: client=${product_id}, apple=${appleProductId}`)
        // Don't block — log for monitoring, as naming conventions may vary
      }
    }

    const now = new Date()

    // Build dynamic update payload based on product type
    const userUpdate: Record<string, unknown> = {}

    if (product.gems > 0) {
      userUpdate.gems = { increment: product.gems }
    }

    if (product.gold > 0) {
      userUpdate.gold = { increment: product.gold }
    }

    if (product.premium) {
      // Set premium_until far in the future (permanent = year 2099)
      userUpdate.premiumUntil = new Date('2099-12-31T23:59:59Z')
      // W3.D5 — grant "Chosen" cosmetic title on ALL of user's characters
      // Done as a separate UPDATE in the transaction below; enum-based so
      // the API can't accept arbitrary title strings.
    }

    // Premium Pass Phase 2 (2026-04-14) — Auto-renewable subscription.
    // Compute the subscription window. Prefer Apple's authoritative
    // `expiresDate` from the signed transaction; fall back to purchase +
    // duration for environments where it's missing (dev / StoreKit-only).
    // Apple Server Notifications v2 will keep this row current on renewals.
    let subscriptionExpiresAt: Date | null = null
    let subscriptionStartedAt: Date | null = null
    let subscriptionOriginalTxId: string | null = null
    if (product.subscription) {
      const appleTx = appleResult.transactionInfo
      const startMs = appleTx?.purchaseDate ?? now.getTime()
      const expiresMs = appleTx?.expiresDate
        ?? startMs + product.subscription.durationDays * 24 * 60 * 60 * 1000
      subscriptionStartedAt = new Date(startMs)
      subscriptionExpiresAt = new Date(expiresMs)
      subscriptionOriginalTxId = appleTx?.originalTransactionId ?? transaction_id
      // Grant the monthly gem allotment on purchase (renewals handled by webhook).
      if (product.subscription.monthlyGems > 0) {
        userUpdate.gems = userUpdate.gems
          ? { increment: (userUpdate.gems as { increment: number }).increment + product.subscription.monthlyGems }
          : { increment: product.subscription.monthlyGems }
      }
    }

    // Execute all operations in a single transaction
    const createIapTransaction = prisma.iapTransaction.create({
      data: {
        userId: user.id,
        productId: product_id,
        transactionId: transaction_id,
        receiptData: receipt_data,
        gemsAwarded: product.gems,
        status: 'verified',
        verifiedAt: now,
      },
    })

    const operations: [typeof createIapTransaction, ...Prisma.PrismaPromise<unknown>[]] = [
      // 1. Record the IAP transaction
      createIapTransaction,
    ]

    // 2. Update user (gems, premium)
    if (Object.keys(userUpdate).length > 0) {
      operations.push(
        prisma.user.update({
          where: { id: user.id },
          data: userUpdate,
        })
      )
    }

    // 2b. W3.D5 — grant "Chosen" title on all user's characters for Premium Forever
    if (product.premium) {
      operations.push(
        prisma.character.updateMany({
          where: { userId: user.id },
          data: { activeTitle: 'chosen' },
        })
      )
    }


    // 3. Bundle extras — grant consumables to the user's active (most-recent) character.
    //    We resolve the target character ONCE and upsert each line item so the
    //    unique (characterId, consumableType) index isn't violated.
    //    If the user has no character (signup edge case), items are skipped
    //    silently — currencies still credit to the user.
    //    See ECONOMY_RULES.md R10.3 + balance.ts IAP_PRODUCTS comments.
    if (product.items && product.items.length > 0) {
      const activeChar = await prisma.character.findFirst({
        where: { userId: user.id },
        orderBy: { updatedAt: 'desc' },
        select: { id: true },
      })
      if (activeChar) {
        for (const grant of product.items) {
          operations.push(
            prisma.consumableInventory.upsert({
              where: {
                characterId_consumableType: {
                  characterId: activeChar.id,
                  consumableType: grant.type,
                },
              },
              create: {
                characterId: activeChar.id,
                consumableType: grant.type,
                quantity: grant.quantity,
              },
              update: {
                quantity: { increment: grant.quantity },
              },
            })
          )
        }
      } else {
        console.warn(`[IAP] bundle ${product_id} bought by user ${user.id} with no character — items skipped`)
      }
    }

    // 3b. Premium Pass subscription row — upsert so repeat purchases (new
    //     original_transaction_id) replace the previous record. The webhook
    //     is the authority for renewals; initial purchase seeds the row.
    if (product.subscription && subscriptionExpiresAt && subscriptionStartedAt && subscriptionOriginalTxId) {
      operations.push(
        prisma.premiumSubscription.upsert({
          where: { userId: user.id },
          create: {
            userId: user.id,
            productId: product_id,
            originalTransactionId: subscriptionOriginalTxId,
            latestTransactionId: transaction_id,
            startedAt: subscriptionStartedAt,
            expiresAt: subscriptionExpiresAt,
            autoRenew: true,
            status: 'active',
            latestReceipt: receipt_data,
          },
          update: {
            productId: product_id,
            originalTransactionId: subscriptionOriginalTxId,
            latestTransactionId: transaction_id,
            startedAt: subscriptionStartedAt,
            expiresAt: subscriptionExpiresAt,
            autoRenew: true,
            status: 'active',
            latestReceipt: receipt_data,
          },
        })
      )
    }

    // 4. Monthly Gem Card — create daily_gem_card record
    if (product.monthlyGemCard) {
      const expiresAt = new Date(now)
      expiresAt.setDate(expiresAt.getDate() + 30)

      operations.push(
        prisma.dailyGemCard.upsert({
          where: { userId: user.id },
          create: {
            userId: user.id,
            purchasedAt: now,
            expiresAt,
            lastClaimedAt: now, // first 50 gems are instant
            daysRemaining: 30,
          },
          update: {
            purchasedAt: now,
            expiresAt,
            lastClaimedAt: now,
            daysRemaining: 30,
          },
        })
      )
    }

    const [transaction] = await prisma.$transaction(operations)

    // Build response
    const response: Record<string, unknown> = {
      success: true,
      transactionId: transaction.id,
    }

    if (product.gems > 0) response.gemsAwarded = product.gems
    if (product.gold > 0) response.goldAwarded = product.gold
    if (product.premium) response.premiumUntil = '2099-12-31T23:59:59Z'
    if (product.monthlyGemCard) response.gemCardActivated = true
    if (product.items && product.items.length > 0) response.itemsAwarded = product.items
    if (product.subscription && subscriptionExpiresAt) {
      response.subscriptionExpiresAt = subscriptionExpiresAt.toISOString()
      response.monthlyGemsAwarded = product.subscription.monthlyGems
    }

    return NextResponse.json(response)
  } catch (error) {
    if (isDuplicateTransactionError(error)) {
      return NextResponse.json(
        { error: 'Transaction already processed' },
        { status: 409 }
      )
    }

    console.error('iap verify-receipt error:', error)
    return NextResponse.json(
      { error: 'Failed to verify receipt' },
      { status: 500 }
    )
  }
}
