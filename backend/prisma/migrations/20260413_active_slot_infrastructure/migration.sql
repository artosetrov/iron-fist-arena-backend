-- Interactive Combat v1 — Phase 1: Active Slot infrastructure.
-- Additive-only. Safe to apply against prod with traffic.
-- Adds:
--   1) TalentSlotAction enum
--   2) 4 nullable columns on passive_nodes (active_action_type, active_cooldown,
--      active_magnitude, is_activatable DEFAULT false)
--   3) character_active_slots table with double-unique constraint
--      (character_id, slot_index) + (character_id, node_id)

DO $$ BEGIN
  CREATE TYPE "public"."TalentSlotAction" AS ENUM (
    'burst_damage',
    'heal_self',
    'shield_self',
    'stun_enemy',
    'execute'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE "public"."passive_nodes"
  ADD COLUMN IF NOT EXISTS "active_action_type" "public"."TalentSlotAction",
  ADD COLUMN IF NOT EXISTS "active_cooldown"    INTEGER,
  ADD COLUMN IF NOT EXISTS "active_magnitude"   DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS "is_activatable"     BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS "public"."character_active_slots" (
  "id"           TEXT        NOT NULL,
  "character_id" TEXT        NOT NULL,
  "node_id"      TEXT        NOT NULL,
  "slot_index"   INTEGER     NOT NULL,
  "equipped_at"  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "character_active_slots_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "character_active_slots_character_id_slot_index_key"
  ON "public"."character_active_slots" ("character_id", "slot_index");

CREATE UNIQUE INDEX IF NOT EXISTS "character_active_slots_character_id_node_id_key"
  ON "public"."character_active_slots" ("character_id", "node_id");

CREATE INDEX IF NOT EXISTS "character_active_slots_character_id_idx"
  ON "public"."character_active_slots" ("character_id");

DO $$ BEGIN
  ALTER TABLE "public"."character_active_slots"
    ADD CONSTRAINT "character_active_slots_character_id_fkey"
    FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "public"."character_active_slots"
    ADD CONSTRAINT "character_active_slots_node_id_fkey"
    FOREIGN KEY ("node_id") REFERENCES "public"."passive_nodes"("id") ON DELETE RESTRICT;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
