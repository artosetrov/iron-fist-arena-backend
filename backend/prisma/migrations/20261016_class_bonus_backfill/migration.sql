-- Class stat bonuses become real on the server (2026-10-16).
-- Until now only ORIGIN_BONUSES were applied at creation; the client advertised
-- CLASS_BONUSES (warrior STR+3 VIT+2, rogue AGI+3 LUK+2, mage INT+3 WIS+2,
-- tank VIT+3 END+2) that were never granted. This adds them to every existing
-- hero exactly once, guarded by "class_bonus_applied".
--
-- Idempotent: re-running only touches rows still flagged false (e.g. heroes
-- created by the old backend between this migration and the backend deploy).
-- Source of truth for the numbers: backend/src/lib/game/creation-stats.ts

ALTER TABLE "characters"
  ADD COLUMN IF NOT EXISTS "class_bonus_applied" BOOLEAN NOT NULL DEFAULT false;

-- HP: add exactly what the extra VIT/END is worth (5 per VIT, 3 per END) on top of
-- the stored max_hp, so any other HP sources already baked in stay untouched.
-- Heroes are healed by the same amount (never above the new max).
WITH bonus AS (
  SELECT
    c."id",
    CASE c."class" WHEN 'warrior' THEN 3 ELSE 0 END AS d_str,
    CASE c."class" WHEN 'rogue'   THEN 3 ELSE 0 END AS d_agi,
    CASE c."class" WHEN 'warrior' THEN 2 WHEN 'tank' THEN 3 ELSE 0 END AS d_vit,
    CASE c."class" WHEN 'tank'    THEN 2 ELSE 0 END AS d_end,
    CASE c."class" WHEN 'mage'    THEN 3 ELSE 0 END AS d_int,
    CASE c."class" WHEN 'mage'    THEN 2 ELSE 0 END AS d_wis,
    CASE c."class" WHEN 'rogue'   THEN 2 ELSE 0 END AS d_luk
  FROM "characters" c
  WHERE c."class_bonus_applied" = false
)
UPDATE "characters" t
SET
  "str" = t."str" + b.d_str,
  "agi" = t."agi" + b.d_agi,
  "vit" = t."vit" + b.d_vit,
  "end" = t."end" + b.d_end,
  "int" = t."int" + b.d_int,
  "wis" = t."wis" + b.d_wis,
  "luk" = t."luk" + b.d_luk,
  "max_hp" = t."max_hp" + b.d_vit * 5 + b.d_end * 3,
  "current_hp" = LEAST(
    t."max_hp" + b.d_vit * 5 + b.d_end * 3,
    t."current_hp" + b.d_vit * 5 + b.d_end * 3
  ),
  "class_bonus_applied" = true
FROM bonus b
WHERE t."id" = b."id";
