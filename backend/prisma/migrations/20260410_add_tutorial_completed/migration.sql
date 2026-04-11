-- W2.D3 — Scripted tutorial fight completion tracking.
-- Adds `tutorial_completed` boolean flag and `tutorial_completed_at` timestamp
-- to the Character table. Used by /api/tutorial/scripted-fight/* endpoints
-- to prevent replay for rewards.

ALTER TABLE "characters"
  ADD COLUMN IF NOT EXISTS "tutorial_completed" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS "tutorial_completed_at" TIMESTAMP(3);

-- Partial index for fast "has tutorial been completed" lookups.
-- Only indexes characters where tutorial_completed = true (smaller index).
CREATE INDEX IF NOT EXISTS "characters_tutorial_completed_idx"
  ON "characters" ("tutorial_completed")
  WHERE "tutorial_completed" = true;
