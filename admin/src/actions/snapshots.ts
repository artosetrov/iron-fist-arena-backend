'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'

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

  const snapshot = await prisma.configSnapshot.create({
    data: {
      name,
      description,
      configs: configData as never,
      createdBy: admin.id,
    },
  })

  await prisma.adminLog.create({
    data: {
      adminId: admin.id,
      action: 'create_config_snapshot',
      target: snapshot.id,
      details: { name, configCount: configData.length } as never,
    },
  })

  return snapshot
}

/** List all snapshots, newest first */
export async function listConfigSnapshots() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  return prisma.configSnapshot.findMany({
    orderBy: { createdAt: 'desc' },
    take: 50,
  })
}

/** Get a single snapshot with full config data */
export async function getConfigSnapshot(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  return prisma.configSnapshot.findUnique({ where: { id } })
}

/** Rollback to a specific snapshot — replaces all current configs */
export async function rollbackToSnapshot(snapshotId: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const snapshot = await prisma.configSnapshot.findUnique({ where: { id: snapshotId } })
  if (!snapshot) throw new Error('Snapshot not found')

  const configData = snapshot.configs as Array<{
    key: string
    value: unknown
    category: string
    description: string | null
  }>

  // Auto-save current state before rollback
  const currentConfigs = await prisma.gameConfig.findMany()
  await prisma.configSnapshot.create({
    data: {
      name: `Auto-backup before rollback to "${snapshot.name}"`,
      description: `Automatic backup created before rolling back to snapshot ${snapshotId}`,
      configs: currentConfigs.map(c => ({
        key: c.key,
        value: c.value,
        category: c.category,
        description: c.description,
      })) as never,
      createdBy: admin.id,
    },
  })

  // Delete all current configs and replace with snapshot
  await prisma.gameConfig.deleteMany()

  for (const config of configData) {
    await prisma.gameConfig.create({
      data: {
        key: config.key,
        value: config.value as never,
        category: config.category,
        description: config.description,
        updatedBy: admin.id,
      },
    })
  }

  await prisma.adminLog.create({
    data: {
      adminId: admin.id,
      action: 'rollback_config',
      target: snapshotId,
      details: {
        snapshotName: snapshot.name,
        configCount: configData.length,
      } as never,
    },
  })

  return { success: true, restoredCount: configData.length }
}

/** Delete a snapshot */
export async function deleteConfigSnapshot(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  await prisma.configSnapshot.delete({ where: { id } })

  await prisma.adminLog.create({
    data: {
      adminId: admin.id,
      action: 'delete_config_snapshot',
      target: id,
    },
  })

  return { success: true }
}
