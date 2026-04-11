-- Loot Relevance v1 — per-character counters for gear-aware loot and shard fallback
--
-- Adds fields to support the new loot system:
--
--   * trash_loot_streak
--     Increments every time a drop is filtered out as "irrelevant" (wrong class,
--     worse than currently equipped at alpha=0.9, lower rarity than worn). Pity
--     thresholds bump drop rarity at 5/10/15 streaks. Resets to 0 on any accepted
--     drop. See backend/src/lib/game/loot.ts (Phase 5).
--
--   * shards_common / shards_rare / shards_epic / shards_legendary
--     Shard currency awarded instead of items when the loot roll can't find any
--     relevant/equippable item (all filters rejected). Four tiers map to the
--     four meaningful rarity sinks — common converts from rejected common/uncommon,
--     rare from rare, epic from epic, legendary from legendary. Used to craft or
--     upgrade future drops. See backend/src/lib/game/loot.ts (Phase 6).
--
-- All columns default-0 so existing characters continue to work.

-- AlterTable
ALTER TABLE "characters"
  ADD COLUMN "trash_loot_streak"  INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN "shards_common"      INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN "shards_rare"        INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN "shards_epic"        INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN "shards_legendary"   INTEGER NOT NULL DEFAULT 0;
