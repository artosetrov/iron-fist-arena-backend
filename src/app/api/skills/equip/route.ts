import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { SKILLS } from '@/lib/game/balance'
import { cacheDelete } from '@/lib/cache'

// POST — Equip or unequip a skill to a slot
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const { character_id, skill_id, slot_index, equip } = await req.json()

    if (!character_id || !skill_id || equip === undefined) {
      return NextResponse.json({ error: 'character_id, skill_id, and equip are required' }, { status: 400 })
    }

    const result = await prisma.$transaction(async (tx) => {
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      const charSkill = await tx.characterSkill.findUnique({
        where: { characterId_skillId: { characterId: character_id, skillId: skill_id } },
      })
      if (!charSkill) throw new Error('NOT_LEARNED')

      if (equip) {
        // Validate slot index
        if (slot_index === undefined || slot_index < 0 || slot_index >= SKILLS.MAX_EQUIPPED_SLOTS) {
          throw new Error('INVALID_SLOT')
        }

        // Check if slot is occupied by another skill
        const occupying = await tx.characterSkill.findFirst({
          where: { characterId: character_id, isEquipped: true, slotIndex: slot_index },
        })
        if (occupying && occupying.skillId !== skill_id) {
          // Unequip the occupying skill first
          await tx.characterSkill.update({
            where: { id: occupying.id },
            data: { isEquipped: false, slotIndex: null },
          })
        }

        // Equip
        await tx.characterSkill.update({
          where: { id: charSkill.id },
          data: { isEquipped: true, slotIndex: slot_index },
        })
      } else {
        // Unequip
        await tx.characterSkill.update({
          where: { id: charSkill.id },
          data: { isEquipped: false, slotIndex: null },
        })
      }

      // Return all character skills
      return tx.characterSkill.findMany({
        where: { characterId: character_id },
        include: { skill: true },
        orderBy: [{ isEquipped: 'desc' }, { slotIndex: 'asc' }],
      })
    })

    // Invalidate cache
    cacheDelete(`skills:char:${character_id}`)

    return NextResponse.json({
      skills: result.map((cs) => ({
        id: cs.id,
        skill_id: cs.skillId,
        name: cs.skill.name,
        rank: cs.rank,
        is_equipped: cs.isEquipped,
        slot_index: cs.slotIndex,
      })),
    })
  } catch (error) {
    if (error instanceof Error) {
      const map: Record<string, { msg: string; status: number }> = {
        NOT_FOUND: { msg: 'Character not found', status: 404 },
        FORBIDDEN: { msg: 'Forbidden', status: 403 },
        NOT_LEARNED: { msg: 'Skill not learned yet', status: 400 },
        INVALID_SLOT: { msg: `Invalid slot index (0-${SKILLS.MAX_EQUIPPED_SLOTS - 1})`, status: 400 },
      }
      const mapped = map[error.message]
      if (mapped) return NextResponse.json({ error: mapped.msg }, { status: mapped.status })
    }
    console.error('equip skill error:', error)
    return NextResponse.json({ error: 'Failed to equip skill' }, { status: 500 })
  }
}
