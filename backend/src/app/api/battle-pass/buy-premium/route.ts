import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { getGemCostsConfig } from '@/lib/game/live-config'
import { rateLimit } from '@/lib/rate-limit'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`bp-premium:${user.id}`, 3, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const GEM_COSTS = await getGemCostsConfig()
    const PREMIUM_COST_GEMS = GEM_COSTS.BATTLE_PASS_PREMIUM
    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    // Use interactive transaction with row-level lock to prevent TOCTOU
    const result = await prisma.$transaction(async (tx) => {
      // Lock the user row for update (gems balance)
      const [userRow] = await tx.$queryRawUnsafe<Array<{ id: string; gems: number }>>(
        `SELECT id, gems FROM users WHERE id = $1 FOR UPDATE`,
        user.id
      )

      if (!userRow) throw new Error('USER_NOT_FOUND')

      // Verify character ownership
      const character = await tx.character.findUnique({
        where: { id: character_id },
      })

      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Find active season
      const now = new Date()
      const activeSeason = await tx.season.findFirst({
        where: {
          startAt: { lte: now },
          endAt: { gte: now },
        },
      })

      if (!activeSeason) throw new Error('NO_ACTIVE_SEASON')

      // Get or create battle pass
      let battlePass = await tx.battlePass.findFirst({
        where: { characterId: character_id, seasonId: activeSeason.id },
      })

      if (!battlePass) {
        battlePass = await tx.battlePass.create({
          data: {
            characterId: character_id,
            seasonId: activeSeason.id,
            premium: false,
            bpXp: 0,
          },
        })
      }

      if (battlePass.premium) throw new Error('ALREADY_PREMIUM')
      if (userRow.gems < PREMIUM_COST_GEMS) throw new Error('NOT_ENOUGH_GEMS')

      const updatedUser = await tx.user.update({
        where: { id: user.id },
        data: { gems: { decrement: PREMIUM_COST_GEMS } },
      })

      const updatedBattlePass = await tx.battlePass.update({
        where: { id: battlePass.id },
        data: { premium: true },
      })

      return { updatedUser, updatedBattlePass }
    })

    return NextResponse.json({
      battlePass: {
        id: result.updatedBattlePass.id,
        premium: result.updatedBattlePass.premium,
        bpXp: result.updatedBattlePass.bpXp,
      },
      gemsRemaining: result.updatedUser.gems,
      cost: PREMIUM_COST_GEMS,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'USER_NOT_FOUND') return NextResponse.json({ error: 'User not found' }, { status: 404 })
      if (error.message === 'NO_ACTIVE_SEASON') return NextResponse.json({ error: 'No active season' }, { status: 404 })
      if (error.message === 'ALREADY_PREMIUM') return NextResponse.json({ error: 'Battle pass is already premium' }, { status: 400 })
      if (error.message === 'NOT_ENOUGH_GEMS') return NextResponse.json({ error: 'Not enough gems' }, { status: 400 })
    }
    console.error('buy premium error:', error)
    return NextResponse.json(
      { error: 'Failed to buy premium battle pass' },
      { status: 500 }
    )
  }
}
