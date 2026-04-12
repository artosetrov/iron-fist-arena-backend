-- Hotfix 2026-04-11: Gold Mine Variant D Phase 2 shaft columns were added
-- to schema.prisma in commit d4450b4 without a corresponding migration file.
-- Prod `/api/characters` was returning 500:
--   ERROR: column characters.active_shaft_key does not exist
-- This migration adds the missing columns. Non-destructive, idempotent.

ALTER TABLE "characters" ADD COLUMN IF NOT EXISTS "active_shaft_key" TEXT;
ALTER TABLE "characters" ADD COLUMN IF NOT EXISTS "shaft_progress" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "characters" ADD COLUMN IF NOT EXISTS "shaft_total" INTEGER NOT NULL DEFAULT 5;
