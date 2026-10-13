-- =============================================================================
-- 20260915_rank_achievement_targets
--
-- Realign the rank achievements with the tier floors they are named after.
--
-- `rank_silver` unlocked at 1200 — Silver I on the current ladder, not Silver.
-- It is the same defect that was corrected by hand for Diamond (1800 -> 3000)
-- and Grandmaster (2200 -> 4250) in v3, missed for Silver at the time. The
-- catalog now derives these targets from tier.ts (`minRatingForTier`), so the
-- code is fixed; this migration fixes the rows the old numbers were written to.
--
-- Two tables hold a copy:
--   * achievement_definitions.target — the seeded catalog. The admin seeder
--     skips keys that already exist, so it will never correct these itself.
--   * achievements.target            — copied onto each character's row when it
--     is created, and what /api/achievements renders and the claim routes
--     compare against. Without this, a player sits at "750 / 1200" with a 62%
--     bar on an achievement the game already considers complete.
--
-- `completed` is recomputed for rows that now clear their target. `completed_at`
-- is set where it is missing so the UI has a date; `reward_claimed` is left
-- alone so nothing is claimed twice.
--
-- Lowering a target can only complete achievements, never un-complete them, so
-- this is safe to re-run.
--
-- Run against prod via Supabase MCP BEFORE deploying the backend.
-- =============================================================================

UPDATE "achievement_definitions" SET "target" = 750  WHERE "key" = 'rank_silver'      AND "target" <> 750;
UPDATE "achievement_definitions" SET "target" = 1500 WHERE "key" = 'rank_gold'        AND "target" <> 1500;
UPDATE "achievement_definitions" SET "target" = 3000 WHERE "key" = 'rank_diamond'     AND "target" <> 3000;
UPDATE "achievement_definitions" SET "target" = 4250 WHERE "key" = 'rank_grandmaster' AND "target" <> 4250;

UPDATE "achievements" SET "target" = 750  WHERE "achievement_key" = 'rank_silver'      AND "target" <> 750;
UPDATE "achievements" SET "target" = 1500 WHERE "achievement_key" = 'rank_gold'        AND "target" <> 1500;
UPDATE "achievements" SET "target" = 3000 WHERE "achievement_key" = 'rank_diamond'     AND "target" <> 3000;
UPDATE "achievements" SET "target" = 4250 WHERE "achievement_key" = 'rank_grandmaster' AND "target" <> 4250;

UPDATE "achievements"
   SET "completed" = true,
       "completed_at" = COALESCE("completed_at", NOW())
 WHERE "achievement_key" IN ('rank_silver', 'rank_gold', 'rank_diamond', 'rank_grandmaster')
   AND "completed" = false
   AND "progress" >= "target";
