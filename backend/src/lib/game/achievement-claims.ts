import { CosmeticType, type Prisma } from '@prisma/client'
import { prisma } from '@/lib/prisma'
import { awardBattlePassXp } from './battle-pass'
import type { AchievementDef } from './achievement-catalog'
import { grantRewardEntries, type RewardGrantEntry, type RewardGrantResult } from './reward-grants'

type SupportedAchievementRewardType = AchievementDef['rewardType']

type ClaimResult = {
  rewardType: SupportedAchievementRewardType
  rewardAmount: number
  rewardId: string | null
  rewardGrantResult: RewardGrantResult
}

function toRewardEntry(def: AchievementDef): RewardGrantEntry | null {
  switch (def.rewardType) {
    case 'gold':
      return { type: 'gold', quantity: def.rewardAmount }
    case 'gems':
      return { type: 'gems', quantity: def.rewardAmount }
    case 'xp':
      return { type: 'xp', quantity: def.rewardAmount }
    case 'title':
    case 'frame':
      return null
    default:
      throw new Error('UNSUPPORTED_REWARD_TYPE')
  }
}

function toCosmeticReward(
  def: AchievementDef,
): { type: CosmeticType; refId: string } | null {
  if (!def.rewardId) return null

  switch (def.rewardType) {
    case 'title':
      return { type: 'title', refId: def.rewardId }
    case 'frame':
      return { type: 'frame', refId: def.rewardId }
    default:
      return null
  }
}

async function readRewardGrantSnapshot(
  tx: Prisma.TransactionClient,
  userId: string,
  characterId: string,
): Promise<RewardGrantResult> {
  const [updatedUser, updatedChar] = await Promise.all([
    tx.user.findUnique({
      where: { id: userId },
      select: { gold: true, gems: true },
    }),
    tx.character.findUnique({
      where: { id: characterId },
      select: { currentXp: true, level: true },
    }),
  ])

  if (!updatedUser) throw new Error('USER_NOT_FOUND')
  if (!updatedChar) throw new Error('CHARACTER_NOT_FOUND')

  return {
    gold: updatedUser.gold,
    gems: updatedUser.gems,
    xp: updatedChar.currentXp,
    level: updatedChar.level,
    levelUpResult: null,
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
  const cosmeticReward = rewardEntry ? null : toCosmeticReward(achievementDef)

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

    let rewardGrantResult: RewardGrantResult
    if (rewardEntry) {
      rewardGrantResult = await grantRewardEntries(tx, {
        userId,
        characterId,
        rewards: [rewardEntry],
      })
    } else if (cosmeticReward) {
      const existingCosmetic = await tx.cosmetic.findFirst({
        where: {
          userId,
          type: cosmeticReward.type,
          refId: cosmeticReward.refId,
        },
        select: { id: true },
      })

      if (!existingCosmetic) {
        await tx.cosmetic.create({
          data: {
            userId,
            type: cosmeticReward.type,
            refId: cosmeticReward.refId,
          },
        })
      }

      rewardGrantResult = await readRewardGrantSnapshot(tx, userId, characterId)
    } else {
      throw new Error('UNSUPPORTED_REWARD_TYPE')
    }

    await tx.achievement.update({
      where: { id: achievement.id },
      data: { completed: true, rewardClaimed: true },
    })

    await awardBattlePassXp(tx, characterId, battlePassXpAward)

    return {
      rewardType: achievementDef.rewardType,
      rewardAmount: achievementDef.rewardAmount,
      rewardId: achievementDef.rewardId ?? null,
      rewardGrantResult,
    }
  })
}
