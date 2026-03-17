import { NextRequest, NextResponse } from 'next/server'
import { getAdminUser } from '@/lib/auth'
import { simulateCombat } from '@/lib/combat-sim'

export async function POST(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { charA, charB, iterations = 1000 } = await req.json()

  if (!charA?.class || !charB?.class) {
    return NextResponse.json({ error: 'charA and charB with class/level required' }, { status: 400 })
  }

  // Cap iterations to prevent abuse
  const cappedIterations = Math.min(Math.max(iterations, 100), 10000)

  const result = await simulateCombat(charA, charB, cappedIterations)
  return NextResponse.json(result)
}
