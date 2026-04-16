'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'

export async function getBalanceConfigs() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.gameConfig.findMany({
    where: { category: 'item_balance' },
    orderBy: { key: 'asc' },
  })
}

export async function getBalanceProfiles() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.itemBalanceProfile.findMany({
    orderBy: { itemType: 'asc' },
  })
}

export async function getSimulationHistory(runType?: string, limit = 20) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const where = runType ? { runType } : {}
  return prisma.balanceSimulationRun.findMany({
    where,
    orderBy: { createdAt: 'desc' },
    take: limit,
  })
}

export async function getBalanceSummary() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const [totalItems, configs, lastSim, profiles] = await Promise.all([
    prisma.item.count({ where: { itemType: { not: 'consumable' } } }),
    prisma.gameConfig.count({ where: { category: 'item_balance' } }),
    prisma.balanceSimulationRun.findFirst({ orderBy: { createdAt: 'desc' } }),
    prisma.itemBalanceProfile.count(),
  ])

  return {
    totalItems,
    totalConfigs: configs,
    totalProfiles: profiles,
    lastSimDate: lastSim?.createdAt ?? null,
    lastSimType: lastSim?.runType ?? null,
    lastSimSummary: lastSim?.summary ?? null,
  }
}
