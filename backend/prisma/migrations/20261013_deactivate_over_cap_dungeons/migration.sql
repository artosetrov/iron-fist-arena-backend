-- 2026-10-13: hide dungeons nobody can ever enter.
--
-- PRESTIGE.MAX_LEVEL is 50 and prestige resets level to 1, so the three
-- dungeons seeded at level_req 55/60/65 (clockwork_citadel, abyssal_depths,
-- infernal_throne) are permanently unreachable. Deactivate them until the
-- level cap or prestige design changes. Idempotent; re-activate via admin.
--
-- Run against prod via Supabase BEFORE deploying the backend that ships it
-- (same pattern as the 202609* data migrations).
UPDATE "dungeons"
SET "is_active" = false, "updated_at" = NOW()
WHERE "level_req" > 50 AND "is_active" = true;
