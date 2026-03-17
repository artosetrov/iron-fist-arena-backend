import { NextRequest, NextResponse } from 'next/server'
import { getAdminUser } from '@/lib/auth'
import { simulateItemImpact } from '@/lib/combat-sim'

export async function POST(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { itemStats, characterClass = 'warrior', characterLevel = 10 } = await req.json()

  if (!itemStats || typeof itemStats !== 'object') {
    return NextResponse.json({ error: 'itemStats object required' }, { status: 400 })
  }

  const result = await simulateItemImpact(itemStats, characterClass, characterLevel)
  return NextResponse.json(result)
}
