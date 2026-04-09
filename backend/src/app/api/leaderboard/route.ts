import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { cacheGet, cacheSet } from '@/lib/cache'
import { rateLimit } from '@/lib/rate-limit'

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
      select: { id: true, characterName: true, class: true, avatar: true, level: true, userId: true },
    })

    const mapEntry = (c: typeof byRating[0] & { gold?: number }, i: number, valueKey: 'pvpRating' | 'level') => ({
      characterId: c.id,
      characterName: c.characterName,
      class: c.class,
      avatar: c.avatar,
      level: c.level,
      value: c[valueKey as keyof typeof c],
      rank: i + 1,
    })

    const mapGoldEntry = (user: typeof byGold[0], char: typeof goldCharacters[0] | undefined, i: number) => ({
      characterId: char?.id || '',
      characterName: char?.characterName || `User ${user.id.slice(0, 8)}`,
      class: char?.class || 'unknown',
      avatar: char?.avatar || 'default',
      level: char?.level || 0,
      value: user.gold,
      rank: i + 1,
    })

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
