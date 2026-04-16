import type { PrismaClient } from '@prisma/client'
import {
  REFERRAL_BONUS,
  isReferralCodeLike,
  normalizeReferralCode,
} from '../src/lib/game/tutorial'

type ReferralBackfillClient = Pick<
  PrismaClient,
  'character' | 'referralRewardClaim' | 'user' | '$transaction'
>

type PendingReferralReward = {
  inviteeCharacterId: string
  referrerCharacterId: string
  referrerUserId: string
  referrerReferralCode: string | null
}

export interface ReferralRewardBackfillResult {
  dryRun: boolean
  scannedInvitees: number
  pendingRewards: number
  appliedRewards: number
  skippedExisting: number
  skippedInvalid: number
  skippedSelfReferral: number
  totalGold: number
  totalGems: number
  preview: Array<{
    inviteeCharacterId: string
    referrerCharacterId: string
    referrerReferralCode: string | null
  }>
}

function buildExistingClaimKey(referrerCharacterId: string, inviteeCharacterId: string): string {
  return `${referrerCharacterId}:${inviteeCharacterId}`
}

export async function backfillReferralRewardClaims(
  prisma: ReferralBackfillClient,
  options: { apply?: boolean } = {},
): Promise<ReferralRewardBackfillResult> {
  const dryRun = options.apply !== true

  const invitees = await prisma.character.findMany({
    where: {
      level: { gte: REFERRAL_BONUS.inviteeLevelThreshold },
      referredBy: { not: null },
    },
    select: {
      id: true,
      referredBy: true,
    },
    orderBy: { id: 'asc' },
  })

  if (invitees.length === 0) {
    return {
      dryRun,
      scannedInvitees: 0,
      pendingRewards: 0,
      appliedRewards: 0,
      skippedExisting: 0,
      skippedInvalid: 0,
      skippedSelfReferral: 0,
      totalGold: 0,
      totalGems: 0,
      preview: [],
    }
  }

  const existingClaims = await prisma.referralRewardClaim.findMany({
    where: {
      inviteeCharacterId: { in: invitees.map((invitee) => invitee.id) },
    },
    select: {
      referrerCharacterId: true,
      inviteeCharacterId: true,
    },
  })
  const existingClaimKeys = new Set(
    existingClaims.map((claim) =>
      buildExistingClaimKey(claim.referrerCharacterId, claim.inviteeCharacterId),
    ),
  )

  const referralValues = Array.from(
    new Set(
      invitees
        .map((invitee) => invitee.referredBy)
        .filter((value): value is string => Boolean(value)),
    ),
  )

  const referralCodes = Array.from(
    new Set(
      referralValues
        .filter((value) => isReferralCodeLike(value))
        .map((value) => normalizeReferralCode(value)),
    ),
  )

  const referrers = await prisma.character.findMany({
    where: {
      OR: [
        { id: { in: referralValues } },
        ...(referralCodes.length > 0 ? [{ referralCode: { in: referralCodes } }] : []),
      ],
    },
    select: {
      id: true,
      userId: true,
      referralCode: true,
    },
  })

  const referrerById = new Map(referrers.map((referrer) => [referrer.id, referrer]))
  const referrerByCode = new Map(
    referrers
      .filter((referrer) => Boolean(referrer.referralCode))
      .map((referrer) => [normalizeReferralCode(referrer.referralCode as string), referrer]),
  )

  const pendingRewards: PendingReferralReward[] = []
  let skippedExisting = 0
  let skippedInvalid = 0
  let skippedSelfReferral = 0

  for (const invitee of invitees) {
    const referralValue = invitee.referredBy
    if (!referralValue) {
      skippedInvalid += 1
      continue
    }

    const referrer =
      referrerById.get(referralValue)
      ?? (isReferralCodeLike(referralValue)
        ? referrerByCode.get(normalizeReferralCode(referralValue))
        : undefined)

    if (!referrer) {
      skippedInvalid += 1
      continue
    }

    if (referrer.id === invitee.id) {
      skippedSelfReferral += 1
      continue
    }

    const claimKey = buildExistingClaimKey(referrer.id, invitee.id)
    if (existingClaimKeys.has(claimKey)) {
      skippedExisting += 1
      continue
    }

    pendingRewards.push({
      inviteeCharacterId: invitee.id,
      referrerCharacterId: referrer.id,
      referrerUserId: referrer.userId,
      referrerReferralCode: referrer.referralCode,
    })
  }

  let appliedRewards = 0

  if (!dryRun && pendingRewards.length > 0) {
    await prisma.$transaction(async (tx) => {
      const currencyByUserId = new Map<string, { gold: number; gems: number }>()

      for (const reward of pendingRewards) {
        try {
          await tx.referralRewardClaim.create({
            data: {
              referrerCharacterId: reward.referrerCharacterId,
              inviteeCharacterId: reward.inviteeCharacterId,
            },
          })
        } catch (error) {
          const duplicateCode = (error as { code?: string } | null)?.code
          if (duplicateCode === 'P2002') {
            continue
          }
          throw error
        }

        appliedRewards += 1

        const existingCurrency = currencyByUserId.get(reward.referrerUserId) ?? {
          gold: 0,
          gems: 0,
        }
        existingCurrency.gold += REFERRAL_BONUS.referrerGold
        existingCurrency.gems += REFERRAL_BONUS.referrerGems
        currencyByUserId.set(reward.referrerUserId, existingCurrency)
      }

      for (const [userId, totals] of currencyByUserId) {
        const data: {
          gold?: { increment: number }
          gems?: { increment: number }
        } = {}
        if (totals.gold > 0) {
          data.gold = { increment: totals.gold }
        }
        if (totals.gems > 0) {
          data.gems = { increment: totals.gems }
        }

        await tx.user.update({
          where: { id: userId },
          data,
        })
      }
    })
  }

  const effectiveRewards = dryRun ? pendingRewards.length : appliedRewards

  return {
    dryRun,
    scannedInvitees: invitees.length,
    pendingRewards: pendingRewards.length,
    appliedRewards,
    skippedExisting,
    skippedInvalid,
    skippedSelfReferral,
    totalGold: effectiveRewards * REFERRAL_BONUS.referrerGold,
    totalGems: effectiveRewards * REFERRAL_BONUS.referrerGems,
    preview: pendingRewards.slice(0, 20).map((reward) => ({
      inviteeCharacterId: reward.inviteeCharacterId,
      referrerCharacterId: reward.referrerCharacterId,
      referrerReferralCode: reward.referrerReferralCode,
    })),
  }
}
