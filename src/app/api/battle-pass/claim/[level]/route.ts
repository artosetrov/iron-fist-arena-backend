import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { bpXpForLevel } from '@/lib/game/balance'

function calculateBpLevel(totalXp: number): number {
  let remaining = totalXp
  let level = 0

  while (true) {
    const needed = bpXpForLevel(level + 1)
    if (remaining < needed) return level
    remaining -= needed
    level++
  }
}

export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ level: string }> }
) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const { level: levelParam } = await params
    const targetLevel = parseInt(levelParam, 10)

    if (isNaN(targetLevel) || targetLevel < 1) {
      return NextResponse.json({ error: 'Invalid level' }, { status: 400 })
    }

    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: character_id },
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

    // Get battle pass
    const battlePass = await prisma.battlePass.findFirst({
      where: { characterId: character_id, seasonId: activeSeason.id },
    })

    if (!battlePass) {
      return NextResponse.json({ error: 'Battle pass not found' }, { status: 404 })
    }

    // Verify character has reached this level
    const currentLevel = calculateBpLevel(battlePass.bpXp)

    if (currentLevel < targetLevel) {
      return NextResponse.json(
        { error: `Battle pass level ${targetLevel} not yet reached (current: ${currentLevel})` },
        { status: 400 }
      )
    }

    // Find the reward(s) for this level
    const rewards = await prisma.battlePassReward.findMany({
      where: { seasonId: activeSeason.id, bpLevel: targetLevel },
    })

    if (rewards.length === 0) {
      return NextResponse.json({ error: 'No rewards found for this level' }, { status: 404 })
    }

    const claimedRewards = []

    for (const reward of rewards) {
      // Check premium requirement
      if (reward.isPremium && !battlePass.premium) {
        continue // skip premium rewards for free players
      }

      // Check if already claimed
      const existingClaim = await prisma.battlePassClaim.findUnique({
        where: {
          characterId_rewardId: {
            characterId: character_id,
            rewardId: reward.id,
          },
        },
      })

      if (existingClaim) {
        continue // already claimed
      }

      // Create the claim
      await prisma.battlePassClaim.create({
        data: {
          characterId: character_id,
          battlePassId: battlePass.id,
          rewardId: reward.id,
        },
      })

      // Apply the reward
      if (reward.rewardType === 'gold') {
        await prisma.character.update({
          where: { id: character_id },
          data: { gold: { increment: reward.rewardAmount } },
        })
      } else if (reward.rewardType === 'gems') {
        await prisma.user.update({
          where: { id: user.id },
          data: { gems: { increment: reward.rewardAmount } },
        })
      } else if (reward.rewardType === 'xp') {
        await prisma.character.update({
          where: { id: character_id },
          data: { currentXp: { increment: reward.rewardAmount } },
        })
      }

      claimedRewards.push({
        rewardType: reward.rewardType,
        rewardId: reward.rewardId,
        rewardAmount: reward.rewardAmount,
        isPremium: reward.isPremium,
      })
    }

    if (claimedRewards.length === 0) {
      return NextResponse.json(
        { error: 'No claimable rewards at this level (already claimed or premium required)' },
        { status: 400 }
      )
    }

    return NextResponse.json({
      level: targetLevel,
      rewards: claimedRewards,
    })
  } catch (error) {
    console.error('claim battle pass reward error:', error)
    return NextResponse.json(
      { error: 'Failed to claim battle pass reward' },
      { status: 500 }
    )
  }
}
