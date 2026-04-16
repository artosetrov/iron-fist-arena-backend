import { describe, expect, it, vi } from 'vitest'
import { backfillReferralRewardClaims } from '../../prisma/referral-reward-backfill'

describe('backfillReferralRewardClaims', () => {
  it('dry-runs mixed canonical and legacy referrals without mutating currency', async () => {
    const prisma = {
      character: {
        findMany: vi.fn()
          .mockResolvedValueOnce([
            { id: 'invitee-1', referredBy: 'referrer-1' },
            { id: 'invitee-2', referredBy: 'FRENDB88' },
            { id: 'invitee-3', referredBy: 'MISSING88' },
            { id: 'invitee-4', referredBy: 'invitee-4' },
          ])
          .mockResolvedValueOnce([
            { id: 'referrer-1', userId: 'user-2', referralCode: 'FRENDB88' },
            { id: 'invitee-4', userId: 'user-4', referralCode: 'SELF4444' },
          ]),
      },
      referralRewardClaim: {
        findMany: vi.fn().mockResolvedValue([
          { referrerCharacterId: 'referrer-1', inviteeCharacterId: 'invitee-1' },
        ]),
      },
      user: {
        update: vi.fn(),
      },
      $transaction: vi.fn(),
    }

    const result = await backfillReferralRewardClaims(prisma as never)

    expect(result).toEqual({
      dryRun: true,
      scannedInvitees: 4,
      pendingRewards: 1,
      appliedRewards: 0,
      skippedExisting: 1,
      skippedInvalid: 1,
      skippedSelfReferral: 1,
      totalGold: 500,
      totalGems: 10,
      preview: [
        {
          inviteeCharacterId: 'invitee-2',
          referrerCharacterId: 'referrer-1',
          referrerReferralCode: 'FRENDB88',
        },
      ],
    })
    expect(prisma.$transaction).not.toHaveBeenCalled()
  })

  it('applies pending rewards once and aggregates user currency updates', async () => {
    const claimCreate = vi.fn().mockResolvedValue(null)
    const userUpdate = vi.fn().mockResolvedValue(null)
    const prisma = {
      character: {
        findMany: vi.fn()
          .mockResolvedValueOnce([
            { id: 'invitee-1', referredBy: 'referrer-1' },
            { id: 'invitee-2', referredBy: 'FRENDB88' },
          ])
          .mockResolvedValueOnce([
            { id: 'referrer-1', userId: 'user-2', referralCode: 'FRENDB88' },
          ]),
      },
      referralRewardClaim: {
        findMany: vi.fn().mockResolvedValue([]),
      },
      user: {
        update: vi.fn(),
      },
      $transaction: vi.fn(async (callback: (tx: {
        referralRewardClaim: { create: typeof claimCreate }
        user: { update: typeof userUpdate }
      }) => Promise<void>) => callback({
        referralRewardClaim: { create: claimCreate },
        user: { update: userUpdate },
      })),
    }

    const result = await backfillReferralRewardClaims(prisma as never, { apply: true })

    expect(result).toEqual({
      dryRun: false,
      scannedInvitees: 2,
      pendingRewards: 2,
      appliedRewards: 2,
      skippedExisting: 0,
      skippedInvalid: 0,
      skippedSelfReferral: 0,
      totalGold: 1000,
      totalGems: 20,
      preview: [
        {
          inviteeCharacterId: 'invitee-1',
          referrerCharacterId: 'referrer-1',
          referrerReferralCode: 'FRENDB88',
        },
        {
          inviteeCharacterId: 'invitee-2',
          referrerCharacterId: 'referrer-1',
          referrerReferralCode: 'FRENDB88',
        },
      ],
    })
    expect(claimCreate).toHaveBeenCalledTimes(2)
    expect(userUpdate).toHaveBeenCalledWith({
      where: { id: 'user-2' },
      data: {
        gold: { increment: 1000 },
        gems: { increment: 20 },
      },
    })
  })
})
