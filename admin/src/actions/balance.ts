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

export type BalanceSaveResult = { updated: number } | { error: string }

/** Back up every config row, returning the snapshot id (null when there is nothing to back up). */
async function snapshotCurrentConfigs(adminId: string, name: string): Promise<string | null> {
  const allConfigs = await prisma.gameConfig.findMany()
  if (allConfigs.length === 0) return null

  const snapshot = await prisma.configSnapshot.create({
    data: {
      name,
      configs: allConfigs.map((c) => ({
        key: c.key,
        value: c.value,
        category: c.category,
        description: c.description,
      })) as never,
      createdBy: adminId,
    },
  })

  return snapshot.id
}

async function discardSnapshot(id: string | null): Promise<void> {
  if (!id) return
  await prisma.configSnapshot.delete({ where: { id } }).catch(() => undefined)
}

/**
 * A rejected save has to explain itself.
 *
 * The backend refuses some saves outright — a `pvp_ranks.*` set that would not
 * form a ladder, for one — and answers 400 with the reason.
 * `callBackendAdminJson` turns that into a thrown Error, and Next.js replaces
 * the message of anything thrown out of a server action in a production build
 * with an opaque digest. So the reason is RETURNED as data instead: an operator
 * who moved a tier floor needs to read which floor and why, not "an error
 * occurred in the Server Components render".
 */
export async function batchUpdateBalanceConfigs(
  updates: { key: string; value: unknown }[],
): Promise<BalanceSaveResult> {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  // Snapshot first — the backup has to exist before anything is written, not
  // after — and discard it if the write is refused, so a rejected save does not
  // leave an "Auto-backup before balance update" behind for a change that never
  // happened.
  const snapshotId = await snapshotCurrentConfigs(
    admin.id,
    `Auto-backup before balance update (${updates.length} changes)`,
  )

  let response: { updated?: number; configs?: unknown[]; total?: number }
  try {
    response = await callBackendAdminJson<{ updated?: number; configs?: unknown[]; total?: number }>(
      '/api/admin/config',
      {
        method: 'POST',
        body: JSON.stringify({ updates }),
      },
    )
  } catch (error) {
    await discardSnapshot(snapshotId)
    return { error: error instanceof Error ? error.message : 'Failed to save balance values' }
  }

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

export async function resetBalanceToDefaults(
  keys: string[],
): Promise<{ deleted: number } | { error: string }> {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  await snapshotCurrentConfigs(admin.id, `Auto-backup before reset (${keys.length} configs)`)

  // Sequential, not Promise.all: the backend refuses a delete that would leave
  // the remaining tier floors out of order, and a parallel batch would have
  // applied some of the deletes before the refusal.
  try {
    for (const key of keys) {
      await callBackendAdminJson<{ success: true }>(
        `/api/admin/config?key=${encodeURIComponent(key)}`,
        { method: 'DELETE' },
      )
    }
  } catch (error) {
    // Deletes already applied stay applied — the snapshot is kept so the
    // partial reset can be rolled back.
    return { error: error instanceof Error ? error.message : 'Failed to reset balance values' }
  }

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
