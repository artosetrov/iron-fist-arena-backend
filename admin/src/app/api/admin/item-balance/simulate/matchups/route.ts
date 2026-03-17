import { NextRequest, NextResponse } from 'next/server'
import { getAdminUser } from '@/lib/auth'
import { simulateMatchups } from '@/lib/combat-sim'

export async function POST(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { level = 10, gearPowerScore = 0, iterations = 500 } = await req.json()

  // Cap iterations
  const cappedIterations = Math.min(Math.max(iterations, 100), 5000)

  const result = await simulateMatchups(level, gearPowerScore, cappedIterations)
  return NextResponse.json(result)
}
