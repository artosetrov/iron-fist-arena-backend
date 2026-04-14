-- Interactive Combat v1 — Phase 3
-- Store both players' active-slot snapshot + per-slot cooldowns in the match,
-- so /strike can validate + fire actives without re-reading character_active_slots
-- (which can change mid-match if user equips from another device).
ALTER TABLE "pvp_matches" ADD COLUMN IF NOT EXISTS "interactive_actives" JSONB;
