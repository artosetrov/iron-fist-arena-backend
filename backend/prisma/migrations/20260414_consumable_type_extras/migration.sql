-- Economy v3 Phase 2 (2026-04-14): Bundle extras
-- Adds protection_scroll and legendary_shard to ConsumableType.
-- Granted via Adventurer's Bundle IAP SKUs. Routes to the user's
-- most-recently-updated character (active char heuristic).

ALTER TYPE "ConsumableType" ADD VALUE IF NOT EXISTS 'protection_scroll';
ALTER TYPE "ConsumableType" ADD VALUE IF NOT EXISTS 'legendary_shard';
