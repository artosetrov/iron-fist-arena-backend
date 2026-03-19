'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

type CreateFlagInput = {
  key: string
  title: string
  description?: string
  flagType?: string   // boolean | percentage | segment | json
  value?: any
  targeting?: any
  isActive?: boolean
  environment?: string
  tags?: string[]
}

type UpdateFlagInput = Partial<Omit<CreateFlagInput, 'key'>> & { isActive?: boolean }

// ---------------------------------------------------------------------------
// CRUD
// ---------------------------------------------------------------------------

export async function listFeatureFlags() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const flags = await prisma.featureFlag.findMany({
    orderBy: [{ isActive: 'desc' }, { key: 'asc' }],
  })

  return flags
}

export async function getFeatureFlag(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  return prisma.featureFlag.findUnique({ where: { id } })
}

export async function createFeatureFlag(data: CreateFlagInput) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  if (!data.key || !data.title) throw new Error('key and title are required')

  // Normalize key to snake_case
  const key = data.key.toLowerCase().replace(/[^a-z0-9_]/g, '_').replace(/_+/g, '_')

  const existing = await prisma.featureFlag.findUnique({ where: { key } })
  if (existing) throw new Error(`Flag "${key}" already exists`)

  const flag = await prisma.featureFlag.create({
    data: {
      key,
      title: data.title,
      description: data.description ?? null,
      flagType: data.flagType ?? 'boolean',
      value: data.value ?? true,
      targeting: data.targeting ?? null,
      isActive: data.isActive ?? false,
      environment: data.environment ?? 'all',
      tags: data.tags ?? [],
      createdBy: admin.id,
    },
  })

  await logAction(admin.id, 'feature_flag.create', flag.key, { flagType: flag.flagType })

  return flag
}

export async function updateFeatureFlag(id: string, data: UpdateFlagInput) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const flag = await prisma.featureFlag.update({
    where: { id },
    data: {
      ...(data.title !== undefined && { title: data.title }),
      ...(data.description !== undefined && { description: data.description }),
      ...(data.flagType !== undefined && { flagType: data.flagType }),
      ...(data.value !== undefined && { value: data.value }),
      ...(data.targeting !== undefined && { targeting: data.targeting }),
      ...(data.isActive !== undefined && { isActive: data.isActive }),
      ...(data.environment !== undefined && { environment: data.environment }),
      ...(data.tags !== undefined && { tags: data.tags }),
    },
  })

  await logAction(admin.id, 'feature_flag.update', flag.key, { isActive: flag.isActive })

  return flag
}

export async function toggleFeatureFlag(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const current = await prisma.featureFlag.findUnique({ where: { id } })
  if (!current) throw new Error('Flag not found')

  const flag = await prisma.featureFlag.update({
    where: { id },
    data: { isActive: !current.isActive },
  })

  await logAction(admin.id, 'feature_flag.toggle', flag.key, {
    from: current.isActive,
    to: flag.isActive,
  })

  return flag
}

export async function deleteFeatureFlag(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const flag = await prisma.featureFlag.delete({ where: { id } })

  await logAction(admin.id, 'feature_flag.delete', flag.key)

  return flag
}

// ---------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------

export async function getFeatureFlagStats() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const [total, active, booleanCount, percentageCount] = await Promise.all([
    prisma.featureFlag.count(),
    prisma.featureFlag.count({ where: { isActive: true } }),
    prisma.featureFlag.count({ where: { flagType: 'boolean' } }),
    prisma.featureFlag.count({ where: { flagType: 'percentage' } }),
  ])

  return { total, active, inactive: total - active, booleanCount, percentageCount }
}

// ---------------------------------------------------------------------------
// Seed common flags
// ---------------------------------------------------------------------------

export async function seedDefaultFlags() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const defaults = [
    { key: 'maintenance_mode', title: 'Maintenance Mode', description: 'Show maintenance screen to all players', flagType: 'boolean', value: false },
    { key: 'pvp_enabled', title: 'PvP Enabled', description: 'Kill switch for PvP matchmaking', flagType: 'boolean', value: true, isActive: true },
    { key: 'dungeon_rush_enabled', title: 'Dungeon Rush Enabled', description: 'Enable/disable dungeon rush mode', flagType: 'boolean', value: true, isActive: true },
    { key: 'new_combat_ui', title: 'New Combat UI', description: 'Rollout of redesigned combat screen', flagType: 'percentage', value: 0 },
    { key: 'double_xp_event', title: 'Double XP Event', description: 'Temporarily double all XP gains', flagType: 'boolean', value: false },
    { key: 'shell_game_enabled', title: 'Shell Game Enabled', description: 'Enable/disable shell game minigame', flagType: 'boolean', value: true, isActive: true },
    { key: 'gold_mine_enabled', title: 'Gold Mine Enabled', description: 'Enable/disable gold mine', flagType: 'boolean', value: true, isActive: true },
    { key: 'iap_enabled', title: 'IAP Enabled', description: 'Kill switch for in-app purchases', flagType: 'boolean', value: true, isActive: true },
    { key: 'force_update', title: 'Force Update', description: 'Force users to update to latest app version', flagType: 'json', value: { minVersion: '1.0.0', message: 'Please update to continue playing' } },
    { key: 'new_loot_table', title: 'New Loot Table (A/B)', description: 'A/B test: new drop chances', flagType: 'percentage', value: 50 },
  ]

  let created = 0
  let skipped = 0
  for (const d of defaults) {
    const exists = await prisma.featureFlag.findUnique({ where: { key: d.key } })
    if (exists) { skipped++; continue }
    await prisma.featureFlag.create({
      data: {
        key: d.key,
        title: d.title,
        description: d.description ?? null,
        flagType: d.flagType ?? 'boolean',
        value: d.value ?? true,
        isActive: d.isActive ?? false,
        environment: 'all',
        tags: [],
        createdBy: admin.id,
      },
    })
    created++
  }

  return { created, skipped, total: defaults.length }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function logAction(adminId: string, action: string, target?: string, details?: any) {
  try {
    await prisma.adminLog.create({
      data: { adminId: adminId, action, target, details },
    })
  } catch {
    console.error('[audit] failed to log:', action, target)
  }
}
