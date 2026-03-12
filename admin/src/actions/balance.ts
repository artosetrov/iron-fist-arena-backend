'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'

export async function getBalanceConfigs() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const balanceCategories = [
    'stamina', 'gold_rewards', 'xp_rewards', 'first_win_bonus',
    'drop_chances', 'rarity_distribution', 'elo', 'combat',
    'win_streak', 'matchmaking', 'prestige', 'upgrade',
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
  adminId: string
) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const results = []

  for (const { key, value } of updates) {
    // Determine category from key prefix
    const dotIdx = key.indexOf('.')
    const category = dotIdx > 0 ? key.substring(0, dotIdx) : 'general'

    const config = await prisma.gameConfig.upsert({
      where: { key },
      update: {
        value: value as never,
        updatedBy: adminId,
      },
      create: {
        key,
        value: value as never,
        category,
        updatedBy: adminId,
      },
    })
    results.push(config)
  }

  // Single audit log for the batch
  await prisma.adminLog.create({
    data: {
      adminId,
      action: 'batch_update_balance',
      target: `${updates.length} configs`,
      details: {
        keys: updates.map((u) => u.key),
        values: Object.fromEntries(updates.map((u) => [u.key, u.value])),
      } as never,
    },
  })

  return { updated: results.length }
}

export async function resetBalanceToDefaults(keys: string[], adminId: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  // Delete the specified keys so they revert to code defaults
  await prisma.gameConfig.deleteMany({
    where: { key: { in: keys } },
  })

  await prisma.adminLog.create({
    data: {
      adminId,
      action: 'reset_balance_defaults',
      target: `${keys.length} configs`,
      details: { keys } as never,
    },
  })

  return { deleted: keys.length }
}
