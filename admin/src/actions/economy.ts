'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'

// ---------------------------------------------------------------------------
// Core Aggregates
// ---------------------------------------------------------------------------

export async function getEconomySummary() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const [
    totalChars,
    totalUsers,
    goldAgg,
    gemsAgg,
    iapAgg,
    offerPurchaseAgg,
  ] = await Promise.all([
    prisma.character.count(),
    prisma.user.count(),
    prisma.character.aggregate({
      _sum: { gold: true },
      _avg: { gold: true },
      _min: { gold: true },
      _max: { gold: true },
    }),
    prisma.user.aggregate({
      _sum: { gems: true },
      _avg: { gems: true },
      _min: { gems: true },
      _max: { gems: true },
    }),
    prisma.iapTransaction.aggregate({
      where: { status: 'verified' },
      _sum: { gemsAwarded: true },
      _count: true,
    }),
    prisma.shopOfferPurchase.aggregate({
      _sum: { price: true },
      _count: true,
    }),
  ])

  return {
    totalCharacters: totalChars,
    totalUsers,
    gold: {
      total: goldAgg._sum.gold ?? 0,
      avg: Math.round(goldAgg._avg.gold ?? 0),
      min: goldAgg._min.gold ?? 0,
      max: goldAgg._max.gold ?? 0,
    },
    gems: {
      total: gemsAgg._sum.gems ?? 0,
      avg: Math.round(gemsAgg._avg.gems ?? 0),
      min: gemsAgg._min.gems ?? 0,
      max: gemsAgg._max.gems ?? 0,
    },
    iap: {
      totalGems: iapAgg._sum.gemsAwarded ?? 0,
      totalTransactions: iapAgg._count,
    },
    offers: {
      totalPurchases: offerPurchaseAgg._count,
      totalRevenue: offerPurchaseAgg._sum.price ?? 0,
    },
  }
}

// ---------------------------------------------------------------------------
// Distribution by Level
// ---------------------------------------------------------------------------

export async function getGoldByLevel() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const results = await prisma.character.groupBy({
    by: ['level'],
    _avg: { gold: true },
    _sum: { gold: true },
    _count: true,
    orderBy: { level: 'asc' },
  })

  return results.map((r) => ({
    level: r.level,
    avgGold: Math.round(r._avg.gold ?? 0),
    totalGold: r._sum.gold ?? 0,
    count: r._count,
  }))
}

// ---------------------------------------------------------------------------
// Top Holders
// ---------------------------------------------------------------------------

export async function getTopGoldHolders(limit = 15) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.character.findMany({
    orderBy: { gold: 'desc' },
    take: limit,
    select: {
      id: true, characterName: true, gold: true, level: true, class: true,
      user: { select: { id: true, username: true, email: true } },
    },
  })
}

export async function getTopGemHolders(limit = 15) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.user.findMany({
    orderBy: { gems: 'desc' },
    take: limit,
    select: {
      id: true, username: true, email: true, gems: true,
      characters: {
        take: 1,
        orderBy: { level: 'desc' },
        select: { characterName: true, level: true },
      },
    },
  })
}

// ---------------------------------------------------------------------------
// IAP Analytics
// ---------------------------------------------------------------------------

export async function getIapByProduct() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const results = await prisma.iapTransaction.groupBy({
    by: ['productId'],
    where: { status: 'verified' },
    _count: true,
    _sum: { gemsAwarded: true },
    orderBy: { _count: { productId: 'desc' } },
  })

  return results.map((r) => ({
    productId: r.productId,
    count: r._count,
    totalGems: r._sum.gemsAwarded ?? 0,
  }))
}

export async function getRecentTransactions(limit = 30) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.iapTransaction.findMany({
    orderBy: { createdAt: 'desc' },
    take: limit,
    select: {
      id: true, productId: true, transactionId: true,
      gemsAwarded: true, status: true, createdAt: true,
      user: { select: { id: true, username: true, email: true } },
    },
  })
}

// ---------------------------------------------------------------------------
// Offer Purchase Analytics
// ---------------------------------------------------------------------------

export async function getOfferPurchasesByOffer() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const results = await prisma.shopOfferPurchase.groupBy({
    by: ['offerId'],
    _count: true,
    _sum: { price: true },
    orderBy: { _count: { offerId: 'desc' } },
  })

  // Enrich with offer names
  const offerIds = results.map((r) => r.offerId)
  const offers = await prisma.shopOffer.findMany({
    where: { id: { in: offerIds } },
    select: { id: true, title: true, key: true, currency: true },
  })
  const offerMap = Object.fromEntries(offers.map((o) => [o.id, o]))

  return results.map((r) => ({
    offerId: r.offerId,
    title: offerMap[r.offerId]?.title ?? 'Deleted',
    key: offerMap[r.offerId]?.key ?? '?',
    currency: offerMap[r.offerId]?.currency ?? 'gold',
    count: r._count,
    totalRevenue: r._sum.price ?? 0,
  }))
}

// ---------------------------------------------------------------------------
// Wealth Distribution (Gini-like buckets)
// ---------------------------------------------------------------------------

export async function getWealthDistribution() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  // Get all characters' gold sorted
  const chars = await prisma.character.findMany({
    select: { gold: true },
    orderBy: { gold: 'asc' },
  })

  if (chars.length === 0) return { buckets: [], giniCoefficient: 0 }

  const golds = chars.map((c) => c.gold)
  const total = golds.reduce((a, b) => a + b, 0)
  const n = golds.length

  // Gini coefficient calculation
  let sumDiffs = 0
  for (let i = 0; i < n; i++) {
    for (let j = 0; j < n; j++) {
      sumDiffs += Math.abs(golds[i] - golds[j])
    }
  }
  const gini = total > 0 ? sumDiffs / (2 * n * total) : 0

  // Bucket into percentile groups
  const bucketCount = 10
  const bucketSize = Math.ceil(n / bucketCount)
  const buckets = []
  for (let i = 0; i < bucketCount; i++) {
    const start = i * bucketSize
    const end = Math.min(start + bucketSize, n)
    const slice = golds.slice(start, end)
    const bucketTotal = slice.reduce((a, b) => a + b, 0)
    buckets.push({
      label: `${Math.round((start / n) * 100)}–${Math.round((end / n) * 100)}%`,
      playerCount: slice.length,
      totalGold: bucketTotal,
      avgGold: slice.length > 0 ? Math.round(bucketTotal / slice.length) : 0,
      pctOfTotal: total > 0 ? Math.round((bucketTotal / total) * 1000) / 10 : 0,
    })
  }

  return {
    buckets,
    giniCoefficient: Math.round(gini * 1000) / 1000,
  }
}

// ---------------------------------------------------------------------------
// Class Distribution (economy per class)
// ---------------------------------------------------------------------------

export async function getEconomyByClass() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const results = await prisma.character.groupBy({
    by: ['class'],
    _avg: { gold: true, level: true },
    _sum: { gold: true },
    _count: true,
    orderBy: { _count: { class: 'desc' } },
  })

  return results.map((r) => ({
    class: r.class,
    count: r._count,
    avgGold: Math.round(r._avg.gold ?? 0),
    totalGold: r._sum.gold ?? 0,
    avgLevel: Math.round((r._avg.level ?? 0) * 10) / 10,
  }))
}
