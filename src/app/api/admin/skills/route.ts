import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'
import { cacheDelete } from '@/lib/cache'

// GET — List all skills
export async function GET(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  const skills = await prisma.skill.findMany({
    orderBy: [{ classRestriction: 'asc' }, { sortOrder: 'asc' }, { name: 'asc' }],
  })

  return NextResponse.json({ skills })
}

// POST — Create a new skill
export async function POST(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  try {
    const body = await req.json()
    const {
      skill_key, name, description, class_restriction,
      damage_base, damage_scaling, damage_type, target_type,
      cooldown, mana_cost, effect_json,
      unlock_level, max_rank, rank_scaling,
      icon, sort_order, is_active,
    } = body

    if (!skill_key || !name) {
      return NextResponse.json({ error: 'skill_key and name are required' }, { status: 400 })
    }

    const skill = await prisma.skill.create({
      data: {
        skillKey: skill_key,
        name,
        description: description ?? null,
        classRestriction: class_restriction ?? null,
        damageBase: damage_base ?? 0,
        damageScaling: damage_scaling ?? null,
        damageType: damage_type ?? 'physical',
        targetType: target_type ?? 'single_enemy',
        cooldown: cooldown ?? 0,
        manaCost: mana_cost ?? 0,
        effectJson: effect_json ?? null,
        unlockLevel: unlock_level ?? 1,
        maxRank: max_rank ?? 5,
        rankScaling: rank_scaling ?? 0.1,
        icon: icon ?? null,
        sortOrder: sort_order ?? 0,
        isActive: is_active ?? true,
      },
    })

    cacheDelete('skills:catalog')
    return NextResponse.json({ skill }, { status: 201 })
  } catch (error: unknown) {
    if (error instanceof Error && error.message.includes('Unique constraint')) {
      return NextResponse.json({ error: 'Skill key already exists' }, { status: 409 })
    }
    console.error('admin create skill error:', error)
    return NextResponse.json({ error: 'Failed to create skill' }, { status: 500 })
  }
}

// PUT — Update an existing skill
export async function PUT(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  try {
    const body = await req.json()
    const { id, ...updates } = body

    if (!id) {
      return NextResponse.json({ error: 'id is required' }, { status: 400 })
    }

    const dataMap: Record<string, string> = {
      skill_key: 'skillKey', name: 'name', description: 'description',
      class_restriction: 'classRestriction', damage_base: 'damageBase',
      damage_scaling: 'damageScaling', damage_type: 'damageType',
      target_type: 'targetType', cooldown: 'cooldown', mana_cost: 'manaCost',
      effect_json: 'effectJson', unlock_level: 'unlockLevel', max_rank: 'maxRank',
      rank_scaling: 'rankScaling', icon: 'icon', sort_order: 'sortOrder',
      is_active: 'isActive',
    }

    const data: Record<string, unknown> = {}
    for (const [snakeKey, prismaKey] of Object.entries(dataMap)) {
      if (updates[snakeKey] !== undefined) {
        data[prismaKey] = updates[snakeKey]
      }
    }

    const skill = await prisma.skill.update({ where: { id }, data })

    cacheDelete('skills:catalog')
    return NextResponse.json({ skill })
  } catch (error) {
    console.error('admin update skill error:', error)
    return NextResponse.json({ error: 'Failed to update skill' }, { status: 500 })
  }
}

// DELETE — Delete a skill
export async function DELETE(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  const id = req.nextUrl.searchParams.get('id')
  if (!id) {
    return NextResponse.json({ error: 'id query param required' }, { status: 400 })
  }

  try {
    await prisma.skill.delete({ where: { id } })
    cacheDelete('skills:catalog')
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('admin delete skill error:', error)
    return NextResponse.json({ error: 'Failed to delete skill' }, { status: 500 })
  }
}
