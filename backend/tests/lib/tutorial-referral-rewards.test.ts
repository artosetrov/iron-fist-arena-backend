import { beforeEach, describe, expect, it, vi } from 'vitest'

const { mockLogTutorialEvent } = vi.hoisted(() => ({
  mockLogTutorialEvent: vi.fn(),
}))

vi.mock('../../src/lib/game/tutorial-analytics', () => ({
  logTutorialEvent: mockLogTutorialEvent,
}))

import { awardReferralQualificationIfEligible } from '../../src/lib/game/tutorial'

describe('tutorial referral qualification rewards', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('awards the referrer once when the invitee reaches the qualification level', async () => {
    const tx = {
      character: {
        findUnique: vi.fn(async () => ({ referredBy: 'referrer-1' })),
        findFirst: vi.fn(async () => ({
          id: 'referrer-1',
          userId: 'user-2',
          referralCode: 'FRIEND88',
        })),
      },
      user: {
        update: vi.fn(async () => ({})),
      },
      referralRewardClaim: {
        create: vi.fn(async () => ({})),
      },
    }

    const result = await awardReferralQualificationIfEligible(tx, 'invitee-1', 5)

    expect(tx.referralRewardClaim.create).toHaveBeenCalledWith({
      data: {
        referrerCharacterId: 'referrer-1',
        inviteeCharacterId: 'invitee-1',
      },
    })
    expect(tx.user.update).toHaveBeenCalledWith({
      where: { id: 'user-2' },
      data: {
        gold: { increment: 500 },
        gems: { increment: 10 },
      },
    })
    expect(mockLogTutorialEvent).toHaveBeenCalledWith({
      event: 'referral_qualified',
      characterId: 'invitee-1',
      referrerCharacterId: 'referrer-1',
      referrerCode: 'FRIEND88',
      qualifiedLevel: 5,
      rewardGold: 500,
      rewardGems: 10,
    })
    expect(result).toEqual({
      referrerCharacterId: 'referrer-1',
      referrerReferralCode: 'FRIEND88',
      goldAwarded: 500,
      gemsAwarded: 10,
    })
  })

  it('treats duplicate qualification claims as already processed', async () => {
    const tx = {
      character: {
        findUnique: vi.fn(async () => ({ referredBy: 'FRIEND88' })),
        findFirst: vi.fn(async () => ({
          id: 'referrer-1',
          userId: 'user-2',
          referralCode: 'FRIEND88',
        })),
      },
      user: {
        update: vi.fn(async () => ({})),
      },
      referralRewardClaim: {
        create: vi.fn(async () => {
          const error = new Error('duplicate') as Error & { code?: string }
          error.code = 'P2002'
          throw error
        }),
      },
    }

    const result = await awardReferralQualificationIfEligible(tx, 'invitee-1', 7)

    expect(result).toBeNull()
    expect(tx.user.update).not.toHaveBeenCalled()
    expect(mockLogTutorialEvent).not.toHaveBeenCalled()
  })
})
