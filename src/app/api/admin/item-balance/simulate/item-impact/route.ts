import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'
import { simulateItemImpact } from '@/lib/game/combat-simulator'
import { initCombatConfig } from '@/lib/game/combat'
import type { CharacterClassType } from '@/lib/game/combat'

/**
 * POST /api/admin/item-balance/simulate/item-impact
 * Simulate how an item affects combat performance.
 * Body: { itemStats, characterClass, characterLevel, iterations? }
 */
export async function POST(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const { itemStats, characterClass, characterLevel, iterations = 500 } = await req.json()

    if (!itemStats || !characterClass || !characterLevel) {
      return NextResponse.json(
        { error: 'itemStats, characterClass, and characterLevel are required' },
        { status: 400 }
      )
    }

    await initCombatConfig()

    const result = await simulateItemImpact(
      itemStats,
      characterClass as CharacterClassType,
      characterLevel,
      Math.min(iterations, 5000),
    )

    await prisma.balanceSimulationRun.create({
      data: {
        runType: 'item_impact',
        config: { itemStats, characterClass, characterLevel, iterations } as never,
        results: result as never,
        summary: `Item impact on ${characterClass} level ${characterLevel}: DPS ${result.dpsChangePercent > 0 ? '+' : ''}${result.dpsChangePercent}%`,
        createdBy: user.id,
      },
    })

    return NextResponse.json(result)
  } catch (error) {
    console.error('item impact simulation error:', error)
    return NextResponse.json({ error: 'Failed to run item impact simulation' }, { status: 500 })
  }
}
