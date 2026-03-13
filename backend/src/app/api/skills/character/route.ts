import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { cacheGet, cacheSet } from '@/lib/cache'

const CACHE_TTL = 5 * 60 * 1000 // 5 minutes

// GET — Get a character's learned and equipped skills
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const characterId = req.nextUrl.searchParams.get('character_id')
  if (!characterId) {
    return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
  }

  const character = await prisma.character.findUnique({
    where: { id: characterId },
    select: { userId: true },
  })
  if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
  if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

  const cacheKey = `skills:char:${characterId}`
  const cached = await cacheGet<unknown[]>(cacheKey)
  if (cached) {
    return NextResponse.json({ skills: cached })
  }

  const characterSkills = await prisma.characterSkill.findMany({
    where: { characterId },
    include: { skill: true },
    orderBy: [{ isEquipped: 'desc' }, { slotIndex: 'asc' }, { createdAt: 'asc' }],
  })

  const skills = characterSkills.map((cs) => ({
    id: cs.id,
    skill_id: cs.skillId,
    skill_key: cs.skill.skillKey,
    name: cs.skill.name,
    description: cs.skill.description,
    class_restriction: cs.skill.classRestriction,
    damage_base: cs.skill.damageBase,
    damage_scaling: cs.skill.damageScaling,
    damage_type: cs.skill.damageType,
    target_type: cs.skill.targetType,
    cooldown: cs.skill.cooldown,
    mana_cost: cs.skill.manaCost,
    effect_json: cs.skill.effectJson,
    unlock_level: cs.skill.unlockLevel,
    max_rank: cs.skill.maxRank,
    rank_scaling: cs.skill.rankScaling,
    icon: cs.skill.icon,
    rank: cs.rank,
    is_equipped: cs.isEquipped,
    slot_index: cs.slotIndex,
  }))

  await cacheSet(cacheKey, skills, CACHE_TTL)

  return NextResponse.json({ skills })
}
