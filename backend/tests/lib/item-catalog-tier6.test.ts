/**
 * Catalog parity: prisma/seed.ts (fresh databases) and the Tier 6 / class-loot
 * migration (production) must describe the same items, and every weapon must
 * carry a class so the loot relevance filter has something to filter on.
 */
import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
import { join } from 'node:path'

const seed = readFileSync(join(__dirname, '../../prisma/seed.ts'), 'utf8')
const migration = readFileSync(
  join(__dirname, '../../prisma/migrations/20261014_items_tier6_class_loot/migration.sql'),
  'utf8',
)

type SeedItem = { catalogId: string; itemType: string; itemLevel: number; classRestriction: string | null; rarity: string }

function parseSeedItems(): SeedItem[] {
  const items: SeedItem[] = []
  const field = (line: string, key: string) => line.match(new RegExp(`\\b${key}: '([^']*)'`))?.[1] ?? null
  for (const line of seed.split('\n')) {
    if (!line.trim().startsWith("{ catalogId: '")) continue
    const level = line.match(/\bitemLevel: (\d+)/)
    const catalogId = field(line, 'catalogId')
    const itemType = field(line, 'itemType')
    const rarity = field(line, 'rarity')
    if (!catalogId || !itemType || !rarity || !level) throw new Error(`unparseable seed line: ${line.slice(0, 80)}`)
    items.push({ catalogId, itemType, rarity, classRestriction: field(line, 'classRestriction'), itemLevel: Number(level[1]) })
  }
  return items
}

describe('item catalog — Tier 6 and class loot', () => {
  const items = parseSeedItems()

  it('parses the catalog (sanity: >100 items)', () => {
    expect(items.length).toBeGreaterThan(100)
  })

  it('every weapon has a class restriction, every non-weapon is universal', () => {
    const weapons = items.filter((i) => i.itemType === 'weapon')
    expect(weapons.length).toBeGreaterThanOrEqual(31)
    for (const w of weapons) expect(['warrior', 'tank', 'rogue', 'mage']).toContain(w.classRestriction)
    for (const i of items.filter((i) => i.itemType !== 'weapon')) expect(i.classRestriction).toBeNull()
  })

  it('each class has a weapon at L44 and a L50 capstone', () => {
    for (const cls of ['warrior', 'tank', 'rogue', 'mage']) {
      const levels = items.filter((i) => i.itemType === 'weapon' && i.classRestriction === cls).map((i) => i.itemLevel)
      expect(levels).toContain(44)
      expect(levels).toContain(50)
    }
  })

  it('covers 41–50 with at least one item every two levels', () => {
    const tier6 = items.filter((i) => i.itemLevel >= 41)
    expect(tier6.length).toBe(19)
    const levels = new Set(tier6.map((i) => i.itemLevel))
    for (let lvl = 42; lvl <= 50; lvl += 2) {
      expect([lvl, lvl - 1].some((l) => levels.has(l))).toBe(true)
    }
  })

  it('the prod migration inserts exactly the seed\'s Tier 6 items and restricts exactly the seed\'s weapons', () => {
    const tier6Ids = items.filter((i) => i.itemLevel >= 41).map((i) => i.catalogId).sort()
    const inserted = [...migration.matchAll(/\(gen_random_uuid\(\), '([^']+)'/g)].map((m) => m[1]).sort()
    expect(inserted).toEqual(tier6Ids)

    const seedRestrictions = Object.fromEntries(
      items.filter((i) => i.itemType === 'weapon' && i.itemLevel < 41).map((i) => [i.catalogId, i.classRestriction]),
    )
    const sqlRestrictions = Object.fromEntries(
      [...migration.matchAll(/\('(wpn_[a-z_]+)', '(warrior|tank|rogue|mage)'\)/g)].map((m) => [m[1], m[2]]),
    )
    expect(sqlRestrictions).toEqual(seedRestrictions)
    expect(migration).toContain('ON CONFLICT ("catalog_id") DO NOTHING')
    expect(migration).toContain('"class_restriction" IS NULL')
  })

  it('the tutorial sword stays universal', () => {
    expect(migration).not.toMatch(/\('wpn_iron_sword_tutorial'/)
    expect(items.find((i) => i.catalogId === 'wpn_iron_sword_tutorial')?.classRestriction ?? null).toBeNull()
  })
})
