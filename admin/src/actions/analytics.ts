'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'

export async function getDashboardStats() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const [totalUsers] = await prisma.$queryRaw<[{ count: bigint }]>`
    SELECT COUNT(*) as count FROM users
  `
  const [totalCharacters] = await prisma.$queryRaw<[{ count: bigint }]>`
    SELECT COUNT(*) as count FROM characters
  `
  const [totalMatches] = await prisma.$queryRaw<[{ count: bigint }]>`
    SELECT COUNT(*) as count FROM pvp_matches
  `
  const [revenueResult] = await prisma.$queryRaw<[{ total: bigint | null }]>`
    SELECT COALESCE(SUM(gems_awarded), 0) as total FROM iap_transactions WHERE status = 'verified'
  `
  const [dauResult] = await prisma.$queryRaw<[{ count: bigint }]>`
    SELECT COUNT(*) as count FROM users WHERE last_login >= NOW() - INTERVAL '24 hours'
  `
  const [mauResult] = await prisma.$queryRaw<[{ count: bigint }]>`
    SELECT COUNT(*) as count FROM users WHERE last_login >= NOW() - INTERVAL '30 days'
  `

  return {
    totalUsers: Number(totalUsers.count),
    totalCharacters: Number(totalCharacters.count),
    totalMatches: Number(totalMatches.count),
    totalRevenue: Number(revenueResult.total ?? 0),
    dau: Number(dauResult.count),
    mau: Number(mauResult.count),
  }
}

export async function getRegistrationChart() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const rows = await prisma.$queryRaw<{ date: string; count: bigint }[]>`
    SELECT DATE(created_at) as date, COUNT(*) as count
    FROM users
    WHERE created_at >= NOW() - INTERVAL '30 days'
    GROUP BY DATE(created_at)
    ORDER BY date ASC
  `
  return rows.map(r => ({ date: String(r.date), count: Number(r.count) }))
}

export async function getPvpChart() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const rows = await prisma.$queryRaw<{ date: string; count: bigint }[]>`
    SELECT DATE(played_at) as date, COUNT(*) as count
    FROM pvp_matches
    WHERE played_at >= NOW() - INTERVAL '30 days'
    GROUP BY DATE(played_at)
    ORDER BY date ASC
  `
  return rows.map(r => ({ date: String(r.date), count: Number(r.count) }))
}

export async function getClassDistribution() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const rows = await prisma.$queryRaw<{ class: string; count: bigint }[]>`
    SELECT class, COUNT(*) as count
    FROM characters
    GROUP BY class
    ORDER BY count DESC
  `
  return rows.map(r => ({ class: r.class, count: Number(r.count) }))
}

export async function getTopPlayers() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const rows = await prisma.$queryRaw<{
    character_name: string
    class: string
    level: number
    pvp_rating: number
    pvp_wins: number
  }[]>`
    SELECT character_name, class, level, pvp_rating, pvp_wins
    FROM characters
    ORDER BY pvp_rating DESC
    LIMIT 10
  `
  return rows
}
