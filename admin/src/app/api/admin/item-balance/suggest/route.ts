import { NextRequest, NextResponse } from 'next/server'
import { getAdminUser } from '@/lib/auth'
import { suggestFix } from '@/lib/item-validator'

export async function POST(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { itemId } = await req.json()
  if (!itemId) return NextResponse.json({ error: 'itemId required' }, { status: 400 })

  const result = await suggestFix(itemId)
  if ('error' in result) {
    return NextResponse.json(result, { status: 404 })
  }

  return NextResponse.json(result)
}
