-- Interactive Combat v1 — additive columns on pvp_matches.
-- Safe to run against prod: all columns nullable / have defaults,
-- existing /pvp/fight flow does not reference these fields.

ALTER TABLE "public"."pvp_matches"
  ADD COLUMN IF NOT EXISTS "status" TEXT DEFAULT 'completed',
  ADD COLUMN IF NOT EXISTS "interactive_strike_index" INTEGER,
  ADD COLUMN IF NOT EXISTS "interactive_timeout_at" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "interactive_choices" JSONB;

-- Backfill any existing rows so the NOT-NULL-like semantics stay stable
-- (column is nullable in Prisma, but we want non-interactive rows marked completed).
UPDATE "public"."pvp_matches"
SET "status" = 'completed'
WHERE "status" IS NULL;

CREATE INDEX IF NOT EXISTS "pvp_matches_status_idx"
  ON "public"."pvp_matches" ("status" ASC);
