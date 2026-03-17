import { NextResponse } from 'next/server'
import { getAdminUser } from '@/lib/auth'
import { validateItems } from '@/lib/item-validator'

export async function POST() {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const result = await validateItems()
  return NextResponse.json(result)
}
