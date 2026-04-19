-- Add `tagline` to dungeon_bosses: one-sentence hook for the root-level
-- boss reveal overlay introduced in the 2026-04-19 ceremony iteration.
-- Nullable — clients fall back to the first sentence of `description`
-- when absent.

ALTER TABLE "dungeon_bosses" ADD COLUMN "tagline" TEXT;

-- Backfill existing rows from `description`. Existing boss descriptions
-- are already short, punchy one-liners (e.g. "Tiny, glowing, toxic.")
-- that read naturally as reveal subtitles. Authors can override via the
-- admin UI or a later repair script once distinct copy is desired.
-- Safe + idempotent: only fills null cells, so authored taglines created
-- between this migration and any re-run are preserved.
UPDATE "dungeon_bosses"
SET "tagline" = "description"
WHERE "tagline" IS NULL
  AND "description" IS NOT NULL
  AND length(trim("description")) > 0;
