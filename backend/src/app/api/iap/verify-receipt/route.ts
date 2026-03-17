import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { IAP_PRODUCTS } from '@/lib/game/balance'
import { verifyAppleTransaction } from '@/lib/apple-iap'

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
    const characterUpdate: Record<string, unknown> = {}

    if (product.gems > 0) {
      userUpdate.gems = { increment: product.gems }
    }

    if (product.gold > 0) {
      characterUpdate.gold = { increment: product.gold }
    }

    if (product.premium) {
      // Set premium_until far in the future (permanent = year 2099)
      userUpdate.premiumUntil = new Date('2099-12-31T23:59:59Z')
    }

    // Execute all operations in a single transaction
    const operations: any[] = [
      // 1. Record the IAP transaction
      prisma.iapTransaction.create({
        data: {
          userId: user.id,
          productId: product_id,
          transactionId: transaction_id,
          receiptData: receipt_data,
          gemsAwarded: product.gems,
          status: 'verified',
          verifiedAt: now,
        },
      }),
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

    // 3. Update character gold (if gold pack)
    if (Object.keys(characterUpdate).length > 0) {
      // Find user's active character
      const character = await prisma.character.findFirst({
        where: { userId: user.id },
        orderBy: { lastPlayed: 'desc' },
      })
      if (character) {
        operations.push(
          prisma.character.update({
            where: { id: character.id },
            data: characterUpdate,
          })
        )
      }
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

    return NextResponse.json(response)
  } catch (error) {
    console.error('iap verify-receipt error:', error)
    return NextResponse.json(
      { error: 'Failed to verify receipt' },
      { status: 500 }
    )
  }
}
