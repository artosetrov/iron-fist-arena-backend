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
  characterId: string
  characterName: string
  userId: string
  inventorySlots: number
  inventoryCount: number
  overflow: number
}

async function main() {
  console.log('Scanning characters for inventory overflow...\n')

  const characters = await prisma.character.findMany({
    select: {
      id: true,
      name: true,
      userId: true,
      inventorySlots: true,
      _count: { select: { equipmentInventory: true } },
    },
  })

  const total = characters.length
  console.log(`Total characters: ${total}`)

  const overflowed: OverflowRow[] = []
  for (const c of characters) {
    const count = c._count.equipmentInventory
    if (count > c.inventorySlots) {
      overflowed.push({
        characterId: c.id,
        characterName: c.name,
        userId: c.userId,
        inventorySlots: c.inventorySlots,
        inventoryCount: count,
        overflow: count - c.inventorySlots,
      })
    }
  }

  if (overflowed.length === 0) {
    console.log('\n✓ No overflow detected. Safe to ship CRIT-04 code fix with no cleanup.')
    return
  }

  // Sort by overflow size descending
  overflowed.sort((a, b) => b.overflow - a.overflow)

  const totalOverflow = overflowed.reduce((s, r) => s + r.overflow, 0)
  const maxOverflow = overflowed[0].overflow
  const pctOverflowed = ((overflowed.length / total) * 100).toFixed(2)

  console.log(`\n⚠ Overflow detected:`)
  console.log(`  Characters affected:  ${overflowed.length} / ${total} (${pctOverflowed}%)`)
  console.log(`  Total ghost items:    ${totalOverflow}`)
  console.log(`  Max overflow:         ${maxOverflow} items (one character)`)

  console.log('\nTop 20 affected characters:')
  console.log('  Character                        | Slots | Count | Overflow')
  console.log('  ---------------------------------|-------|-------|---------')
  for (const row of overflowed.slice(0, 20)) {
    const name = row.characterName.padEnd(32).slice(0, 32)
    const slots = String(row.inventorySlots).padStart(5)
    const count = String(row.inventoryCount).padStart(5)
    const over = String(row.overflow).padStart(8)
    console.log(`  ${name} | ${slots} | ${count} | ${over}`)
  }

  if (overflowed.length > 20) {
    console.log(`  ... and ${overflowed.length - 20} more`)
  }

  // Recommendation
  console.log('\nRecommendation:')
  if (overflowed.length <= 5) {
    console.log('  ≤ 5 affected — ship code fix + in-game notification, let players resolve manually.')
  } else if (overflowed.length <= 50) {
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
