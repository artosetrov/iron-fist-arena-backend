-- =============================================================================
-- 20261014_milestone_claims_per_account
--
-- Milestone rewards (gold + gems, L10 … L50) are paid to the account, but the
-- claim was keyed on the character. A user with five characters collected
-- every milestone five times — 172 500 gold and 2 600 gems into one wallet —
-- and since the claim cascaded with the character, deleting a L50 character
-- and levelling a fresh one reset the whole ladder.
--
-- The claim is now unique per (user, milestone). The character that earned
-- it is kept for display and set to NULL if that character is deleted, so
-- the claim itself survives.
--
-- Backfill keeps the EARLIEST claim per (user, level) and drops the rest —
-- those duplicates were the exploit, and the gold already paid out is not
-- clawed back here.
--
-- Run against prod via Supabase MCP BEFORE deploying the backend.
-- =============================================================================

ALTER TABLE "milestone_claims" ADD COLUMN IF NOT EXISTS "user_id" TEXT;

UPDATE "milestone_claims" mc
   SET "user_id" = c."user_id"
  FROM "characters" c
 WHERE mc."character_id" = c."id"
   AND mc."user_id" IS NULL;

-- Claims whose character is already gone cannot be attributed; they also
-- cannot be claimed again by anyone, so dropping them is safe.
DELETE FROM "milestone_claims" WHERE "user_id" IS NULL;

-- Collapse per-account duplicates, keeping the earliest.
DELETE FROM "milestone_claims" a
 USING "milestone_claims" b
 WHERE a."user_id" = b."user_id"
   AND a."milestone_level" = b."milestone_level"
   AND (a."claimed_at", a."id") > (b."claimed_at", b."id");

ALTER TABLE "milestone_claims" ALTER COLUMN "user_id" SET NOT NULL;
ALTER TABLE "milestone_claims" ALTER COLUMN "character_id" DROP NOT NULL;

ALTER TABLE "milestone_claims" DROP CONSTRAINT IF EXISTS "milestone_claims_character_id_milestone_level_key";
ALTER TABLE "milestone_claims" DROP CONSTRAINT IF EXISTS "milestone_claims_character_id_fkey";

ALTER TABLE "milestone_claims"
  ADD CONSTRAINT "milestone_claims_character_id_fkey"
  FOREIGN KEY ("character_id") REFERENCES "characters"("id") ON DELETE SET NULL ON UPDATE NO ACTION;

ALTER TABLE "milestone_claims"
  ADD CONSTRAINT "milestone_claims_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE UNIQUE INDEX IF NOT EXISTS "milestone_claims_user_id_milestone_level_key"
  ON "milestone_claims" ("user_id", "milestone_level");
