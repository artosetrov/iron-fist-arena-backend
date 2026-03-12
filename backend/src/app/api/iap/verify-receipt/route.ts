import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { IAP_PRODUCTS } from '@/lib/game/balance'

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

    // In a real implementation, verify the receipt with Apple/Google here.
    // For now, we trust the receipt and mark as verified.
    const now = new Date()

    const [transaction] = await prisma.$transaction([
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
      prisma.user.update({
        where: { id: user.id },
        data: { gems: { increment: product.gems } },
      }),
    ])

    return NextResponse.json({
      success: true,
      gemsAwarded: transaction.gemsAwarded,
      transactionId: transaction.id,
    })
  } catch (error) {
    console.error('iap verify-receipt error:', error)
    return NextResponse.json(
      { error: 'Failed to verify receipt' },
      { status: 500 }
    )
  }
}
