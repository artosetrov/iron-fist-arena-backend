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

export async function updateBalanceConfig(key: string, value: unknown, adminId: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  if (!key.startsWith('item_balance.')) {
    throw new Error('key must start with item_balance.')
  }

  const config = await prisma.gameConfig.upsert({
    where: { key },
    update: { value: value as never, updatedBy: adminId },
    create: {
      key,
      value: value as never,
      category: 'item_balance',
      updatedBy: adminId,
    },
  })

  await prisma.adminLog.create({
    data: {
      adminId,
      action: 'update_balance_config',
      details: { key, value } as never,
    },
  })

  return config
}

export async function getBalanceProfiles() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.itemBalanceProfile.findMany({
    orderBy: { itemType: 'asc' },
  })
}

export async function updateBalanceProfile(
  itemType: string,
  statWeights: Record<string, number>,
  powerWeight: number,
  adminId: string,
  description?: string,
) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const profile = await prisma.itemBalanceProfile.upsert({
    where: { itemType: itemType as never },
    update: {
      statWeights: statWeights as never,
      powerWeight,
      description: description ?? null,
      updatedBy: adminId,
    },
    create: {
      itemType: itemType as never,
      statWeights: statWeights as never,
      powerWeight,
      description: description ?? null,
      updatedBy: adminId,
    },
  })

  await prisma.adminLog.create({
    data: {
      adminId,
      action: 'update_balance_profile',
      details: { itemType, statWeights, powerWeight } as never,
    },
  })

  return profile
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
