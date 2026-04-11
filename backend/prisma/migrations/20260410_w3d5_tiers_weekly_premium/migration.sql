-- W3.D5 — PvP tier expansion, Weekly BP challenges, Premium Forever
--
-- Three blocks in one migration (all additive, all nullable/default-safe):
--
-- (1) BAL-05 — ELO tier expansion
--     No schema change. New ladder lives in code: backend/src/lib/game/tier.ts.
--     PVP_RANKS live-config rows (bronze/silver/gold/platinum/diamond/master/
--     grandmaster) are seeded by admin/src/actions/config.ts on next admin load.
--     Starting rating 1000 now lands in Silver II (was Bronze on old ladder).
--
-- (2) BAL-06 — Weekly Battle Pass challenges
--     weekly_challenge_progress table: 5 rotating challenge slots per character
--     per ISO week. Deterministic pool selection seeded by ISO-week string, no
--     cron job. Each slot has a goal_type (QuestType enum), target, progress,
--     and a flat bp_xp_award. Claimed slots push BP XP through the same
--     awardBattlePassXp(tx, characterId, amount) path as dailies.
--
-- (3) IAP-02 — Premium Forever expansion
--     User.premium_gem_claim_date: one-per-UTC-day claim tracking for the
--     +25 gems/day Premium entitlement (paid in Daily Login claim handler).
--     TitleType enum + Character.active_title: cosmetic "Chosen" title for
--     Premium Forever holders. Enum-based so API can't accept arbitrary
--     strings. Premium +10% gold multiplier is applied at the END of the
--     reward stack (after CHA/streak/level) in code — no schema change.

-- (1) ELO tiers — no schema change, all in code.

-- (2) Weekly BP challenges
CREATE TABLE "weekly_challenge_progress" (
  "id" TEXT NOT NULL,
  "character_id" TEXT NOT NULL,
  "iso_week" TEXT NOT NULL,
  "slot_index" INTEGER NOT NULL,
  "goal_type" "QuestType" NOT NULL,
  "goal_target" INTEGER NOT NULL,
  "progress" INTEGER NOT NULL DEFAULT 0,
  "bp_xp_award" INTEGER NOT NULL,
  "claimed" BOOLEAN NOT NULL DEFAULT false,
  "completed_at" TIMESTAMP(3),
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "weekly_challenge_progress_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "weekly_challenge_progress_character_id_iso_week_slot_index_key"
  ON "weekly_challenge_progress" ("character_id", "iso_week", "slot_index");

CREATE INDEX "weekly_challenge_progress_character_id_iso_week_idx"
  ON "weekly_challenge_progress" ("character_id", "iso_week");

ALTER TABLE "weekly_challenge_progress"
  ADD CONSTRAINT "weekly_challenge_progress_character_id_fkey"
  FOREIGN KEY ("character_id") REFERENCES "characters" ("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

-- (3a) Premium Forever — +25 gems/day claim date
ALTER TABLE "users"
  ADD COLUMN "premium_gem_claim_date" TIMESTAMP(3);

-- (3b) Cosmetic title enum + Character.active_title
CREATE TYPE "TitleType" AS ENUM ('chosen');

ALTER TABLE "characters"
  ADD COLUMN "active_title" "TitleType";
