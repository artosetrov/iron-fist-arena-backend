-- Interactive Combat v1 — Phase 4.A: Active Slot consumables.
-- Extends character_active_slots so a slot can hold EITHER a passive-talent node
-- OR a consumable (Phase 4 scope: health potions only). Spec:
--   docs/02_product_and_features/ACTIVE_SKILL_PICKER_SPEC.md §4
--
-- Additive-and-reversible-ish against prod:
--   * Existing rows stay valid (all have node_id set). node_id just becomes NULL-able.
--   * We drop the non-partial UNIQUE(character_id, node_id) and replace it with a
--     partial version so multiple consumable rows (all with node_id IS NULL) are legal.
--   * CHECK enforces mutual exclusion: exactly one of (node_id, consumable_type) set.
--   * Partial UNIQUE on character_id WHERE consumable_type IS NOT NULL enforces the
--     "max 1 consumable per loadout" rule at the DB level (belt + suspenders vs. the
--     API guard).
--
-- Apply order:
--   1. Run this against prod via Supabase MCP BEFORE deploying backend code.
--   2. Then deploy backend.
--   3. Then run `python3 scripts/check_schema_drift.py` from local → must pass.

-- 1) node_id: drop NOT NULL.
ALTER TABLE "public"."character_active_slots"
  ALTER COLUMN "node_id" DROP NOT NULL;

-- 2) Add consumable_type nullable column.
ALTER TABLE "public"."character_active_slots"
  ADD COLUMN IF NOT EXISTS "consumable_type" "public"."ConsumableType";

-- 3) Mutual-exclusion CHECK — exactly one of (node_id, consumable_type) must be set.
DO $$ BEGIN
  ALTER TABLE "public"."character_active_slots"
    ADD CONSTRAINT "character_active_slots_exactly_one_kind_chk"
    CHECK (
      (("node_id" IS NOT NULL)::int + ("consumable_type" IS NOT NULL)::int) = 1
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 4) Replace the legacy UNIQUE(character_id, node_id) with a partial version.
--    Non-partial unique on a nullable column treats NULLs as distinct in Postgres,
--    so "technically" the old index would still allow multiple null rows — but we
--    want an index that only polices talent rows. Drop + recreate as partial.
DROP INDEX IF EXISTS "public"."character_active_slots_character_id_node_id_key";

CREATE UNIQUE INDEX IF NOT EXISTS "character_active_slots_character_id_node_id_unique"
  ON "public"."character_active_slots" ("character_id", "node_id")
  WHERE "node_id" IS NOT NULL;

-- 5) Enforce "at most 1 consumable per loadout" at the DB level.
--    Partial unique on JUST character_id (not character_id+consumable_type) — we
--    want the rule "one consumable total", not "one of each kind".
CREATE UNIQUE INDEX IF NOT EXISTS "character_active_slots_character_id_consumable_unique"
  ON "public"."character_active_slots" ("character_id")
  WHERE "consumable_type" IS NOT NULL;
