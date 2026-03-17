import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { getSkillsConfig } from '@/lib/game/live-config'
import { cacheDelete } from '@/lib/cache'
import { rateLimit } from '@/lib/rate-limit'

// POST — Learn a new skill
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`skills-learn:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const SKILLS = await getSkillsConfig()
    const { character_id, skill_id } = await req.json()

    if (!character_id || !skill_id) {
      return NextResponse.json({ error: 'character_id and skill_id are required' }, { status: 400 })
    }

    const result = await prisma.$transaction(async (tx) => {
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true, level: true, class: true, gold: true },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      const skill = await tx.skill.findUnique({ where: { id: skill_id } })
      if (!skill || !skill.isActive) throw new Error('SKILL_NOT_FOUND')

      // Check class restriction
      if (skill.classRestriction && skill.classRestriction !== character.class) {
        throw new Error('CLASS_RESTRICTED')
      }

      // Check level requirement
      if (character.level < skill.unlockLevel) {
        throw new Error('LEVEL_TOO_LOW')
      }

      // Check if already learned
      const existing = await tx.characterSkill.findUnique({
        where: { characterId_skillId: { characterId: character_id, skillId: skill_id } },
      })
      if (existing) throw new Error('ALREADY_LEARNED')

      // Check gold
      if (character.gold < SKILLS.LEARN_GOLD_COST) {
        throw new Error('NOT_ENOUGH_GOLD')
      }

      // Deduct gold
      await tx.character.update({
        where: { id: character_id },
        data: { gold: { decrement: SKILLS.LEARN_GOLD_COST } },
      })

      // Create character skill
      const charSkill = await tx.characterSkill.create({
        data: { characterId: character_id, skillId: skill_id, rank: 1 },
        include: { skill: true },
      })

      return {
        charSkill,
        goldRemaining: character.gold - SKILLS.LEARN_GOLD_COST,
      }
    })

    // Invalidate cache
    await cacheDelete(`skills:char:${character_id}`)

    return NextResponse.json({
      skill: {
        id: result.charSkill.id,
        skill_id: result.charSkill.skillId,
        name: result.charSkill.skill.name,
        rank: result.charSkill.rank,
        is_equipped: result.charSkill.isEquipped,
      },
      gold_spent: SKILLS.LEARN_GOLD_COST,
      gold_remaining: result.goldRemaining,
    })
  } catch (error) {
    if (error instanceof Error) {
      const map: Record<string, { msg: string; status: number }> = {
        NOT_FOUND: { msg: 'Character not found', status: 404 },
        FORBIDDEN: { msg: 'Forbidden', status: 403 },
        SKILL_NOT_FOUND: { msg: 'Skill not found', status: 404 },
        CLASS_RESTRICTED: { msg: 'This skill is not available for your class', status: 400 },
        LEVEL_TOO_LOW: { msg: 'Character level too low to learn this skill', status: 400 },
        ALREADY_LEARNED: { msg: 'Skill already learned', status: 400 },
        NOT_ENOUGH_GOLD: { msg: 'Not enough gold', status: 400 },
      }
      const mapped = map[error.message]
      if (mapped) return NextResponse.json({ error: mapped.msg }, { status: mapped.status })
    }
    console.error('learn skill error:', error)
    return NextResponse.json({ error: 'Failed to learn skill' }, { status: 500 })
  }
}
