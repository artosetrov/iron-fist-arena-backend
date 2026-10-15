import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { tierFromRating } from '@/lib/game/tier'
import { getPvpLadderRanges } from '@/lib/game/live-config'
import { QUEST_META } from '@/lib/game/daily-quest-meta'

/** Two fights more than this far apart belong to different sessions. */
const SESSION_GAP_MS = 30 * 60 * 1000
/** Never look further back than this for the last session. */
const LOOKBACK_MS = 12 * 60 * 60 * 1000
const MAX_MATCHES = 50
/** Loot is persisted in the same request that completes the fight. */
const LOOT_SLACK_MS = 10 * 1000

type Ladder = Awaited<ReturnType<typeof getPvpLadderRanges>>

/** Rating floor/ceiling of the division `rating` sits in, read off the ladder. */
function divisionProgress(rating: number, ladder: Ladder) {
  const current = tierFromRating(rating, undefined, ladder)
  let floor = rating
  while (floor > 0 && tierFromRating(floor - 1, undefined, ladder).label === current.label) floor--
  let next = rating + 1
  // Ladders are a few thousand points tall; cap the walk so Master+ (open-ended) terminates.
  while (next < rating + 5000 && tierFromRating(next, undefined, ladder).label === current.label) next++
  const hasNext = next < rating + 5000
  return {
    current: rating,
    tierKey: current.tier,
    division: current.division,
    label: current.label,
    nextLabel: hasNext ? tierFromRating(next, undefined, ladder).label : null,
    pointsToNext: hasNext ? next - rating : null,
    progress: hasNext ? (rating - floor) / Math.max(1, next - floor) : 1,
  }
}

/**
 * GET /api/session-summary?character_id=X
 *
 * The player's last play session: their own completed fights (they attacked),
 * chained back from the newest while consecutive fights are < 30 min apart.
 * Fights where they were only the defender happened while they were away and
 * are not part of their session.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  if (!(await rateLimit(`session-summary:${user.id}`, 30, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json({ error: 'character_id required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { userId: true, level: true, currentXp: true, pvpRating: true, pvpWins: true, pvpLosses: true },
    })
    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    const recent = await prisma.pvpMatch.findMany({
      where: {
        player1Id: characterId,
        playedAt: { gte: new Date(Date.now() - LOOKBACK_MS) },
        OR: [{ status: 'completed' }, { status: null }],
      },
      orderBy: { playedAt: 'desc' },
      take: MAX_MATCHES,
      select: {
        playedAt: true, updatedAt: true, winnerId: true, goldReward: true, xpReward: true,
        player1RatingBefore: true, player1RatingAfter: true,
      },
    })

    // Walk back from the newest fight until a gap > SESSION_GAP_MS.
    const session: typeof recent = []
    for (const m of recent) {
      const prev = session[session.length - 1]
      if (prev && prev.playedAt.getTime() - m.updatedAt.getTime() > SESSION_GAP_MS) break
      session.push(m)
    }
    const chronological = [...session].reverse()

    const wins = session.filter((m) => m.winnerId === characterId).length
    const goldEarned = session.reduce((sum, m) => sum + (m.goldReward ?? 0), 0)
    const xpEarned = session.reduce((sum, m) => sum + (m.xpReward ?? 0), 0)
    const ratingChange = session.reduce((sum, m) => sum + (m.player1RatingAfter - m.player1RatingBefore), 0)

    // Loot: inventory rows created while a session fight was being completed —
    // not shop purchases made between fights (those used to be counted).
    let loot: { name: string; rarity: string; imageKey: string | null }[] = []
    if (session.length > 0) {
      const from = new Date(chronological[0].playedAt.getTime() - LOOT_SLACK_MS)
      const to = new Date(chronological[chronological.length - 1].updatedAt.getTime() + LOOT_SLACK_MS)
      const rows = await prisma.equipmentInventory.findMany({
        where: { characterId, createdAt: { gte: from, lte: to } },
        orderBy: { createdAt: 'asc' },
        select: { createdAt: true, item: { select: { itemName: true, rarity: true, imageKey: true } } },
      })
      loot = rows
        .filter((r) => {
          const t = r.createdAt.getTime()
          return session.some((m) => t >= m.updatedAt.getTime() - LOOT_SLACK_MS && t <= m.updatedAt.getTime() + LOOT_SLACK_MS)
        })
        .map((r) => ({ name: r.item.itemName, rarity: r.item.rarity, imageKey: r.item.imageKey }))
    }

    const todayStr = new Date().toISOString().split('T')[0]
    const dailyQuests = await prisma.dailyQuest.findMany({
      where: { characterId, day: todayStr },
      orderBy: { createdAt: 'asc' },
      select: { questType: true, progress: true, target: true, completed: true },
    })
    // DB `completed` means the reward was CLAIMED; done = progress reached target.
    const quests = dailyQuests.map((q) => ({
      type: q.questType,
      title: QUEST_META[q.questType]?.description(q.target) ?? q.questType,
      progress: Math.min(q.progress, q.target),
      target: q.target,
      done: q.progress >= q.target,
      claimed: q.completed,
    }))

    const ladder = await getPvpLadderRanges()

    return NextResponse.json({
      session: {
        matchesPlayed: session.length,
        wins,
        losses: session.length - wins,
        goldEarned,
        xpEarned,
        ratingChange,
        itemsGained: loot.length,
        questsCompleted: quests.filter((q) => q.done).length,
        questsTotal: quests.length,
        results: chronological.map((m) => (m.winnerId === characterId ? 'W' : 'L')),
        startedAt: chronological[0]?.playedAt ?? null,
        endedAt: chronological[chronological.length - 1]?.updatedAt ?? null,
        rating: divisionProgress(character.pvpRating ?? 1000, ladder),
        quests,
        loot: loot.slice(0, 20),
        // legacy field kept for older clients
        dailyQuests: dailyQuests.map((q) => ({
          type: q.questType, progress: q.progress, target: q.target, completed: q.completed,
        })),
      },
      character: {
        level: character.level,
        currentXp: character.currentXp,
        rating: character.pvpRating,
        totalWins: character.pvpWins,
        totalLosses: character.pvpLosses,
      },
    })
  } catch (error) {
    console.error('session summary error:', error)
    return NextResponse.json({ error: 'Failed to fetch session summary' }, { status: 500 })
  }
}
