'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'
import { callBackendAdminJson } from '@/lib/backend-admin'

export async function getBalanceConfigs() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const balanceCategories = [
    'stamina', 'gold_rewards', 'xp_rewards', 'first_win_bonus',
    'drop_chances', 'rarity_distribution', 'elo', 'pvp_ranks', 'combat',
    'win_streak', 'loss_streak', 'matchmaking', 'prestige', 'upgrade',
    'training_xp_dr', 'stamina_refill_dr', 'charisma', 'repair',
    'battle_pass', 'hp_regen', 'skills', 'passives',
    'gem_costs', 'inventory',
  ]

  return prisma.gameConfig.findMany({
    where: { category: { in: balanceCategories } },
    orderBy: [{ category: 'asc' }, { key: 'asc' }],
  })
}

export async function batchUpdateBalanceConfigs(
  updates: { key: string; value: unknown }[],
) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  // Auto-snapshot before batch update
  const allConfigs = await prisma.gameConfig.findMany()
  if (allConfigs.length > 0) {
    await prisma.configSnapshot.create({
      data: {
        name: `Auto-backup before balance update (${updates.length} changes)`,
        configs: allConfigs.map(c => ({
          key: c.key,
          value: c.value,
          category: c.category,
          description: c.description,
        })) as never,
        createdBy: admin.id,
      },
    })
  }

  const response = await callBackendAdminJson<{ updated?: number; configs?: unknown[]; total?: number }>(
    '/api/admin/config',
    {
      method: 'POST',
      body: JSON.stringify({ updates }),
    },
  )

  // Single audit log for the batch
  await prisma.adminLog.create({
    data: {
      adminId: admin.id,
      action: 'batch_update_balance',
      target: `${updates.length} configs`,
      details: {
        keys: updates.map((u) => u.key),
        values: Object.fromEntries(updates.map((u) => [u.key, u.value])),
      } as never,
    },
  })

  return { updated: response.updated ?? response.configs?.length ?? response.total ?? updates.length }
}

export async function resetBalanceToDefaults(keys: string[]) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  // Auto-snapshot before reset
  const allConfigs = await prisma.gameConfig.findMany()
  if (allConfigs.length > 0) {
    await prisma.configSnapshot.create({
      data: {
        name: `Auto-backup before reset (${keys.length} configs)`,
        configs: allConfigs.map(c => ({
          key: c.key,
          value: c.value,
          category: c.category,
          description: c.description,
        })) as never,
        createdBy: admin.id,
      },
    })
  }

  await Promise.all(
    keys.map((key) =>
      callBackendAdminJson<{ success: true }>(`/api/admin/config?key=${encodeURIComponent(key)}`, {
        method: 'DELETE',
      })
    )
  )

  await prisma.adminLog.create({
    data: {
      adminId: admin.id,
      action: 'reset_balance_defaults',
      target: `${keys.length} configs`,
      details: { keys } as never,
    },
  })

  return { deleted: keys.length }
}
