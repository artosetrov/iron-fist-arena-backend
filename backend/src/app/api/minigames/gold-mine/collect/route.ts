import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { buildSlotsArray } from '@/lib/game/gold-mine'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, slot_index } = body

    if (!character_id || slot_index == null) {
      return NextResponse.json(
        { error: 'character_id and slot_index are required' },
        { status: 400 }
      )
    }

    // Use interactive transaction with row-level lock to prevent double-collect
    const result = await prisma.$transaction(async (tx) => {
      // Verify character ownership
      const character = await tx.character.findUnique({
        where: { id: character_id },
      })

      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Lock the session row for update to prevent double-collect
      const [sessionRow] = await tx.$queryRawUnsafe<Array<{
        id: string; collected: boolean; reward: number; gem_reward: number; ends_at: Date;
      }>>(
        `SELECT id, collected, reward, gem_reward, ends_at FROM gold_mine_sessions WHERE character_id = $1 AND slot_index = $2 AND collected = false FOR UPDATE`,
        character_id,
        slot_index
      )

      if (!sessionRow) throw new Error('NO_SESSION')

      const now = new Date()
      if (now < sessionRow.ends_at) throw new Error('NOT_READY')

      // Mark collected
      await tx.goldMineSession.update({
        where: { id: sessionRow.id },
        data: { collected: true },
      })

      // Add gold to character
      const updatedCharacter = await tx.character.update({
        where: { id: character_id },
        data: { gold: { increment: sessionRow.reward } },
      })

      // Add gems to user if any
      let updatedUser = null
      if (sessionRow.gem_reward > 0) {
        updatedUser = await tx.user.update({
          where: { id: user.id },
          data: { gems: { increment: sessionRow.gem_reward } },
        })
      }

      return {
        updatedCharacter,
        updatedUser,
        reward: sessionRow.reward,
        gemReward: sessionRow.gem_reward,
        goldMineSlots: character.goldMineSlots,
      }
    })

    // Get current user gems if not updated in transaction
    const userGems = result.updatedUser
      ? result.updatedUser.gems
      : (await prisma.user.findUnique({ where: { id: user.id }, select: { gems: true } }))?.gems ?? 0

    // Update daily quest progress (outside transaction, non-critical)
    await updateDailyQuestProgress(prisma, character_id, 'gold_mine_collect')

    const slots = await buildSlotsArray(prisma, character_id, result.goldMineSlots)

    return NextResponse.json({
      slots,
      gold_collected: result.reward,
      gems_collected: result.gemReward,
      gold: result.updatedCharacter.gold,
      gems: userGems,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'NO_SESSION') return NextResponse.json({ error: 'No active session for this slot' }, { status: 404 })
      if (error.message === 'NOT_READY') return NextResponse.json({ error: 'Mining session not yet complete' }, { status: 400 })
    }
    console.error('gold-mine collect error:', error)
    return NextResponse.json(
      { error: 'Failed to collect gold mine reward' },
      { status: 500 }
    )
  }
}
