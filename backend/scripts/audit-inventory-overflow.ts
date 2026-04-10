/**
 * Audit script: detect characters with inventory overflow.
 *
 * Background:
 *   Before CRIT-04 fix, `persistLoot()` in `lib/game/loot.ts` used a global
 *   `MAX_SLOTS` (default 100) instead of per-character `character.inventorySlots`
 *   (28-58). This allowed loot drops to exceed the player's actual slot limit,
 *   creating "ghost slots" (inventoryCount > inventorySlots).
 *
 *   This script scans all characters and reports any such overflow so we can
 *   decide on a cleanup strategy (see CRIT-04 EXPANDED in QA_FIX_PLAN_2026-04-10.md).
 *
 * Cleanup decisions:
 *   - 0 overflowed    → ship the code fix, no cleanup needed
 *   - 1-5 overflowed  → notify players in-game, let them sell/drop manually
 *   - >5 overflowed   → design automatic cleanup (bump inventorySlots, dropbox, auto-sell)
 *
 * Run: cd backend && npx tsx scripts/audit-inventory-overflow.ts
 * Read-only — never writes to DB.
 */

import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

interface OverflowRow {
  character_id: string
  character_name: string
  user_id: string
  inventory_slots: number
  inventory_count: number
  overflow: number
}

interface SummaryRow {
  total_characters: number
  overflowed: number
  total_ghost_items: number
  max_overflow: number
  max_inventory_count_any_char: number
}

async function main() {
  console.log('Scanning characters for inventory overflow...\n')

  // Single aggregated summary query — runs one pass over the DB.
  const summaryResult = await prisma.$queryRaw<SummaryRow[]>`
    WITH counts AS (
      SELECT
        c.id,
        c.inventory_slots,
        COUNT(ei.id)::int AS inventory_count
      FROM characters c
      LEFT JOIN equipment_inventory ei ON ei.character_id = c.id
      GROUP BY c.id, c.inventory_slots
    )
    SELECT
      (SELECT COUNT(*) FROM characters)::int AS total_characters,
      (SELECT COUNT(*) FROM counts WHERE inventory_count > inventory_slots)::int AS overflowed,
      (SELECT COALESCE(SUM(inventory_count - inventory_slots), 0)::int FROM counts WHERE inventory_count > inventory_slots) AS total_ghost_items,
      (SELECT COALESCE(MAX(inventory_count - inventory_slots), 0)::int FROM counts WHERE inventory_count > inventory_slots) AS max_overflow,
      (SELECT COALESCE(MAX(inventory_count), 0)::int FROM counts) AS max_inventory_count_any_char
  `
  const summary = summaryResult[0]

  console.log(`Total characters:           ${summary.total_characters}`)
  console.log(`Max inventory count (any):  ${summary.max_inventory_count_any_char}`)

  if (summary.overflowed === 0) {
    console.log('\n✓ No overflow detected. Safe to ship CRIT-04 code fix with no cleanup.')
    return
  }

  // Fetch top-20 overflowed characters with names (only if there ARE overflowed ones)
  const rows = await prisma.$queryRaw<OverflowRow[]>`
    WITH counts AS (
      SELECT
        c.id AS character_id,
        c.character_name,
        c.user_id,
        c.inventory_slots,
        COUNT(ei.id)::int AS inventory_count
      FROM characters c
      LEFT JOIN equipment_inventory ei ON ei.character_id = c.id
      GROUP BY c.id, c.character_name, c.user_id, c.inventory_slots
    )
    SELECT
      character_id,
      character_name,
      user_id,
      inventory_slots,
      inventory_count,
      (inventory_count - inventory_slots)::int AS overflow
    FROM counts
    WHERE inventory_count > inventory_slots
    ORDER BY overflow DESC
    LIMIT 20
  `

  const pctOverflowed = ((summary.overflowed / summary.total_characters) * 100).toFixed(2)

  console.log(`\n⚠ Overflow detected:`)
  console.log(`  Characters affected:  ${summary.overflowed} / ${summary.total_characters} (${pctOverflowed}%)`)
  console.log(`  Total ghost items:    ${summary.total_ghost_items}`)
  console.log(`  Max overflow:         ${summary.max_overflow} items (one character)`)

  console.log('\nTop 20 affected characters:')
  console.log('  Character                        | Slots | Count | Overflow')
  console.log('  ---------------------------------|-------|-------|---------')
  for (const row of rows) {
    const name = (row.character_name ?? '<unnamed>').padEnd(32).slice(0, 32)
    const slots = String(row.inventory_slots).padStart(5)
    const count = String(row.inventory_count).padStart(5)
    const over = String(row.overflow).padStart(8)
    console.log(`  ${name} | ${slots} | ${count} | ${over}`)
  }

  if (summary.overflowed > 20) {
    console.log(`  ... and ${summary.overflowed - 20} more`)
  }

  // Recommendation
  console.log('\nRecommendation:')
  if (summary.overflowed <= 5) {
    console.log('  ≤ 5 affected — ship code fix + in-game notification, let players resolve manually.')
  } else if (summary.overflowed <= 50) {
    console.log('  6-50 affected — consider scripted inventory expansion (bump inventorySlots to match count)')
    console.log('  or move excess items to a "recovery box" table.')
  } else {
    console.log('  > 50 affected — design batch cleanup migration before shipping CRIT-04 fix.')
    console.log('  Block release until strategy is agreed.')
  }
}

main()
  .catch((e) => {
    console.error('Error:', e)
    process.exit(1)
  })
  .finally(async () => await prisma.$disconnect())
