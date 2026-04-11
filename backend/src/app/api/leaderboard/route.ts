import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { cacheGet, cacheSet } from '@/lib/cache'
import { rateLimit } from '@/lib/rate-limit'
// W3.D5 — BAL-05 ladder: 8 tiers × 3 divisions + Master + GM + Challenger
import { tierFromRating } from '@/lib/game/tier'

const LEADERBOARD_CACHE_TTL = 60 * 1000 // 60 seconds

export async function GET(req: NextRequest) {
  try {
    const ip = req.headers.get('x-forwarded-for')?.split(',')[0].trim() || 'unknown'
    if (!(await rateLimit(`leaderboard:${ip}`, 30, 60_000))) {
      return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
    }

    const limitParam = req.nextUrl.searchParams.get('limit')
    const limit = Math.min(Math.max(parseInt(limitParam || '100', 10) || 100, 1), 500)

    // Check cache first — leaderboard is the same for all users
    const cacheKey = `leaderboard:${limit}`
    const cached = await cacheGet<object>(cacheKey)
    if (cached) return NextResponse.json(cached)

    const baseSelect = { id: true, characterName: true, class: true, pvpRating: true, level: true, avatar: true }

    const [byRating, byLevel, byGold] = await Promise.all([
      prisma.character.findMany({ select: baseSelect, orderBy: { pvpRating: 'desc' }, take: limit }),
      prisma.character.findMany({ select: baseSelect, orderBy: { level: 'desc' }, take: limit }),
      prisma.user.findMany({ select: { id: true, gold: true }, orderBy: { gold: 'desc' }, take: limit }),
    ])

    // Fetch character data for gold leaderboard (we have user IDs)
    const goldUserIds = byGold.map(u => u.id)
    const goldCharacters = await prisma.character.findMany({
      where: { userId: { in: goldUserIds } },
      // W3.D5 — include pvpRating so we can surface the TierBadge on the gold list too.
      select: { id: true, characterName: true, class: true, avatar: true, level: true, userId: true, pvpRating: true },
    })

    // W3.D5 — BAL-05: resolve tier server-side using rating + leaderboard rank
    // so iOS can render a TierBadge without duplicating the ladder math.
    // Challenger is a top-N cutoff by absolute rank, so we must know the rank
    // before resolving the tier — that's why this runs inside `mapEntry`.
    const mapEntry = (c: typeof byRating[0] & { gold?: number }, i: number, valueKey: 'pvpRating' | 'level') => {
      const rank = i + 1
      // Tier is computed from actual pvpRating (not from the `value` slot, which
      // might be `level` for the level leaderboard). This keeps the badge
      // semantically stable across all sort orders.
      const info = tierFromRating(c.pvpRating, valueKey === 'pvpRating' ? rank : undefined)
      return {
        characterId: c.id,
        characterName: c.characterName,
        class: c.class,
        avatar: c.avatar,
        level: c.level,
        value: c[valueKey as keyof typeof c],
        rank,
        tierKey: info.tier,
        division: info.division,
        tierLabel: info.label,
      }
    }

    const mapGoldEntry = (user: typeof byGold[0], char: typeof goldCharacters[0] | undefined, i: number) => {
      // Gold list: tier reflects the character's actual PvP rating, not their
      // rank within the gold list (so Challenger is never awarded here — it
      // would be misleading: that's the rating list's job).
      const info = char ? tierFromRating(char.pvpRating) : null
      return {
        characterId: char?.id || '',
        characterName: char?.characterName || `User ${user.id.slice(0, 8)}`,
        class: char?.class || 'unknown',
        avatar: char?.avatar || 'default',
        level: char?.level || 0,
        value: user.gold,
        rank: i + 1,
        tierKey: info?.tier ?? null,
        division: info?.division ?? null,
        tierLabel: info?.label ?? null,
      }
    }

    const result = {
      rating: byRating.map((c, i) => mapEntry(c, i, 'pvpRating')),
      level: byLevel.map((c, i) => mapEntry(c, i, 'level')),
      gold: byGold.map((u, i) => {
        const char = goldCharacters.find(c => c.userId === u.id)
        return mapGoldEntry(u, char, i)
      }),
    }

    await cacheSet(cacheKey, result, LEADERBOARD_CACHE_TTL)
    return NextResponse.json(result)
  } catch (error) {
    console.error('leaderboard error:', error)
    return NextResponse.json({ error: 'Failed to fetch leaderboard' }, { status: 500 })
  }
}
