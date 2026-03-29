import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { calculateCurrentHp } from '@/lib/game/hp-regen'
import { rateLimit } from '@/lib/rate-limit'

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const ip = req.headers.get('x-forwarded-for')?.split(',')[0].trim() || 'unknown'
    if (!(await rateLimit(`profile:${ip}`, 60, 60_000))) {
      return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
    }

    const { id } = await params

    const raw = await prisma.character.findUnique({
      where: { id },
      include: {
        equipment: {
          where: { isEquipped: true },
          include: {
            item: {
              select: {
                id: true,
                catalogId: true,
                itemName: true,
                itemType: true,
                rarity: true,
                itemLevel: true,
                baseStats: true,
                specialEffect: true,
                uniquePassive: true,
                setName: true,
                imageUrl: true,
                imageKey: true,
                classRestriction: true,
                description: true,
              },
            },
          },
        },
      },
    })

    if (!raw) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    // Compute current HP with regen (public — no stamina exposed)
    const hpResult = await calculateCurrentHp(
      raw.currentHp,
      raw.maxHp,
      raw.lastHpUpdate ?? new Date()
    )

    // Map equipped items to a flat array
    const equipment = raw.equipment.map((eq) => ({
      id: eq.id,
      itemName: eq.item.itemName,
      itemType: eq.item.itemType,
      rarity: eq.item.rarity,
      itemLevel: eq.item.itemLevel,
      upgradeLevel: eq.upgradeLevel,
      equippedSlot: eq.equippedSlot,
      baseStats: eq.item.baseStats,
      rolledStats: eq.rolledStats,
      specialEffect: eq.item.specialEffect,
      uniquePassive: eq.item.uniquePassive,
      setName: eq.item.setName,
      imageUrl: eq.item.imageUrl,
      imageKey: eq.item.imageKey,
      durability: eq.durability,
      maxDurability: eq.maxDurability,
    }))

    const profile = {
      id: raw.id,
      characterName: raw.characterName,
      class: raw.class,
      origin: raw.origin,
      gender: raw.gender,
      avatar: raw.avatar,
      level: raw.level,
      prestigeLevel: raw.prestigeLevel,
      // HP
      currentHp: hpResult.hp,
      maxHp: raw.maxHp,
      // PvP
      pvpRating: raw.pvpRating,
      pvpWins: raw.pvpWins,
      pvpLosses: raw.pvpLosses,
      pvpWinStreak: raw.pvpWinStreak,
      // Base stats
      str: raw.str,
      agi: raw.agi,
      vit: raw.vit,
      end: raw.end,
      int: raw.int,
      wis: raw.wis,
      luk: raw.luk,
      cha: raw.cha,
      // Derived
      armor: raw.armor,
      magicResist: raw.magicResist,
      // Stance
      combatStance: raw.combatStance,
      // Equipment
      equipment,
    }

    return NextResponse.json({ profile })
  } catch (error) {
    console.error('public profile error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch profile' },
      { status: 500 }
    )
  }
}
