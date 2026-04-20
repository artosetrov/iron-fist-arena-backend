/**
 * Seed `appearance_skins` from the canonical catalog.
 *
 * Mirrors `prisma/migrations/20260420_seed_appearance_skins/migration.sql` —
 * keep them in sync. The migration is what runs in prod / staging; this
 * script is for local dev DBs and CI fixtures.
 *
 * Source of truth: PNG files in Supabase Storage `assets/appearances/`.
 * Naming convention:
 *   `{origin}_{m|f}_{name}.png`  →  skin_key `origin_x_name`
 *
 * Default skin per (origin, gender) is the first entry alphabetically.
 *
 * Idempotent: uses `upsert` keyed on `skinKey`. Re-running will not duplicate
 * rows and will refresh `name` / `imageUrl` / `imageKey` / `sortOrder` /
 * `isDefault` to whatever is in this file (admin-edited rarity / pricing
 * fields are NOT touched on conflict — see `update` block).
 */

import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

const STORAGE_BASE =
  'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances'

type Origin = 'human' | 'orc' | 'skeleton' | 'demon' | 'dogfolk'
type Gender = 'male' | 'female'

interface Skin {
  skinKey: string
  name: string
  origin: Origin
  gender: Gender
}

// Names mirror Storage filenames; display name is title-case with `_` → ` `.
const SKIN_DEFS: Skin[] = [
  // demon / female
  { skinKey: 'demon_f_demoness',     name: 'Demoness',     origin: 'demon', gender: 'female' },
  { skinKey: 'demon_f_hellfire',     name: 'Hellfire',     origin: 'demon', gender: 'female' },
  { skinKey: 'demon_f_shadow_witch', name: 'Shadow Witch', origin: 'demon', gender: 'female' },
  { skinKey: 'demon_f_succubus',     name: 'Succubus',     origin: 'demon', gender: 'female' },
  // demon / male
  { skinKey: 'demon_m_fiend',    name: 'Fiend',    origin: 'demon', gender: 'male' },
  { skinKey: 'demon_m_hellborn', name: 'Hellborn', origin: 'demon', gender: 'male' },
  { skinKey: 'demon_m_infernal', name: 'Infernal', origin: 'demon', gender: 'male' },
  { skinKey: 'demon_m_warlock',  name: 'Warlock',  origin: 'demon', gender: 'male' },
  // dogfolk / female
  { skinKey: 'dogfolk_f_feral',       name: 'Feral',       origin: 'dogfolk', gender: 'female' },
  { skinKey: 'dogfolk_f_moon_dancer', name: 'Moon Dancer', origin: 'dogfolk', gender: 'female' },
  { skinKey: 'dogfolk_f_she_wolf',    name: 'She-Wolf',    origin: 'dogfolk', gender: 'female' },
  { skinKey: 'dogfolk_f_swift_paw',   name: 'Swift Paw',   origin: 'dogfolk', gender: 'female' },
  // dogfolk / male
  { skinKey: 'dogfolk_m_alpha',    name: 'Alpha',    origin: 'dogfolk', gender: 'male' },
  { skinKey: 'dogfolk_m_guardian', name: 'Guardian', origin: 'dogfolk', gender: 'male' },
  { skinKey: 'dogfolk_m_howler',   name: 'Howler',   origin: 'dogfolk', gender: 'male' },
  { skinKey: 'dogfolk_m_tracker',  name: 'Tracker',  origin: 'dogfolk', gender: 'male' },
  // human / female
  { skinKey: 'human_f_archer',     name: 'Archer',     origin: 'human', gender: 'female' },
  { skinKey: 'human_f_noblewoman', name: 'Noblewoman', origin: 'human', gender: 'female' },
  { skinKey: 'human_f_priestess',  name: 'Priestess',  origin: 'human', gender: 'female' },
  { skinKey: 'human_f_sorceress',  name: 'Sorceress',  origin: 'human', gender: 'female' },
  // human / male
  { skinKey: 'human_m_knight',   name: 'Knight',   origin: 'human', gender: 'male' },
  { skinKey: 'human_m_nobleman', name: 'Nobleman', origin: 'human', gender: 'male' },
  { skinKey: 'human_m_paladin',  name: 'Paladin',  origin: 'human', gender: 'male' },
  { skinKey: 'human_m_ranger',   name: 'Ranger',   origin: 'human', gender: 'male' },
  // orc / female
  { skinKey: 'orc_f_huntress',     name: 'Huntress',     origin: 'orc', gender: 'female' },
  { skinKey: 'orc_f_savage',       name: 'Savage',       origin: 'orc', gender: 'female' },
  { skinKey: 'orc_f_warmaiden',    name: 'Warmaiden',    origin: 'orc', gender: 'female' },
  { skinKey: 'orc_f_witch_doctor', name: 'Witch Doctor', origin: 'orc', gender: 'female' },
  // orc / male
  { skinKey: 'orc_m_berserker', name: 'Berserker', origin: 'orc', gender: 'male' },
  { skinKey: 'orc_m_brute',     name: 'Brute',     origin: 'orc', gender: 'male' },
  { skinKey: 'orc_m_shaman',    name: 'Shaman',    origin: 'orc', gender: 'male' },
  { skinKey: 'orc_m_warchief',  name: 'Warchief',  origin: 'orc', gender: 'male' },
  // skeleton / female
  { skinKey: 'skeleton_f_banshee',    name: 'Banshee',    origin: 'skeleton', gender: 'female' },
  { skinKey: 'skeleton_f_bone_witch', name: 'Bone Witch', origin: 'skeleton', gender: 'female' },
  { skinKey: 'skeleton_f_specter',    name: 'Specter',    origin: 'skeleton', gender: 'female' },
  { skinKey: 'skeleton_f_wraith',     name: 'Wraith',     origin: 'skeleton', gender: 'female' },
  // skeleton / male
  { skinKey: 'skeleton_m_bone_warrior', name: 'Bone Warrior', origin: 'skeleton', gender: 'male' },
  { skinKey: 'skeleton_m_death_knight', name: 'Death Knight', origin: 'skeleton', gender: 'male' },
  { skinKey: 'skeleton_m_lich',         name: 'Lich',         origin: 'skeleton', gender: 'male' },
  { skinKey: 'skeleton_m_revenant',     name: 'Revenant',     origin: 'skeleton', gender: 'male' },
]

