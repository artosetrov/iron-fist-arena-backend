import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { SKILLS } from '@/lib/game/balance'
import { cacheDelete } from '@/lib/cache'
import { rateLimit } from '@/lib/rate-limit'

// POST — Upgrade a skill's rank
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`skills-upgrade:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const { character_id, skill_id } = await req.json()

    if (!character_id || !skill_id) {
      return NextResponse.json({ error: 'character_id and skill_id are required' }, { status: 400 })
    }

    const result = await prisma.$transaction(async (tx) => {
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true, gold: true },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      const charSkill = await tx.characterSkill.findUnique({
        where: { characterId_skillId: { characterId: character_id, skillId: skill_id } },
        include: { skill: true },
      })
      if (!charSkill) throw new Error('NOT_LEARNED')

      if (charSkill.rank >= charSkill.skill.maxRank) {
        throw new Error('MAX_RANK')
      }

      const cost = SKILLS.UPGRADE_GOLD_BASE + charSkill.rank * SKILLS.UPGRADE_GOLD_PER_RANK
      if (character.gold < cost) {
        throw new Error('NOT_ENOUGH_GOLD')
      }

      // Deduct gold and upgrade rank
      await tx.character.update({
        where: { id: character_id },
        data: { gold: { decrement: cost } },
      })

      const updated = await tx.characterSkill.update({
        where: { id: charSkill.id },
        data: { rank: { increment: 1 } },
        include: { skill: true },
      })

      return { updated, cost, goldRemaining: character.gold - cost }
    })

    // Invalidate cache
    await cacheDelete(`skills:char:${character_id}`)

    return NextResponse.json({
      skill: {
        id: result.updated.id,
        name: result.updated.skill.name,
        rank: result.updated.rank,
        max_rank: result.updated.skill.maxRank,
      },
      gold_spent: result.cost,
      gold_remaining: result.goldRemaining,
    })
  } catch (error) {
    if (error instanceof Error) {
      const map: Record<string, { msg: string; status: number }> = {
        NOT_FOUND: { msg: 'Character not found', status: 404 },
        FORBIDDEN: { msg: 'Forbidden', status: 403 },
        NOT_LEARNED: { msg: 'Skill not learned yet', status: 400 },
        MAX_RANK: { msg: 'Skill already at maximum rank', status: 400 },
        NOT_ENOUGH_GOLD: { msg: 'Not enough gold', status: 400 },
      }
      const mapped = map[error.message]
      if (mapped) return NextResponse.json({ error: mapped.msg }, { status: mapped.status })
    }
    console.error('upgrade skill error:', error)
    return NextResponse.json({ error: 'Failed to upgrade skill' }, { status: 500 })
  }
}
