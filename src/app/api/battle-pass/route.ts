import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { bpXpForLevel } from '@/lib/game/balance'

function formatRewardName(rewardType: string, amount: number): string {
  switch (rewardType) {
    case 'gold': return `${amount} Gold`
    case 'gems': return `${amount} Gems`
    case 'xp': return `${amount} XP`
    case 'stamina': return `${amount} Stamina`
    case 'chest': return 'Chest'
    case 'skin': return 'Skin'
    case 'item': return 'Item'
    default: return rewardType
  }
}

/**
 * Calculate the current BP level from total bpXp.
 * Each level requires bpXpForLevel(level) XP.
 * Level 1 requires bpXpForLevel(1), level 2 requires bpXpForLevel(2), etc.
 */
function calculateBpLevel(totalXp: number): { level: number; xpIntoLevel: number; xpForNext: number } {
  let remaining = totalXp
  let level = 0

  while (true) {
    const needed = bpXpForLevel(level + 1)
    if (remaining < needed) {
      return { level, xpIntoLevel: remaining, xpForNext: needed }
    }
    remaining -= needed
    level++
  }
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

    // Find active season
    const now = new Date()
    const activeSeason = await prisma.season.findFirst({
      where: {
        startAt: { lte: now },
        endAt: { gte: now },
      },
    })

    if (!activeSeason) {
      return NextResponse.json({ error: 'No active season' }, { status: 404 })
    }

    // Get battle pass and rewards in parallel (both depend only on season)
    let [battlePass, rewards] = await Promise.all([
      prisma.battlePass.findFirst({
        where: { characterId, seasonId: activeSeason.id },
      }),
      prisma.battlePassReward.findMany({
        where: { seasonId: activeSeason.id },
        orderBy: [{ bpLevel: 'asc' }, { isPremium: 'asc' }],
      }),
    ])

    if (!battlePass) {
      battlePass = await prisma.battlePass.create({
        data: {
          characterId,
          seasonId: activeSeason.id,
          premium: false,
          bpXp: 0,
        },
      })
    }

    // Calculate current level
    const { level, xpIntoLevel, xpForNext } = calculateBpLevel(battlePass.bpXp)

    // Get claimed rewards
    const claims = await prisma.battlePassClaim.findMany({
      where: { characterId, battlePassId: battlePass.id },
    })

    const claimedRewardIds = new Set(claims.map((c) => c.rewardId))

    // Build rewards with claimed status
    const rewardsWithStatus = rewards.map((r) => ({
      ...r,
      claimed: claimedRewardIds.has(r.id),
      claimable: r.bpLevel <= level && !claimedRewardIds.has(r.id) && (!r.isPremium || battlePass!.premium),
    }))

    // Build free/premium reward arrays in the format iOS expects
    const freeRewards = rewardsWithStatus
      .filter((r) => !r.isPremium)
      .map((r) => ({
        level: r.bpLevel,
        reward_type: r.rewardType,
        reward_name: formatRewardName(r.rewardType, r.rewardAmount),
        amount: r.rewardAmount,
        claimed: r.claimed,
      }))

    const premiumRewards = rewardsWithStatus
      .filter((r) => r.isPremium)
      .map((r) => ({
        level: r.bpLevel,
        reward_type: r.rewardType,
        reward_name: formatRewardName(r.rewardType, r.rewardAmount),
        amount: r.rewardAmount,
        claimed: r.claimed,
      }))

    return NextResponse.json({
      season_name: activeSeason.theme ?? `Season ${activeSeason.number}`,
      current_level: level,
      current_xp: xpIntoLevel,
      xp_to_next: xpForNext,
      has_premium: battlePass.premium,
      free_rewards: freeRewards,
      premium_rewards: premiumRewards,
    })
  } catch (error) {
    console.error('get battle pass error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch battle pass' },
      { status: 500 }
    )
  }
}
