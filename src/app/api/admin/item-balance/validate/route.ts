import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'
import { validateAllItems } from '@/lib/game/item-validation'

/**
 * POST /api/admin/item-balance/validate
 * Run validation on all items and optionally persist the result.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const result = await validateAllItems()

    // Persist the simulation run
    await prisma.balanceSimulationRun.create({
      data: {
        runType: 'item_audit',
        config: {},
        results: result as never,
        summary: `${result.totalItems} items checked, ${result.flaggedItems.length} flagged (${result.stats.overpoweredCount} OP, ${result.stats.underpoweredCount} UP)`,
        createdBy: user.id,
      },
    })

    return NextResponse.json(result)
  } catch (error) {
    console.error('validate items error:', error)
    return NextResponse.json({ error: 'Failed to validate items' }, { status: 500 })
  }
}
