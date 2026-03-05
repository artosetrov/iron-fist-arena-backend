import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const transactions = await prisma.iapTransaction.findMany({
      where: {
        userId: user.id,
        status: 'verified',
      },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        productId: true,
        transactionId: true,
        gemsAwarded: true,
        createdAt: true,
        verifiedAt: true,
      },
    })

    return NextResponse.json({ transactions })
  } catch (error) {
    console.error('iap restore-purchases error:', error)
    return NextResponse.json(
      { error: 'Failed to restore purchases' },
      { status: 500 }
    )
  }
}
