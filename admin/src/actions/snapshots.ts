'use server'

import type { Prisma } from '@prisma/client'
import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'
import { callBackendAdminJson } from '@/lib/backend-admin'

type SnapshotConfigEntry = {
  key: string
  value: Prisma.JsonValue
  category: string
  description: string | null
}

type SnapshotListItem = {
  id: string
  name: string
  description: string | null
  createdBy: string
  createdAt: Date
  configs: Prisma.JsonValue
}

/** Take a snapshot of the current config state */
export async function createConfigSnapshot(name: string, description?: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  // Read all current configs
  const allConfigs = await prisma.gameConfig.findMany()
  const configData = allConfigs.map(c => ({
    key: c.key,
    value: c.value,
    category: c.category,
    description: c.description,
  }))

  return prisma.$transaction(async (tx) => {
    const snapshot = await tx.configSnapshot.create({
      data: {
        name,
        description,
        configs: configData as never,
        createdBy: admin.id,
      },
    })

    await tx.adminLog.create({
      data: {
        adminId: admin.id,
        action: 'create_config_snapshot',
        target: snapshot.id,
        details: { name, configCount: configData.length } as never,
      },
    })

    return snapshot
  })
}

/** List all snapshots, newest first */
export async function listConfigSnapshots(): Promise<SnapshotListItem[]> {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  return prisma.configSnapshot.findMany({
    select: {
      id: true,
      name: true,
      description: true,
      createdBy: true,
      createdAt: true,
      configs: true,
    },
    orderBy: { createdAt: 'desc' },
    take: 50,
  })
}

/** Rollback to a specific snapshot — replaces all current configs */
export async function rollbackToSnapshot(snapshotId: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const snapshot = await prisma.configSnapshot.findUnique({ where: { id: snapshotId } })
  if (!snapshot) throw new Error('Snapshot not found')

  const configData = Array.isArray(snapshot.configs) ? (snapshot.configs as SnapshotConfigEntry[]) : null
  if (!configData || !configData.every((config) => config && typeof config.key === 'string' && typeof config.category === 'string')) {
    throw new Error('Snapshot payload is invalid')
  }

  return callBackendAdminJson<{
    success: true
    restoredCount: number
    backupCreated: boolean
    backupId: string | null
  }>('/api/admin/config/restore', {
    method: 'POST',
    body: JSON.stringify({
      snapshotId,
      snapshotName: snapshot.name,
      configs: configData,
      createBackup: true,
    }),
  })
}

/** Delete a snapshot */
export async function deleteConfigSnapshot(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  await prisma.$transaction(async (tx) => {
    await tx.configSnapshot.delete({ where: { id } })

    await tx.adminLog.create({
      data: {
        adminId: admin.id,
        action: 'delete_config_snapshot',
        target: id,
      },
    })
  })

  return { success: true }
}
