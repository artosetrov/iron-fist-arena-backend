import { NextRequest, NextResponse } from 'next/server'
import { getAdminUser } from '@/lib/auth'
import { applySuggestion } from '@/lib/item-validator'

export async function POST(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { itemId, suggestedStats, suggestedSellPrice } = await req.json()
  if (!itemId || !suggestedStats) {
    return NextResponse.json({ error: 'itemId and suggestedStats required' }, { status: 400 })
  }

  const result = await applySuggestion(itemId, suggestedStats, suggestedSellPrice ?? 0, admin.id)
  return NextResponse.json(result)
}
