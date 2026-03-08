import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'
import { simulateCombat } from '@/lib/game/combat-simulator'
import { initCombatConfig } from '@/lib/game/combat'
import type { CharacterClassType } from '@/lib/game/combat'

/**
 * POST /api/admin/item-balance/simulate/combat
 * Run combat simulation between two characters.
 * Body: { charA: { class, level, stats?, gearPowerScore? }, charB: { ... }, iterations? }
 */
export async function POST(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const { charA, charB, iterations = 1000 } = await req.json()

    if (!charA?.class || !charA?.level || !charB?.class || !charB?.level) {
      return NextResponse.json(
        { error: 'charA and charB must include class and level' },
        { status: 400 }
      )
    }

    // Pre-load combat config from DB
    await initCombatConfig()

    const result = await simulateCombat(
      {
        class: charA.class as CharacterClassType,
        level: charA.level,
        stats: charA.stats,
        gearPowerScore: charA.gearPowerScore,
      },
      {
        class: charB.class as CharacterClassType,
        level: charB.level,
        stats: charB.stats,
        gearPowerScore: charB.gearPowerScore,
      },
      Math.min(iterations, 10000),
    )

    // Persist simulation run
    await prisma.balanceSimulationRun.create({
      data: {
        runType: 'combat_sim',
        config: { charA, charB, iterations } as never,
        results: result as never,
        summary: `${charA.class} vs ${charB.class} at level ${charA.level}: ${result.winRateA}% / ${result.winRateB}%`,
        createdBy: user.id,
      },
    })

    return NextResponse.json(result)
  } catch (error) {
    console.error('combat simulation error:', error)
    return NextResponse.json({ error: 'Failed to run combat simulation' }, { status: 500 })
  }
}
