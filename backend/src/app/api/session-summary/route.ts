import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/session-summary?character_id=X
 * Returns session stats: recent matches, gold/xp earned, items obtained, quests progressed.
 * "Session" = activity in the last 30 minutes (configurable).
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json({ error: 'character_id required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { userId: true, level: true, currentXp: true, gold: true, pvpRating: true, pvpWins: true, pvpLosses: true },
    })

    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    // Session window: last 30 minutes
    const sessionStart = new Date(Date.now() - 30 * 60 * 1000)

    // Recent PvP matches
    const recentMatches = await prisma.pvpMatch.findMany({
      where: {
        OR: [
          { attackerId: characterId },
          { defenderId: characterId },
        ],
        createdAt: { gte: sessionStart },
      },
      orderBy: { createdAt: 'desc' },
      take: 20,
    })

    const wins = recentMatches.filter(m => m.winnerId === characterId).length
    const losses = recentMatches.length - wins
    const goldEarned = recentMatches.reduce((sum, m) => {
      if (m.attackerId === characterId) return sum + (m.goldReward ?? 0)
      return sum
    }, 0)
    const xpEarned = recentMatches.reduce((sum, m) => {
      if (m.attackerId === characterId) return sum + (m.xpReward ?? 0)
      return sum
    }, 0)

    // Rating change
    const ratingBefore = recentMatches.length > 0
      ? (recentMatches[recentMatches.length - 1].attackerId === characterId
          ? recentMatches[recentMatches.length - 1].attackerRatingBefore
          : recentMatches[recentMatches.length - 1].defenderRatingBefore) ?? character.pvpRating
      : character.pvpRating
    const ratingChange = (character.pvpRating ?? 1000) - (ratingBefore ?? 1000)

    // Recent items gained (from inventory log — fallback to loot count)
    const recentItems = await prisma.item.count({
      where: {
        characterId,
        createdAt: { gte: sessionStart },
      },
    })

    // Daily quests progress
    const today = new Date()
    today.setUTCHours(0, 0, 0, 0)
    const dailyQuests = await prisma.dailyQuest.findMany({
      where: {
        characterId,
        assignedDate: { gte: today },
      },
      select: { questType: true, progress: true, target: true, completed: true, claimed: true },
    })

    const questsCompleted = dailyQuests.filter(q => q.completed).length
    const questsTotal = dailyQuests.length

    return NextResponse.json({
      session: {
        matchesPlayed: recentMatches.length,
        wins,
        losses,
        goldEarned,
        xpEarned,
        ratingChange,
        itemsGained: recentItems,
        questsCompleted,
        questsTotal,
        dailyQuests: dailyQuests.map(q => ({
          type: q.questType,
          progress: q.progress,
          target: q.target,
          completed: q.completed,
          claimed: q.claimed,
        })),
      },
      character: {
        level: character.level,
        currentXp: character.currentXp,
        gold: character.gold,
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
