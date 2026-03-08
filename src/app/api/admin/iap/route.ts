import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/admin/iap
 * Query params: ?limit=50&offset=0&status=verified
 * Returns IAP transaction list for admin review.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const limit = Math.min(parseInt(req.nextUrl.searchParams.get('limit') ?? '50'), 200)
    const offset = parseInt(req.nextUrl.searchParams.get('offset') ?? '0')
    const status = req.nextUrl.searchParams.get('status')

    const where = status ? { status } : {}

    const [transactions, total] = await Promise.all([
      prisma.iapTransaction.findMany({
        where,
        select: {
          id: true,
          productId: true,
          transactionId: true,
          gemsAwarded: true,
          status: true,
          createdAt: true,
          verifiedAt: true,
          user: { select: { email: true, username: true } },
        },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      prisma.iapTransaction.count({ where }),
    ])

    return NextResponse.json({ transactions, total, limit, offset })
  } catch (error) {
    console.error('admin iap error:', error)
    return NextResponse.json({ error: 'Failed to fetch IAP transactions' }, { status: 500 })
  }
}
