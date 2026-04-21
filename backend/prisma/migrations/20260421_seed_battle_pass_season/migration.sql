-- Seed 2026-04-21: idempotently repopulate Season 1 + battle pass reward ladder.
--
-- Source of truth: `backend/prisma/seed-battle-pass.ts` (reward formulas) plus
-- `backend/prisma/battle-pass-milestones.ts` (level 10/20/30 item milestones).
-- This .sql mirrors the TS seed so a prod / staging snapshot-restore can rehydrate
-- the live battle pass without Node tooling.
--
-- IMPORTANT: the TS seed does a `deleteMany` before re-inserting rewards — safe
-- only for bootstrap / controlled repair flows. THIS MIGRATION does NOT delete:
-- ON CONFLICT (season_id, bp_level, is_premium) DO NOTHING so operator tuning
-- on existing rows is preserved. Use the TS seed for a clean rewrite, this SQL
-- for gap-fill after a snapshot-restore.
--
-- When editing reward formulas: regenerate BOTH `seed-battle-pass.ts` AND this
-- file in the same commit. See gatekeeper/SKILL.md §6c.
--
-- Related incidents: Stash (2026-04-13) — battle_pass_rewards rows were wiped
-- by a prod snapshot-restore; admins had to re-run the TS seed by hand because
-- there was no .sql mirror.

-- ---------------------------------------------------------------------------
-- Season 1 — upsert by unique `number`
-- ---------------------------------------------------------------------------

INSERT INTO "seasons" ("id", "number", "theme", "start_at", "end_at", "created_at", "updated_at")
VALUES (
  gen_random_uuid(),
  1,
  'Season 1: Dark Forge',
  NOW(),
  NOW() + INTERVAL '90 days',
  NOW(),
  NOW()
)
ON CONFLICT ("number") DO NOTHING;

-- ---------------------------------------------------------------------------
-- Battle pass rewards — non-item tiers (free + premium gold/gems/xp/stamina)
--
-- Mirrors the per-level formula in seed-battle-pass.ts:
--   Free:
--     level % 5 == 0  -> gems  (<=10 ? 5 : <=20 ? 10 : 20)
--     level % 3 == 0  -> xp    (200 + level*50)
--     else            -> gold  (100 + level*30)
--   Premium (non-milestone):
--     level % 10 == 0 -> item  (handled by the next INSERT)
--     level % 5 == 0  -> gems  (<=10 ? 15 : <=20 ? 25 : 50)
--     level % 2 == 0  -> gold  (200 + level*50)
--     else            -> level%4==1 ? stamina (30+level*2) : xp (300+level*60)
-- ---------------------------------------------------------------------------

INSERT INTO "battle_pass_rewards" ("id", "season_id", "bp_level", "is_premium", "reward_type", "reward_id", "reward_amount", "created_at")
SELECT gen_random_uuid(), s."id", v.bp_level, v.is_premium, v.reward_type, NULL, v.reward_amount, NOW()
FROM "seasons" s
CROSS JOIN (VALUES
  -- Free track (30 rows)
  ( 1, false, 'gold',     130),
  ( 2, false, 'gold',     160),
  ( 3, false, 'xp',       350),
  ( 4, false, 'gold',     220),
  ( 5, false, 'gems',       5),
  ( 6, false, 'xp',       500),
  ( 7, false, 'gold',     310),
  ( 8, false, 'gold',     340),
  ( 9, false, 'xp',       650),
  (10, false, 'gems',       5),
  (11, false, 'gold',     430),
  (12, false, 'xp',       800),
  (13, false, 'gold',     490),
  (14, false, 'gold',     520),
  (15, false, 'gems',      10),
  (16, false, 'gold',     580),
  (17, false, 'gold',     610),
  (18, false, 'xp',      1100),
  (19, false, 'gold',     670),
  (20, false, 'gems',      10),
  (21, false, 'xp',      1250),
  (22, false, 'gold',     760),
  (23, false, 'gold',     790),
  (24, false, 'xp',      1400),
  (25, false, 'gems',      20),
  (26, false, 'gold',     880),
  (27, false, 'xp',      1550),
  (28, false, 'gold',     940),
  (29, false, 'gold',     970),
  (30, false, 'gems',      20),
  -- Premium track, non-item tiers (27 rows; levels 10/20/30 are handled below)
  ( 1, true,  'stamina',   32),
  ( 2, true,  'gold',     300),
  ( 3, true,  'xp',       480),
  ( 4, true,  'gold',     400),
  ( 5, true,  'gems',      15),
  ( 6, true,  'gold',     500),
  ( 7, true,  'xp',       720),
  ( 8, true,  'gold',     600),
  ( 9, true,  'stamina',   48),
  (11, true,  'xp',       960),
  (12, true,  'gold',     800),
  (13, true,  'stamina',   56),
  (14, true,  'gold',     900),
  (15, true,  'gems',      25),
  (16, true,  'gold',    1000),
  (17, true,  'stamina',   64),
  (18, true,  'gold',    1100),
  (19, true,  'xp',      1440),
  (21, true,  'stamina',   72),
  (22, true,  'gold',    1300),
  (23, true,  'xp',      1680),
  (24, true,  'gold',    1400),
  (25, true,  'gems',      50),
  (26, true,  'gold',    1500),
  (27, true,  'xp',      1920),
  (28, true,  'gold',    1600),
  (29, true,  'stamina',   88)
) AS v(bp_level, is_premium, reward_type, reward_amount)
WHERE s."number" = 1
ON CONFLICT ("season_id", "bp_level", "is_premium") DO NOTHING;

-- ---------------------------------------------------------------------------
-- Battle pass rewards — premium milestone items at levels 10 / 20 / 30.
--
-- FK-style lookup: we do NOT hardcode item UUIDs. We join to `items` on
-- `catalog_id` so the mirror stays tolerant of the item seed running at a
-- different time (or being re-seeded with fresh UUIDs after a restore).
--
-- If the items catalog is missing a milestone row, the matching reward simply
-- won't be inserted — admins will see the gap and must seed items first. This
-- is the same precondition the TS seed enforces (with a thrown error).
-- ---------------------------------------------------------------------------

INSERT INTO "battle_pass_rewards" ("id", "season_id", "bp_level", "is_premium", "reward_type", "reward_id", "reward_amount", "created_at")
SELECT gen_random_uuid(), s."id", m.bp_level, true, 'item', i."id", 1, NOW()
FROM "seasons" s
CROSS JOIN (VALUES
  (10, 'chest_chain_mail'),
  (20, 'chest_plate_armor'),
  (30, 'chest_titan_cuirass')
) AS m(bp_level, catalog_id)
JOIN "items" i ON i."catalog_id" = m.catalog_id
WHERE s."number" = 1
ON CONFLICT ("season_id", "bp_level", "is_premium") DO NOTHING;
