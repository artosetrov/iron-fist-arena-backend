import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { calculateAllItemPowerScores } from '@/lib/game/item-balance'

/**
 * GET /api/admin/item-balance/power-scores
 * Returns power scores for all catalog items.
 * Query params: ?rarity=rare&itemType=weapon&minLevel=1&maxLevel=50
 */
export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const rarity = req.nextUrl.searchParams.get('rarity') ?? undefined
    const itemType = req.nextUrl.searchParams.get('itemType') ?? undefined
    const minLevel = req.nextUrl.searchParams.get('minLevel')
    const maxLevel = req.nextUrl.searchParams.get('maxLevel')

    const result = await calculateAllItemPowerScores({
      rarity,
      itemType,
      minLevel: minLevel ? parseInt(minLevel) : undefined,
      maxLevel: maxLevel ? parseInt(maxLevel) : undefined,
    })

    return NextResponse.json(result)
  } catch (error) {
    console.error('get power scores error:', error)
    return NextResponse.json({ error: 'Failed to calculate power scores' }, { status: 500 })
  }
}
