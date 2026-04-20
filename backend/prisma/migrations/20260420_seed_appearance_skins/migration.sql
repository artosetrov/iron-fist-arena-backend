-- Seed 2026-04-20: repopulate appearance_skins catalog.
-- Production `appearance_skins` was found empty (0 rows), which left
-- `/api/appearances` returning { skins: [] } and dead-locked the "Choose Your
-- Appearance" step during character creation (selectedSkinKey stayed nil,
-- the Next button was permanently disabled, and the hero card rendered
-- with no avatar).
--
-- Most likely cause: a snapshot restore that did not carry this static
-- catalog (same class of incident as Degon 2026-04-19 / Gold Mine 2026-04-11
-- / Stash 2026-04-13). The 40 PNGs still exist in Supabase Storage
-- `assets/appearances/`; only the DB rows were gone.
--
-- This migration reseeds all 40 default skins derived from the Storage
-- filenames (`{origin}_{m|f}_{name}.png`). It is idempotent via
-- `ON CONFLICT (skin_key) DO NOTHING` so it is safe to re-run and will not
-- overwrite admin-customised rows that already exist with the same key.

INSERT INTO "appearance_skins" (
  "id", "skin_key", "name", "origin", "gender",
  "rarity", "price_gold", "price_gems",
  "image_url", "image_key",
  "is_default", "sort_order", "created_at", "updated_at"
) VALUES
  -- demon / female
  (gen_random_uuid(), 'demon_f_demoness',     'Demoness',      'demon', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/demon_f_demoness.png',     'demon_f_demoness',     true,  1, NOW(), NOW()),
  (gen_random_uuid(), 'demon_f_hellfire',     'Hellfire',      'demon', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/demon_f_hellfire.png',     'demon_f_hellfire',     false, 2, NOW(), NOW()),
  (gen_random_uuid(), 'demon_f_shadow_witch', 'Shadow Witch',  'demon', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/demon_f_shadow_witch.png', 'demon_f_shadow_witch', false, 3, NOW(), NOW()),
  (gen_random_uuid(), 'demon_f_succubus',     'Succubus',      'demon', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/demon_f_succubus.png',     'demon_f_succubus',     false, 4, NOW(), NOW()),

  -- demon / male
  (gen_random_uuid(), 'demon_m_fiend',    'Fiend',    'demon', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/demon_m_fiend.png',    'demon_m_fiend',    true,  1, NOW(), NOW()),
  (gen_random_uuid(), 'demon_m_hellborn', 'Hellborn', 'demon', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/demon_m_hellborn.png', 'demon_m_hellborn', false, 2, NOW(), NOW()),
  (gen_random_uuid(), 'demon_m_infernal', 'Infernal', 'demon', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/demon_m_infernal.png', 'demon_m_infernal', false, 3, NOW(), NOW()),
  (gen_random_uuid(), 'demon_m_warlock',  'Warlock',  'demon', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/demon_m_warlock.png',  'demon_m_warlock',  false, 4, NOW(), NOW()),

  -- dogfolk / female
  (gen_random_uuid(), 'dogfolk_f_feral',       'Feral',       'dogfolk', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/dogfolk_f_feral.png',       'dogfolk_f_feral',       true,  1, NOW(), NOW()),
  (gen_random_uuid(), 'dogfolk_f_moon_dancer', 'Moon Dancer', 'dogfolk', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/dogfolk_f_moon_dancer.png', 'dogfolk_f_moon_dancer', false, 2, NOW(), NOW()),
  (gen_random_uuid(), 'dogfolk_f_she_wolf',    'She-Wolf',    'dogfolk', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/dogfolk_f_she_wolf.png',    'dogfolk_f_she_wolf',    false, 3, NOW(), NOW()),
  (gen_random_uuid(), 'dogfolk_f_swift_paw',   'Swift Paw',   'dogfolk', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/dogfolk_f_swift_paw.png',   'dogfolk_f_swift_paw',   false, 4, NOW(), NOW()),

  -- dogfolk / male
  (gen_random_uuid(), 'dogfolk_m_alpha',    'Alpha',    'dogfolk', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/dogfolk_m_alpha.png',    'dogfolk_m_alpha',    true,  1, NOW(), NOW()),
  (gen_random_uuid(), 'dogfolk_m_guardian', 'Guardian', 'dogfolk', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/dogfolk_m_guardian.png', 'dogfolk_m_guardian', false, 2, NOW(), NOW()),
  (gen_random_uuid(), 'dogfolk_m_howler',   'Howler',   'dogfolk', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/dogfolk_m_howler.png',   'dogfolk_m_howler',   false, 3, NOW(), NOW()),
  (gen_random_uuid(), 'dogfolk_m_tracker',  'Tracker',  'dogfolk', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/dogfolk_m_tracker.png',  'dogfolk_m_tracker',  false, 4, NOW(), NOW()),

  -- human / female
  (gen_random_uuid(), 'human_f_archer',     'Archer',     'human', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/human_f_archer.png',     'human_f_archer',     true,  1, NOW(), NOW()),
  (gen_random_uuid(), 'human_f_noblewoman', 'Noblewoman', 'human', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/human_f_noblewoman.png', 'human_f_noblewoman', false, 2, NOW(), NOW()),
  (gen_random_uuid(), 'human_f_priestess',  'Priestess',  'human', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/human_f_priestess.png',  'human_f_priestess',  false, 3, NOW(), NOW()),
  (gen_random_uuid(), 'human_f_sorceress',  'Sorceress',  'human', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/human_f_sorceress.png',  'human_f_sorceress',  false, 4, NOW(), NOW()),

  -- human / male
  (gen_random_uuid(), 'human_m_knight',    'Knight',    'human', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/human_m_knight.png',    'human_m_knight',    true,  1, NOW(), NOW()),
  (gen_random_uuid(), 'human_m_nobleman',  'Nobleman',  'human', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/human_m_nobleman.png',  'human_m_nobleman',  false, 2, NOW(), NOW()),
  (gen_random_uuid(), 'human_m_paladin',   'Paladin',   'human', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/human_m_paladin.png',   'human_m_paladin',   false, 3, NOW(), NOW()),
  (gen_random_uuid(), 'human_m_ranger',    'Ranger',    'human', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/human_m_ranger.png',    'human_m_ranger',    false, 4, NOW(), NOW()),

  -- orc / female
  (gen_random_uuid(), 'orc_f_huntress',     'Huntress',     'orc', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/orc_f_huntress.png',     'orc_f_huntress',     true,  1, NOW(), NOW()),
  (gen_random_uuid(), 'orc_f_savage',       'Savage',       'orc', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/orc_f_savage.png',       'orc_f_savage',       false, 2, NOW(), NOW()),
  (gen_random_uuid(), 'orc_f_warmaiden',    'Warmaiden',    'orc', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/orc_f_warmaiden.png',    'orc_f_warmaiden',    false, 3, NOW(), NOW()),
  (gen_random_uuid(), 'orc_f_witch_doctor', 'Witch Doctor', 'orc', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/orc_f_witch_doctor.png', 'orc_f_witch_doctor', false, 4, NOW(), NOW()),

  -- orc / male
  (gen_random_uuid(), 'orc_m_berserker', 'Berserker', 'orc', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/orc_m_berserker.png', 'orc_m_berserker', true,  1, NOW(), NOW()),
  (gen_random_uuid(), 'orc_m_brute',     'Brute',     'orc', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/orc_m_brute.png',     'orc_m_brute',     false, 2, NOW(), NOW()),
  (gen_random_uuid(), 'orc_m_shaman',    'Shaman',    'orc', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/orc_m_shaman.png',    'orc_m_shaman',    false, 3, NOW(), NOW()),
  (gen_random_uuid(), 'orc_m_warchief',  'Warchief',  'orc', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/orc_m_warchief.png',  'orc_m_warchief',  false, 4, NOW(), NOW()),

  -- skeleton / female
  (gen_random_uuid(), 'skeleton_f_banshee',    'Banshee',    'skeleton', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/skeleton_f_banshee.png',    'skeleton_f_banshee',    true,  1, NOW(), NOW()),
  (gen_random_uuid(), 'skeleton_f_bone_witch', 'Bone Witch', 'skeleton', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/skeleton_f_bone_witch.png', 'skeleton_f_bone_witch', false, 2, NOW(), NOW()),
  (gen_random_uuid(), 'skeleton_f_specter',    'Specter',    'skeleton', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/skeleton_f_specter.png',    'skeleton_f_specter',    false, 3, NOW(), NOW()),
  (gen_random_uuid(), 'skeleton_f_wraith',     'Wraith',     'skeleton', 'female', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/skeleton_f_wraith.png',     'skeleton_f_wraith',     false, 4, NOW(), NOW()),

  -- skeleton / male
  (gen_random_uuid(), 'skeleton_m_bone_warrior', 'Bone Warrior', 'skeleton', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/skeleton_m_bone_warrior.png', 'skeleton_m_bone_warrior', true,  1, NOW(), NOW()),
  (gen_random_uuid(), 'skeleton_m_death_knight', 'Death Knight', 'skeleton', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/skeleton_m_death_knight.png', 'skeleton_m_death_knight', false, 2, NOW(), NOW()),
  (gen_random_uuid(), 'skeleton_m_lich',         'Lich',         'skeleton', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/skeleton_m_lich.png',         'skeleton_m_lich',         false, 3, NOW(), NOW()),
  (gen_random_uuid(), 'skeleton_m_revenant',     'Revenant',     'skeleton', 'male', 'common', 0, 0,
    'https://gqnyozmqbhgzprsftdzp.supabase.co/storage/v1/object/public/assets/appearances/skeleton_m_revenant.png',     'skeleton_m_revenant',     false, 4, NOW(), NOW())
ON CONFLICT ("skin_key") DO NOTHING;
