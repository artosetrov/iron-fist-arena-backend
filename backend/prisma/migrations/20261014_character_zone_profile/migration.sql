-- =============================================================================
-- 20261014_character_zone_profile
--
-- Combat v2 (docs/06_game_systems/COMBAT_V2_DESIGN.md §4.1): a character's
-- recorded zone habits — what they attack and block in interactive combat,
-- conditioned on last round's exchange. /pvp/match/complete folds each match
-- into it; /pvp/strike plays it back as the defender's "ghost" in async PvP.
-- NULL = no rounds recorded yet (a stable bot personality is used instead).
--
-- Idempotent. Run against prod BEFORE deploying the backend.
-- =============================================================================

ALTER TABLE "characters" ADD COLUMN IF NOT EXISTS "zone_profile" JSONB;
