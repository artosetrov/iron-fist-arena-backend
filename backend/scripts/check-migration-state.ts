/**
 * One-off: inspect prod schema state to determine which migrations are already applied.
 * Read-only — no mutations. Run with: `npx tsx scripts/check-migration-state.ts`.
 */
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function columnExists(table: string, column: string): Promise<boolean> {
  const rows = await prisma.$queryRawUnsafe<Array<{ exists: boolean }>>(
    `SELECT EXISTS (
       SELECT 1 FROM information_schema.columns
       WHERE table_schema='public' AND table_name=$1 AND column_name=$2
     ) AS exists`,
    table, column
  )
  return rows[0]?.exists === true
}

async function tableExists(table: string): Promise<boolean> {
  const rows = await prisma.$queryRawUnsafe<Array<{ exists: boolean }>>(
    `SELECT EXISTS (
       SELECT 1 FROM information_schema.tables
       WHERE table_schema='public' AND table_name=$1
     ) AS exists`,
    table
  )
  return rows[0]?.exists === true
}

async function enumHasValue(enumName: string, value: string): Promise<boolean> {
  const rows = await prisma.$queryRawUnsafe<Array<{ exists: boolean }>>(
    `SELECT EXISTS (
       SELECT 1 FROM pg_type t JOIN pg_enum e ON e.enumtypid = t.oid
       WHERE t.typname = $1 AND e.enumlabel = $2
     ) AS exists`,
    enumName, value
  )
  return rows[0]?.exists === true
}

async function main() {
  const checks = {
    // 20260410_add_daily_activity_caps
    'characters.dungeon_clears_today': await columnExists('characters', 'dungeon_clears_today'),
    // 20260410_add_tutorial_completed
    'characters.tutorial_completed': await columnExists('characters', 'tutorial_completed'),
    // 20260410_w3d5_tiers_weekly_premium
    'weekly_challenge_progress': await tableExists('weekly_challenge_progress'),
    'characters.active_title': await columnExists('characters', 'active_title'),
    'users.premium_gem_claim_date': await columnExists('users', 'premium_gem_claim_date'),
    // 20260411_add_loot_relevance
    'characters.trash_loot_streak': await columnExists('characters', 'trash_loot_streak'),
    // 20260412_add_contraband_claims
    'contraband_claims': await tableExists('contraband_claims'),
    // 20260412_add_stash_items
    'stash_items': await tableExists('stash_items'),
    // 20260413_active_slot_infrastructure
    'character_active_slots': await tableExists('character_active_slots'),
    'passive_nodes.is_activatable': await columnExists('passive_nodes', 'is_activatable'),
    // 20260413_fix_schema_drift
    'consumable_inventory.created_at': await columnExists('consumable_inventory', 'created_at'),
    'push_campaigns': await tableExists('push_campaigns'),
    // 20260413_interactive_actives_snapshot
    'pvp_matches.interactive_actives': await columnExists('pvp_matches', 'interactive_actives'),
    // 20260413_interactive_combat_v1
    'pvp_matches.interactive_strike_index': await columnExists('pvp_matches', 'interactive_strike_index'),
    'pvp_matches.status': await columnExists('pvp_matches', 'status'),
    // 20260414_active_slot_consumables
    'character_active_slots.consumable_type': await columnExists('character_active_slots', 'consumable_type'),
    // 20260414_consumable_type_extras
    'ConsumableType.protection_scroll': await enumHasValue('ConsumableType', 'protection_scroll'),
    // 20260414_premium_subscription
    'premium_subscriptions': await tableExists('premium_subscriptions'),
    // 20260414_stamina_cap_180 — check default
    // (default is not directly queryable simply; spot-check via sample row)
    // 20260415_add_missing_event_type_values
    'EventType.double_xp': await enumHasValue('EventType', 'double_xp'),
    // 20260415_add_referral_reward_claims
    'referral_reward_claims': await tableExists('referral_reward_claims'),
    // 20260418 (my new migration) — should NOT exist yet
    'pvp_matches.opponent_type': await columnExists('pvp_matches', 'opponent_type'),
  }

  const output = Object.entries(checks)
    .map(([k, v]) => `${v ? '✅' : '❌'}  ${k}`)
    .join('\n')
  console.log(output)

  await prisma.$disconnect()
}

main().catch((e) => {
  console.error(e)
  process.exit(1)
})
