import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { getAuthUser } from '@/lib/auth'
import { rateLimit } from '@/lib/rate-limit'

/**
 * Skin catalog. Anonymous callers (onboarding before sign-in) get the plain
 * catalog; signed-in callers also get `owned` per skin so the appearance
 * editor can show Equip instead of a price for skins they already have
 * (default skins, Battle Pass rewards, earlier purchases). Ownership mirrors
 * the check in PATCH /api/characters/[id]/appearance: a Cosmetic row of type
 * `skin` whose refId is the skin key or the skin id.
 */
export async function GET(req: NextRequest) {
  try {
    // Unauthenticated GET — IP rate limit (backend/CLAUDE.md, Rate Limiting).
    const ip = req.headers.get('x-forwarded-for')?.split(',')[0].trim() || 'unknown'
    if (!(await rateLimit(`appearances:${ip}`, 60, 60_000))) {
      return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
    }

    const skins = await prisma.appearanceSkin.findMany({
      orderBy: [{ origin: 'asc' }, { gender: 'asc' }, { sortOrder: 'asc' }],
      select: {
        id: true,
        skinKey: true,
        name: true,
        origin: true,
        gender: true,
        rarity: true,
        priceGold: true,
        priceGems: true,
        imageUrl: true,
        imageKey: true,
        isDefault: true,
        sortOrder: true,
      },
    })

    let ownedRefs = new Set<string>()
    const user = await getAuthUser(req).catch(() => null)
    if (user) {
      const rows = await prisma.cosmetic.findMany({
        where: { userId: user.id, type: 'skin' },
        select: { refId: true },
      })
      ownedRefs = new Set(rows.map((r) => r.refId))
    }

    return NextResponse.json({
      skins: skins.map((s) => ({
        ...s,
        owned: s.isDefault || ownedRefs.has(s.skinKey) || ownedRefs.has(s.id),
      })),
    })
  } catch (error) {
    console.error('Failed to fetch appearances:', error)
    return NextResponse.json({ error: 'Failed to fetch appearances' }, { status: 500 })
  }
}
