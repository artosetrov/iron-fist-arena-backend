import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { calculateCurrentHp } from '@/lib/game/hp-regen'

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const { id } = await params

    const [character, dbUser] = await Promise.all([
      prisma.character.findUnique({
        where: { id },
        include: {
          equipment: { include: { item: true } },
          consumables: true,
        },
      }),
      prisma.user.findUnique({ where: { id: user.id }, select: { gems: true } }),
    ])

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Compute current stamina without writing to DB
    const staminaResult = await calculateCurrentStamina(
      character.currentStamina,
      character.maxStamina,
      character.lastStaminaUpdate ?? new Date()
    )

    // Compute current HP with regen
    const hpResult = await calculateCurrentHp(
      character.currentHp,
      character.maxHp,
      character.lastHpUpdate ?? new Date()
    )

    // Persist regen updates to DB if changed
    const regenUpdates: Record<string, unknown> = {}
    if (staminaResult.updated) {
      regenUpdates.currentStamina = staminaResult.stamina
      regenUpdates.lastStaminaUpdate = new Date()
    }
    if (hpResult.updated) {
      regenUpdates.currentHp = hpResult.hp
      regenUpdates.lastHpUpdate = new Date()
    }
    if (Object.keys(regenUpdates).length > 0) {
      await prisma.character.update({
        where: { id },
        data: regenUpdates,
      })
    }

    return NextResponse.json({
      character: {
        ...character,
        currentStamina: staminaResult.stamina,
        currentHp: hpResult.hp,
        gems: dbUser?.gems ?? 0,
      },
    })
  } catch (error) {
    console.error('get character error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch character' },
      { status: 500 }
    )
  }
}

export async function DELETE(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const { id } = await params

    const character = await prisma.character.findUnique({
      where: { id },
      select: { id: true, userId: true },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // PvpMatch has no onDelete cascade on its FK references — must clean up manually.
    // All other related tables (EquipmentInventory, Achievement, DailyQuest, etc.) have
    // onDelete: Cascade in the schema and are handled automatically by Postgres.
    await prisma.$transaction([
      // Nullify optional FK columns first (winner/loser can be null)
      prisma.pvpMatch.updateMany({ where: { winnerId: id }, data: { winnerId: null } }),
      prisma.pvpMatch.updateMany({ where: { loserId: id }, data: { loserId: null } }),
      // Delete matches where the character is a required participant (player1/player2)
      prisma.pvpMatch.deleteMany({ where: { OR: [{ player1Id: id }, { player2Id: id }] } }),
      // Delete the character — cascades to all other related tables via DB constraints
      prisma.character.delete({ where: { id } }),
    ])

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('delete character error:', error)
    return NextResponse.json(
      { error: 'Failed to delete character' },
      { status: 500 }
    )
  }
}
