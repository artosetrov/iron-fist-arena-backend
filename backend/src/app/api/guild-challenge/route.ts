import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { getActiveGuildChallenge, createWeeklyChallenge } from '@/lib/game/guild-challenge'

/**
 * GET /api/guild-challenge
 * Returns the current active guild challenge with progress.
 * If no active challenge exists and ?create=true (admin), creates one.
 */
export async function GET(req: NextRequest) {
  try {
    const user = await getAuthUser(req)
    if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

    let challenge = await getActiveGuildChallenge(prisma)

    // Auto-create if none exists (first request bootstraps)
    if (!challenge) {
      await createWeeklyChallenge(prisma)
      challenge = await getActiveGuildChallenge(prisma)
    }

    if (!challenge) {
      return NextResponse.json({ challenge: null })
    }

    const now = new Date()
    const totalSeconds = (challenge.endAt.getTime() - challenge.startAt.getTime()) / 1000
    const remainingSeconds = Math.max(0, (challenge.endAt.getTime() - now.getTime()) / 1000)
    const progressPercent = challenge.goalTarget > 0
      ? Math.min(100, Math.round((challenge.currentProgress / challenge.goalTarget) * 100))
      : 0

    return NextResponse.json({
      challenge: {
        id: challenge.id,
        title: challenge.title,
        description: challenge.description,
        goalType: challenge.goalType,
        goalTarget: challenge.goalTarget,
        currentProgress: challenge.currentProgress,
        progressPercent,
        goldReward: challenge.goldReward,
        gemReward: challenge.gemReward,
        completed: challenge.completed,
        claimed: challenge.claimed,
        startAt: challenge.startAt.toISOString(),
        endAt: challenge.endAt.toISOString(),
        remainingSeconds: Math.floor(remainingSeconds),
        totalSeconds: Math.floor(totalSeconds),
      },
    })
  } catch (error) {
    console.error('guild-challenge GET error:', error)
    return NextResponse.json({ error: 'Internal error' }, { status: 500 })
  }
}

/**
 * POST /api/guild-challenge
 * Body: { action: "claim", challengeId: string }
 * Claims the reward for a completed guild challenge.
 */
export async function POST(req: NextRequest) {
  try {
    const user = await getAuthUser(req)
    if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

    const body = await req.json()
    const { action, challengeId } = body

    if (action !== 'claim') {
      return NextResponse.json({ error: 'Invalid action' }, { status: 400 })
    }

    if (!challengeId) {
      return NextResponse.json({ error: 'Missing challengeId' }, { status: 400 })
    }

    // Get the player's character
    const character = await prisma.character.findFirst({
      where: { userId: user.id },
    })
    if (!character) {
      return NextResponse.json({ error: 'No character found' }, { status: 404 })
    }

    // Claim reward inside transaction with row lock
    const result = await prisma.$transaction(async (tx) => {
      // Lock the challenge row
      const challenges = await tx.$queryRawUnsafe<Array<{
        id: string; completed: boolean; claimed: boolean;
        gold_reward: number; gem_reward: number;
      }>>(
        `SELECT id, completed, claimed, gold_reward, gem_reward FROM guild_challenges WHERE id = $1 FOR UPDATE`,
        challengeId,
      )

      if (challenges.length === 0) {
        throw new Error('Challenge not found')
      }

      const ch = challenges[0]

      if (!ch.completed) {
        throw new Error('Challenge not completed yet')
      }

      if (ch.claimed) {
        throw new Error('Already claimed')
      }

      // Mark as claimed
      await tx.$executeRawUnsafe(
        `UPDATE guild_challenges SET claimed = true WHERE id = $1`,
        challengeId,
      )

      // Award gold + gems to the player
      await tx.character.update({
        where: { id: character.id },
        data: {
          gold: { increment: ch.gold_reward },
          gems: { increment: ch.gem_reward },
        },
      })

      return { goldReward: ch.gold_reward, gemReward: ch.gem_reward }
    })

    return NextResponse.json({
      success: true,
      goldReward: result.goldReward,
      gemReward: result.gemReward,
    })
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Internal error'
    if (['Challenge not found', 'Challenge not completed yet', 'Already claimed'].includes(message)) {
      return NextResponse.json({ error: message }, { status: 400 })
    }
    console.error('guild-challenge POST error:', error)
    return NextResponse.json({ error: 'Internal error' }, { status: 500 })
  }
}
