-- =============================================================================
-- 20261017_rogue_cunning_lifesteal
--
-- Balance audit 2026-10-16 §2: rogue was the only class with zero sustain
-- and zero %HP in its tree (tank 69% lifesteal, warrior 48%). Cunning — a
-- foundation node, +3%/rank damage as an "initiative" proxy — becomes
-- +3%/rank life steal. Topology and cost unchanged; players who own it keep
-- their ranks and get sustain instead of 3–9% damage.
--
-- Idempotent. Run against prod via Supabase MCP BEFORE deploying the backend.
-- =============================================================================

UPDATE "passive_nodes"
   SET "bonus_type" = 'lifesteal', "description" = '+3%/+6%/+9% Life Steal'
 WHERE "node_key" = 'rogue.found.cunning' AND "bonus_type" <> 'lifesteal';
