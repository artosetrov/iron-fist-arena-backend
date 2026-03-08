import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'
import { simulateClassMatchups } from '@/lib/game/combat-simulator'
import { initCombatConfig } from '@/lib/game/combat'

/**
 * POST /api/admin/item-balance/simulate/matchups
 * Run round-robin class matchup simulation.
 * Body: { level, gearPowerScore?, iterations? }
 */
export async function POST(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const { level, gearPowerScore = 0, iterations = 500 } = await req.json()

    if (!level || level < 1) {
      return NextResponse.json({ error: 'level is required and must be >= 1' }, { status: 400 })
    }

    await initCombatConfig()

    const result = await simulateClassMatchups(
      level,
      gearPowerScore,
      Math.min(iterations, 5000),
    )

    await prisma.balanceSimulationRun.create({
      data: {
        runType: 'class_matchups',
        config: { level, gearPowerScore, iterations } as never,
        results: result as never,
        summary: `4x4 class matchup at level ${level}, gear ${gearPowerScore}`,
        createdBy: user.id,
      },
    })

    return NextResponse.json(result)
  } catch (error) {
    console.error('matchup simulation error:', error)
    return NextResponse.json({ error: 'Failed to run matchup simulation' }, { status: 500 })
  }
}
