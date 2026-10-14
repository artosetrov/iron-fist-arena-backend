-- =============================================================================
-- 20261014_ticket_attacker_stance
--
-- Snapshot the attacker's combat stance on the PvP battle ticket at
-- /pvp/prepare, and fight with it at /pvp/resolve.
--
-- /prepare returns the opponent's persisted stance because the client replays
-- the fight locally; the server then re-ran the fight with the attacker's
-- LIVE stance. Prepare → read the opponent's stance → switch to the counter
-- (zone match/mismatch is fixed for the whole async fight) → resolve the same
-- ticket was an ~87% win rate at identical gear (2026-10-14 audit).
--
-- Nullable and additive; tickets issued before deploy resolve as before.
-- Run against prod via Supabase MCP BEFORE deploying the backend.
-- =============================================================================

ALTER TABLE "pvp_battle_tickets" ADD COLUMN IF NOT EXISTS "attacker_stance" JSONB;
