import { prisma } from '@/lib/prisma'
import { awardBattlePassXp } from './battle-pass'
import type { AchievementDef } from './achievement-catalog'
import { grantRewardEntries, type RewardGrantEntry, type RewardGrantResult } from './reward-grants'

type SupportedAchievementRewardType = 'gold' | 'gems' | 'xp'

type ClaimResult = {
  rewardType: SupportedAchievementRewardType
  rewardAmount: number
  rewardGrantResult: RewardGrantResult
}

function toRewardEntry(def: AchievementDef): RewardGrantEntry {
  switch (def.rewardType) {
    case 'gold':
      return { type: 'gold', quantity: def.rewardAmount }
    case 'gems':
      return { type: 'gems', quantity: def.rewardAmount }
    case 'xp':
      return { type: 'xp', quantity: def.rewardAmount }
    default:
      throw new Error('UNSUPPORTED_REWARD_TYPE')
  }
}

export async function claimAchievementReward(args: {
  userId: string
  characterId: string
  achievementKey: string
  achievementDef: AchievementDef
  battlePassXpAward: number
}): Promise<ClaimResult> {
  const { userId, characterId, achievementKey, achievementDef, battlePassXpAward } = args
  const rewardEntry = toRewardEntry(achievementDef)

  return prisma.$transaction(async (tx) => {
    const character = await tx.character.findUnique({
      where: { id: characterId },
      select: { id: true, userId: true },
    })

    if (!character) throw new Error('CHARACTER_NOT_FOUND')
    if (character.userId !== userId) throw new Error('FORBIDDEN')

    const achievements = await tx.$queryRawUnsafe<Array<{
      id: string
      progress: number
      completed: boolean
      rewardClaimed: boolean
    }>>(
      `SELECT id, progress, completed, reward_claimed AS "rewardClaimed"
         FROM achievements
        WHERE character_id = $1 AND achievement_key = $2
        FOR UPDATE`,
      characterId,
      achievementKey,
    )

    const achievement = achievements[0]
    if (!achievement) throw new Error('ACHIEVEMENT_NOT_FOUND')

    const isCompleted = achievement.completed || achievement.progress >= achievementDef.target
    if (!isCompleted) throw new Error('NOT_COMPLETED')
    if (achievement.rewardClaimed) throw new Error('ALREADY_CLAIMED')

    const rewardGrantResult = await grantRewardEntries(tx, {
      userId,
      characterId,
      rewards: [rewardEntry],
    })

    await tx.achievement.update({
      where: { id: achievement.id },
      data: { completed: true, rewardClaimed: true },
    })

    await awardBattlePassXp(tx, characterId, battlePassXpAward)

    return {
      rewardType: rewardEntry.type as SupportedAchievementRewardType,
      rewardAmount: achievementDef.rewardAmount,
      rewardGrantResult,
    }
  })
}
