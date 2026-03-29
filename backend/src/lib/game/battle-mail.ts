// =============================================================================
// battle-mail.ts — Mail notifications for PvP events
//
// - battle_invite: sent to defender when a challenge is created
// - arena_result: sent to both fighters after any PvP fight
//
// Both use the MailMessage system so they appear in the unified inbox.
// =============================================================================

import { Prisma, PrismaClient } from '@prisma/client'

export type BattleMailFightType = 'arena' | 'revenge' | 'challenge'

export interface BattleMailParams {
  winnerId: string
  loserId: string
  winnerName: string
  loserName: string
  fightType: BattleMailFightType
  matchId: string
  totalTurns: number
  // Winner data
  winnerRatingBefore: number
  winnerRatingAfter: number
  winnerGold: number
  winnerXp: number
  // Loser data
  loserRatingBefore: number
  loserRatingAfter: number
  loserGold: number
  loserXp: number
}

const SENDER_NAME_MAP: Record<BattleMailFightType, string> = {
  arena: 'Arena',
  revenge: 'Arena',
  challenge: 'Challenge',
}

const LABEL_MAP: Record<BattleMailFightType, string> = {
  arena: 'Arena Battle',
  revenge: 'Revenge Battle',
  challenge: 'Challenge Duel',
}

/**
 * Creates battle result mail for both the winner and loser.
 * Each player gets their own MailMessage with personalized content.
 *
 * Mail body is a JSON string with structured battle data that the iOS
 * client parses for rich rendering. Attachments are empty (rewards are
 * already given at fight time — no double-claiming).
 *
 * This function is fire-and-forget — errors are caught and logged.
 */
export async function createBattleResultMail(
  prisma: PrismaClient,
  params: BattleMailParams,
): Promise<void> {
  const {
    winnerId, loserId, winnerName, loserName, fightType,
    matchId, totalTurns,
    winnerRatingBefore, winnerRatingAfter, winnerGold, winnerXp,
    loserRatingBefore, loserRatingAfter, loserGold, loserXp,
  } = params

  const senderName = SENDER_NAME_MAP[fightType]
  const label = LABEL_MAP[fightType]
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days

  // Build structured body for each player
  const winnerBody = JSON.stringify({
    fightType,
    label,
    isWin: true,
    opponentName: loserName,
    opponentId: loserId,
    matchId,
    totalTurns,
    ratingBefore: winnerRatingBefore,
    ratingAfter: winnerRatingAfter,
    ratingChange: winnerRatingAfter - winnerRatingBefore,
    goldReward: winnerGold,
    xpReward: winnerXp,
  })

  const loserBody = JSON.stringify({
    fightType,
    label,
    isWin: false,
    opponentName: winnerName,
    opponentId: winnerId,
    matchId,
    totalTurns,
    ratingBefore: loserRatingBefore,
    ratingAfter: loserRatingAfter,
    ratingChange: loserRatingAfter - loserRatingBefore,
    goldReward: loserGold,
    xpReward: loserXp,
  })

  try {
    await prisma.$transaction([
      // Winner mail
      prisma.mailMessage.create({
        data: {
          subject: `Victory vs ${loserName}`,
          body: winnerBody,
          senderType: 'arena_result',
          senderName,
          attachments: Prisma.JsonNull,
          targetType: 'character',
          expiresAt,
          recipients: {
            create: {
              characterId: winnerId,
              isRead: false,
              isClaimed: false,
            },
          },
        },
      }),
      // Loser mail
      prisma.mailMessage.create({
        data: {
          subject: `Defeat vs ${winnerName}`,
          body: loserBody,
          senderType: 'arena_result',
          senderName,
          attachments: Prisma.JsonNull,
          targetType: 'character',
          expiresAt,
          recipients: {
            create: {
              characterId: loserId,
              isRead: false,
              isClaimed: false,
            },
          },
        },
      }),
    ])
  } catch (error) {
    // Non-fatal — battle result is already persisted in PvpMatch
    console.error('Failed to create battle result mail:', error)
  }
}

// =============================================================================
// Battle Invite Mail (challenge sent → defender's inbox)
// =============================================================================

export interface BattleInviteParams {
  challengeId: string
  challengerId: string
  challengerName: string
  challengerClass: string
  challengerLevel: number
  challengerRating: number
  challengerAvatar: string | null
  defenderId: string
  message: string | null
  goldWager: number
  expiresAt: Date
}

/**
 * Creates a battle_invite mail for the defender when a challenge is sent.
 * The invite appears in the unified inbox with accept/decline actions.
 *
 * Body is a JSON string with challenger info and challengeId so the iOS
 * client can render the invite card and call accept/decline APIs.
 */
export async function createBattleInviteMail(
  prisma: PrismaClient,
  params: BattleInviteParams,
): Promise<void> {
  const body = JSON.stringify({
    challengeId: params.challengeId,
    challengerId: params.challengerId,
    challengerName: params.challengerName,
    challengerClass: params.challengerClass,
    challengerLevel: params.challengerLevel,
    challengerRating: params.challengerRating,
    challengerAvatar: params.challengerAvatar,
    message: params.message,
    goldWager: params.goldWager,
    expiresAt: params.expiresAt.toISOString(),
    status: 'pending',
  })

  try {
    await prisma.mailMessage.create({
      data: {
        subject: `Challenge from ${params.challengerName}`,
        body,
        senderType: 'battle_invite',
        senderName: 'Challenge',
        attachments: Prisma.JsonNull,
        targetType: 'character',
        expiresAt: params.expiresAt,
        recipients: {
          create: {
            characterId: params.defenderId,
            isRead: false,
            isClaimed: false,
          },
        },
      },
    })
  } catch (error) {
    console.error('Failed to create battle invite mail:', error)
  }
}

/**
 * Updates the battle_invite mail body when the challenge status changes
 * (accepted, declined, expired). Uses string search on body to find the
 * mail by challengeId (UUID, globally unique — safe for contains search).
 */
export async function updateBattleInviteStatus(
  prisma: PrismaClient,
  challengeId: string,
  newStatus: 'accepted' | 'declined' | 'expired',
): Promise<void> {
  try {
    const mail = await prisma.mailMessage.findFirst({
      where: {
        senderType: 'battle_invite',
        body: { contains: challengeId },
      },
    })
    if (!mail) return

    // Parse body, update status, write back
    const bodyData = JSON.parse(mail.body)
    bodyData.status = newStatus
    await prisma.mailMessage.update({
      where: { id: mail.id },
      data: { body: JSON.stringify(bodyData) },
    })
  } catch (error) {
    console.error('Failed to update battle invite mail status:', error)
  }
}
