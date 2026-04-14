-- Economy v3 Phase 2 (2026-04-14): Stamina cap 120 → 180
-- Rationale (ECONOMY_RULES.md R8): two daily check-ins must fully absorb
-- overnight regen. At 1 point / 8 min regen, 180 cap = 24h to fill 0 → max.
--
-- Strategy:
--   1. Raise column defaults so new characters spawn with 180.
--   2. Bump existing characters who are at or near the old 120 cap so they
--      don't feel the change as a downgrade. Players mid-dungeon (current <
--      maxStamina) keep their current value; only their cap goes up.
--
-- This is a pure buff for existing players — nobody's stamina decreases.

-- 1. Defaults
ALTER TABLE "characters" ALTER COLUMN "max_stamina" SET DEFAULT 180;
ALTER TABLE "characters" ALTER COLUMN "current_stamina" SET DEFAULT 180;

-- 2. Raise cap for every existing character who still has the old cap.
UPDATE "characters"
SET "max_stamina" = 180
WHERE "max_stamina" = 120;

-- 3. If a character was parked at full stamina on the old cap, top them up.
--    This is optional but nicer UX — they don't sit at 120/180 waiting.
UPDATE "characters"
SET "current_stamina" = 180
WHERE "max_stamina" = 180
  AND "current_stamina" = 120;
