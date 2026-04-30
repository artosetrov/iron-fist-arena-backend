/**
 * seed-passives-v2.ts — TS runner for the four class passive trees.
 *
 * Applies the SQL seed files in `backend/prisma/seeds/passives-{class}-v2.sql`
 * to the connected Prisma DB in a deterministic order. Each SQL file is
 * idempotent (scope-limited DELETE on `node_key LIKE '<class>.%'` then INSERT)
 * and SAFE to re-run pre-launch — but WILL wipe progress if any player has
 * already unlocked v2 nodes for that class.
 *
 * Usage:
 *   npm run seed:passives          (runs all 4 classes)
 *   npm run seed:passives -- mage  (runs a single class)
 *
 * Why a TS wrapper exists alongside the SQL files:
 *   • Local / CI DB bootstrap from a clean schema can re-create the tree
 *     without copy-pasting SQL into psql.
 *   • Ergonomic single-command setup for new contributors.
 *   • Gatekeeper rule §6c: every SQL-only seed in the repo should have a
 *     TS pair so the canonical entry-point is uniform across data sets.
 *
 * Why this is a thin wrapper (not a Prisma `upsert` rewrite):
 *   • The SQL files are the spec source-of-truth — they're authored against
 *     `docs/06_game_systems/SKILL_TREE_DESIGN_V2.md` directly. Re-encoding
 *     the same data through `prisma.passiveNode.upsert` doubles the surface
 *     for drift between SQL and TS without adding correctness.
 *   • `executeRawUnsafe` runs the file verbatim, so iterating on a class
 *     tree is "edit the .sql, re-run npm script" — no TS rebuild dance.
 */

import { PrismaClient } from '@prisma/client'
import { readFileSync } from 'node:fs'
import { join } from 'node:path'

type ClassName = 'warrior' | 'rogue' | 'mage' | 'tank'

const ALL_CLASSES: ClassName[] = ['warrior', 'rogue', 'mage', 'tank']

/**
 * Resolve the SQL file path for a given class. Lives next to this script
 * regardless of where the package is invoked from.
 */
function sqlPathFor(klass: ClassName): string {
  return join(__dirname, `passives-${klass}-v2.sql`)
}

/**
 * Apply one class's SQL file. Each file is BEGIN/COMMIT-wrapped on its own,
 * so we don't need an outer transaction here — partial failure on one class
 * still leaves the others intact, which is the right behavior for a seed
 * tool (the operator can re-run only the broken class).
 */
async function applyClass(prisma: PrismaClient, klass: ClassName): Promise<{ nodes: number; connections: number }> {
  const path = sqlPathFor(klass)
  const sql = readFileSync(path, 'utf8')

  // `executeRawUnsafe` accepts arbitrary SQL — required because the seed
  // files contain BEGIN/COMMIT, multiple statements, and a CTE-driven INSERT
  // that the parameterized `executeRaw` can't represent.
  await prisma.$executeRawUnsafe(sql)

  const [{ count: nodes }] = await prisma.$queryRawUnsafe<{ count: bigint }[]>(
    `SELECT COUNT(*)::bigint AS count FROM passive_nodes WHERE node_key LIKE $1`,
    `${klass}.%`,
  )
  const [{ count: connections }] = await prisma.$queryRawUnsafe<{ count: bigint }[]>(
    `SELECT COUNT(*)::bigint AS count FROM passive_connections
        WHERE from_id IN (SELECT id FROM passive_nodes WHERE node_key LIKE $1)
           OR to_id   IN (SELECT id FROM passive_nodes WHERE node_key LIKE $1)`,
    `${klass}.%`,
  )

  return { nodes: Number(nodes), connections: Number(connections) }
}

async function main() {
  const targetArg = process.argv[2]?.toLowerCase() as ClassName | undefined
  const targets: ClassName[] = targetArg
    ? (ALL_CLASSES.includes(targetArg) ? [targetArg] : [])
    : ALL_CLASSES

  if (targets.length === 0) {
    console.error(
      `[seed-passives-v2] unknown class "${targetArg}". ` +
        `Use one of: ${ALL_CLASSES.join(', ')} — or omit the arg to seed all.`,
    )
    process.exit(2)
  }

  const prisma = new PrismaClient()
  try {
    console.log(`[seed-passives-v2] applying: ${targets.join(', ')}`)
    for (const klass of targets) {
      const t0 = Date.now()
      const { nodes, connections } = await applyClass(prisma, klass)
      console.log(
        `[seed-passives-v2] ${klass.padEnd(8)} → ${nodes} nodes / ${connections} connections (${Date.now() - t0} ms)`,
      )
    }
    console.log(`[seed-passives-v2] done.`)
  } finally {
    await prisma.$disconnect()
  }
}

main().catch((err) => {
  console.error('[seed-passives-v2] failed:', err)
  process.exit(1)
})
