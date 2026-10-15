import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { getIapOffers } from '@/lib/game/iap-offers'

/**
 * GET /api/iap/offers — this account's state for the shop's special offers:
 * whether the one-time Starter Bundle is still on sale, and the Monthly Gem
 * Card's terms and status. Terms come from balance.ts so the client does not
 * hardcode economy numbers.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    return NextResponse.json(await getIapOffers(user.id))
  } catch (error) {
    console.error('iap offers error:', error)
    return NextResponse.json({ error: 'Failed to load offers' }, { status: 500 })
  }
}