async function main() {
  // Group by (origin, gender) so we can mark `is_default` deterministically:
  // first skin alphabetically per pair.
  const grouped = new Map<string, Skin[]>()
  for (const skin of SKIN_DEFS) {
    const key = `${skin.origin}/${skin.gender}`
    if (!grouped.has(key)) grouped.set(key, [])
    grouped.get(key)!.push(skin)
  }

  let created = 0
  let updated = 0

  for (const [, skins] of grouped) {
    skins.sort((a, b) => a.skinKey.localeCompare(b.skinKey))

    for (let i = 0; i < skins.length; i++) {
      const skin = skins[i]
      const isDefault = i === 0
      const sortOrder = i + 1
      const imageUrl = `${STORAGE_BASE}/${skin.skinKey}.png`

      const result = await prisma.appearanceSkin.upsert({
        where: { skinKey: skin.skinKey },
        // Update only catalog metadata — leave admin-managed pricing /
        // rarity untouched if a row already exists.
        update: {
          name: skin.name,
          origin: skin.origin,
          gender: skin.gender,
          imageUrl,
          imageKey: skin.skinKey,
          isDefault,
          sortOrder,
        },
        create: {
          skinKey: skin.skinKey,
          name: skin.name,
          origin: skin.origin,
          gender: skin.gender,
          rarity: 'common',
          priceGold: 0,
          priceGems: 0,
          imageUrl,
          imageKey: skin.skinKey,
          isDefault,
          sortOrder,
        },
      })

      if (result.createdAt.getTime() === result.updatedAt.getTime()) {
        created++
      } else {
        updated++
      }
    }
  }

  console.log(`✓ appearance_skins seed complete — ${created} created, ${updated} updated`)
}

main()
  .catch((err) => {
    console.error('✗ appearance_skins seed failed:', err)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
