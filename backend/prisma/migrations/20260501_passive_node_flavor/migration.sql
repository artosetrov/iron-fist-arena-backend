-- =============================================================================
-- 20260501_passive_node_flavor
-- Adds optional `flavor` text column to passive_nodes for narrative prose.
-- The existing `description` column continues to hold the stat-effect string
-- (e.g. "+5%/+10%/+15% Damage"); `flavor` is new and intended for 1-2 sentence
-- in-world copy rendered below the effect chip in the iOS Talent detail modal.
-- =============================================================================

ALTER TABLE "passive_nodes" ADD COLUMN IF NOT EXISTS "flavor" TEXT;
