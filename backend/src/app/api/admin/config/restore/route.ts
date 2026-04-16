import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'
import { invalidateGameConfigCache } from '@/lib/game/config'

type SnapshotConfigEntry = {
  key: string
  value: unknown
  category: string
  description: string | null
}

function isSnapshotConfigEntry(value: unknown): value is SnapshotConfigEntry {
  if (!value || typeof value !== 'object') return false

  const maybe = value as Partial<SnapshotConfigEntry>
  return (
    typeof maybe.key === 'string' &&
    maybe.key.length > 0 &&
    typeof maybe.category === 'string' &&
    ('description' in maybe ? maybe.description === null || typeof maybe.description === 'string' : true) &&
    'value' in maybe
  )
}

export async function POST(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  try {
    const body = await req.json()
    const snapshotName =
      typeof body?.snapshotName === 'string' && body.snapshotName.trim().length > 0
        ? body.snapshotName.trim()
        : 'unnamed snapshot'
    const snapshotId =
      typeof body?.snapshotId === 'string' && body.snapshotId.trim().length > 0
        ? body.snapshotId.trim()
        : null
    const createBackup = body?.createBackup !== false
    const configs = Array.isArray(body?.configs) ? body.configs : null

    if (!configs || configs.length === 0 || !configs.every(isSnapshotConfigEntry)) {
      return NextResponse.json({ error: 'configs[] with key, value, category, and description is required' }, { status: 400 })
    }

    const parsedConfigs = configs as SnapshotConfigEntry[]
    const uniqueKeys = new Set(parsedConfigs.map((config) => config.key))
    if (uniqueKeys.size !== parsedConfigs.length) {
      return NextResponse.json({ error: 'configs[] contains duplicate keys' }, { status: 400 })
    }

    const previousConfigs = await prisma.gameConfig.findMany({
      select: { key: true },
    })

    const result = await prisma.$transaction(async (tx) => {
      const currentConfigs = await tx.gameConfig.findMany()
      let backupId: string | null = null

      if (createBackup) {
        const backup = await tx.configSnapshot.create({
          data: {
            name: `Auto-backup before rollback to "${snapshotName}"`,
            description: snapshotId
              ? `Automatic backup created before rolling back to snapshot ${snapshotId}`
              : `Automatic backup created before config restore to "${snapshotName}"`,
            configs: currentConfigs.map((config) => ({
              key: config.key,
              value: config.value,
              category: config.category,
              description: config.description,
            })) as never,
            createdBy: admin.id,
          },
        })
        backupId = backup.id
      }

      await tx.gameConfig.deleteMany()

      for (const config of parsedConfigs) {
        await tx.gameConfig.create({
          data: {
            key: config.key,
            value: config.value as never,
            category: config.category,
            description: config.description,
            updatedBy: admin.id,
          },
        })
      }

      await tx.adminLog.create({
        data: {
          adminId: admin.id,
          action: 'restore_config_snapshot',
          target: snapshotId ?? snapshotName,
          details: {
            snapshotId,
            snapshotName,
            restoredCount: parsedConfigs.length,
            backupId,
          } as never,
        },
      })

      return {
        backupId,
        restoredCount: parsedConfigs.length,
      }
    })

    const invalidatedKeys = [
      ...new Set([...previousConfigs.map((config) => config.key), ...parsedConfigs.map((config) => config.key)]),
    ]
    await invalidateGameConfigCache(invalidatedKeys)

    return NextResponse.json({
      success: true,
      restoredCount: result.restoredCount,
      backupCreated: createBackup,
      backupId: result.backupId,
    })
  } catch (error) {
    console.error('admin restore config error:', error)
    return NextResponse.json({ error: 'Failed to restore config snapshot' }, { status: 500 })
  }
}
