import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { getAchievementCatalog } from '@/lib/game/achievement-catalog'
import { claimAchievementReward } from '@/lib/game/achievement-claims'
import { invalidatePassiveCache, invalidateSkillCache } from '@/lib/game/combat-loader'
import { getBattlePassConfig } from '@/lib/game/live-config'
import { rateLimit } from '@/lib/rate-limit'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`achievements-claim:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, achievement_key } = body

    if (!character_id || !achievement_key) {
      return NextResponse.json(
        { error: 'character_id and achievement_key are required' },
        { status: 400 }
      )
    }

    // Validate achievement key exists in catalog (DB-driven with hardcoded fallback)
    const catalog = await getAchievementCatalog()
    const def = catalog[achievement_key]
    if (!def) {
      return NextResponse.json({ error: 'Invalid achievement key' }, { status: 400 })
    }

    const BATTLE_PASS = await getBattlePassConfig()
    const result = await claimAchievementReward({
      userId: user.id,
      characterId: character_id,
      achievementKey: achievement_key,
      achievementDef: def,
      battlePassXpAward: BATTLE_PASS.BP_XP_PER_ACHIEVEMENT,
    })

    if (result.rewardGrantResult.levelUpResult?.leveledUp) {
      await Promise.all([
        invalidateSkillCache(character_id),
        invalidatePassiveCache(character_id),
      ])
    }

    return NextResponse.json({
      achievement_key,
      reward: {
        type: result.rewardType,
        amount: result.rewardAmount,
      },
      reward_gold: result.rewardType === 'gold' ? result.rewardAmount : 0,
      reward_gems: result.rewardType === 'gems' ? result.rewardAmount : 0,
      reward_xp: result.rewardType === 'xp' ? result.rewardAmount : 0,
      gold: result.rewardGrantResult.gold,
      gems: result.rewardGrantResult.gems,
      xp: result.rewardGrantResult.xp,
      leveled_up: result.rewardGrantResult.levelUpResult?.leveledUp ?? false,
      new_level: result.rewardGrantResult.levelUpResult?.newLevel,
      stat_points_awarded: result.rewardGrantResult.levelUpResult?.statPointsAwarded,
    })
  } catch (error: unknown) {
    if (error instanceof Error) {
      if (error.message === 'CHARACTER_NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'ACHIEVEMENT_NOT_FOUND') return NextResponse.json({ error: 'Achievement not found' }, { status: 404 })
      if (error.message === 'NOT_COMPLETED') return NextResponse.json({ error: 'Achievement not yet completed' }, { status: 400 })
      if (error.message === 'ALREADY_CLAIMED') return NextResponse.json({ error: 'Reward already claimed' }, { status: 400 })
      if (error.message === 'UNSUPPORTED_REWARD_TYPE') {
        return NextResponse.json({ error: 'Achievement reward is misconfigured' }, { status: 500 })
      }
    }

    console.error('claim achievement error:', error)
    return NextResponse.json(
      { error: 'Failed to claim achievement reward' },
      { status: 500 }
    )
  }
}
