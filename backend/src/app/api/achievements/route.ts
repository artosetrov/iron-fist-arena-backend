import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { getAchievementCatalog } from '@/lib/game/achievement-catalog'

// Human-readable display metadata for achievements.
// These are the titles and descriptions the player sees in the UI.
const ACHIEVEMENT_DISPLAY: Record<string, { title: string; description: string }> = {
  // PvP
  pvp_first_blood:  { title: 'First Blood',      description: 'Win your first PvP battle' },
  pvp_wins_10:      { title: '10 Victories',      description: 'Win 10 PvP battles' },
  pvp_wins_50:      { title: '50 Victories',      description: 'Win 50 PvP battles' },
  pvp_wins_100:     { title: 'Centurion',         description: 'Win 100 PvP battles' },
  pvp_wins_500:     { title: 'Warmaster',         description: 'Win 500 PvP battles' },
  pvp_streak_5:     { title: 'On Fire',           description: 'Win 5 PvP battles in a row' },
  pvp_streak_10:    { title: 'Unstoppable',       description: 'Win 10 PvP battles in a row' },
  revenge_first:    { title: 'Sweet Revenge',     description: 'Win your first revenge battle' },
  revenge_wins_10:  { title: 'Nemesis',           description: 'Win 10 revenge battles' },
  // Progression
  reach_level_10:   { title: 'Adventurer',        description: 'Reach level 10' },
  reach_level_25:   { title: 'Veteran',           description: 'Reach level 25' },
  reach_level_50:   { title: 'Legend',             description: 'Reach level 50' },
  first_prestige:   { title: 'Reborn',            description: 'Prestige for the first time' },
  prestige_3:       { title: 'Thrice Forged',     description: 'Reach prestige 3' },
  // Ranking
  rank_silver:      { title: 'Silver Rank',       description: 'Achieve Silver rank (1,200 rating)' },
  rank_gold:        { title: 'Gold Rank',         description: 'Achieve Gold rank (1,500 rating)' },
  rank_diamond:     { title: 'Diamond Rank',      description: 'Achieve Diamond rank (1,800 rating)' },
  rank_grandmaster: { title: 'Grandmaster',       description: 'Achieve Grandmaster rank (2,200 rating)' },
}

/** Fallback: convert achievement key to a readable title. */
function formatKeyFallback(key: string): string {
  return key.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
}

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')

    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { userId: true },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Load catalog from DB (falls back to hardcoded)
    const catalog = await getAchievementCatalog()

    // Get existing achievements
    let achievements = await prisma.achievement.findMany({
      where: { characterId },
      orderBy: { achievementKey: 'asc' },
    })

    // If no achievements exist, initialize from catalog
    if (achievements.length === 0) {
      const catalogKeys = Object.keys(catalog)

      const createData = catalogKeys.map((key) => ({
        characterId,
        achievementKey: key,
        target: catalog[key].target,
        progress: 0,
        completed: false,
        rewardClaimed: false,
      }))

      await prisma.achievement.createMany({ data: createData })

      achievements = await prisma.achievement.findMany({
        where: { characterId },
        orderBy: { achievementKey: 'asc' },
      })
    }

    // Enrich with catalog metadata and transform to iOS-compatible format
    const enriched = achievements.map((a) => {
      const def = catalog[a.achievementKey]
      const rewardType = def?.rewardType ?? 'gold'
      const rewardAmount = def?.rewardAmount ?? 0
      const reward =
        rewardType === 'gold'
          ? { gold: rewardAmount }
          : rewardType === 'gems'
          ? { gems: rewardAmount }
          : rewardType === 'title'
          ? { title: def?.rewardId ?? 'unknown' }
          : rewardType === 'frame'
          ? { frame: def?.rewardId ?? 'unknown' }
          : null

      const key = a.achievementKey
      const meta = ACHIEVEMENT_DISPLAY[key]

      return {
        key,
        category: def?.category ?? 'unknown',
        title: meta?.title ?? formatKeyFallback(key),
        description: meta?.description ?? `Reach ${a.target}`,
        target: a.target,
        progress: a.progress,
        completed: a.completed || a.progress >= a.target,
        rewardClaimed: a.rewardClaimed,
        reward,
      }
    })

    return NextResponse.json({ achievements: enriched })
  } catch (error) {
    console.error('get achievements error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch achievements' },
      { status: 500 }
    )
  }
}
