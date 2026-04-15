-- Align legacy / skipped tutorial rows with the newer tutorial_completed flag.
-- Without this backfill, characters with tutorial_step >= 3 or tutorial_skipped
-- can still pass replay guards that only inspect tutorial_completed.
UPDATE "characters"
SET
  "tutorial_completed" = true,
  "tutorial_completed_at" = COALESCE("tutorial_completed_at", CURRENT_TIMESTAMP)
WHERE
  "tutorial_completed" = false
  AND ("tutorial_skipped" = true OR "tutorial_step" >= 3);
