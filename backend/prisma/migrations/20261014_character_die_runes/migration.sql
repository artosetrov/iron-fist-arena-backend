-- 2026-10-14: Dice combat — runes socketed into dice faces.
-- Spec: docs/06_game_systems/DICE_RUNES_DESIGN.md §6. Idempotent.

CREATE TABLE IF NOT EXISTS "character_die_runes" (
  "id"           TEXT NOT NULL,
  "character_id" TEXT NOT NULL,
  "die"          TEXT NOT NULL,
  "face_index"   INTEGER NOT NULL,
  "rune_key"     TEXT NOT NULL,
  "updated_at"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "character_die_runes_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "character_die_runes_die_chk" CHECK ("die" IN ('atk', 'grd')),
  CONSTRAINT "character_die_runes_face_chk" CHECK ("face_index" BETWEEN 0 AND 5)
);

CREATE UNIQUE INDEX IF NOT EXISTS "character_die_runes_character_id_die_face_index_key"
  ON "character_die_runes" ("character_id", "die", "face_index");
CREATE UNIQUE INDEX IF NOT EXISTS "character_die_runes_character_id_rune_key_key"
  ON "character_die_runes" ("character_id", "rune_key");

DO $$ BEGIN
  ALTER TABLE "character_die_runes"
    ADD CONSTRAINT "character_die_runes_character_id_fkey"
    FOREIGN KEY ("character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
