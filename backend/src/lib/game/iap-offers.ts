import { prisma } from '@/lib/prisma'
import { IAP_PRODUCTS, MONTHLY_GEM_CARD } from './balance'
import { getGemCardStatus, type GemCardStatus } from './gem-card'

/** Body of GET /api/iap/offers. */
export interface IapOffers {
  /** False once the account has bought the one-time Starter Bundle. */
  starterBundleAvailable: boolean
  /** Monthly Gem Card terms (from balance.ts) plus this account's card. */
  gemCard: GemCardStatus & {
    instantGems: number
    dailyGems: number
    days: number
  }
}

/**
 * Whether the account has a receipt for this SKU. Any status counts: a
 * refunded one-time offer stays used, or buy → refund → buy would repeat it.
 */
export async function hasPurchased(userId: string, productId: string): Promise<boolean> {
  const row = await prisma.iapTransaction.findFirst({
    where: { userId, productId },
    select: { id: true },
  })
  return row !== null
}

export async function getIapOffers(userId: string, now: Date = new Date()): Promise<IapOffers> {
  const starter = IAP_PRODUCTS.starter_bundle
  const [starterBought, gemCard] = await Promise.all([
    starter?.oneTime ? hasPurchased(userId, 'starter_bundle') : Promise.resolve(false),
    getGemCardStatus(userId, now),
  ])

  return {
    starterBundleAvailable: starter !== undefined && starter.enabled !== false && !starterBought,
    gemCard: {
      instantGems: IAP_PRODUCTS.monthly_gem_card?.gems ?? MONTHLY_GEM_CARD.INSTANT_GEMS,
      dailyGems: MONTHLY_GEM_CARD.DAILY_GEMS,
      days: MONTHLY_GEM_CARD.DAYS,
      ...gemCard,
    },
  }
}
