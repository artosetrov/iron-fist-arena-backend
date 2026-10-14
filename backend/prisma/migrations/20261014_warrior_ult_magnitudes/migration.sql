-- =============================================================================
-- 20261014_warrior_ult_magnitudes
--
-- The warrior v2 talent seed wrote its two ultimates as whole percentages
-- (60, 50) where every other class seeds fractions (rogue 1, mage 0.7,
-- tank 0.7). The strike handlers treat magnitude as a fraction:
--
--   applyBurstDamage(dmg, 60) = dmg × 61   -> guaranteed one-shot, once per match
--   applyShield(dmg, 50)      = 0          -> total immunity to one hit
--
-- Both for five talent points, at any level. The handlers now clamp to [0, 1]
-- as well, so a repeat of this seed mistake degrades to ×2 / full block instead
-- of ×61 / immunity — but the rows themselves still have to say what they mean.
--
-- Idempotent. Run against prod via Supabase MCP BEFORE deploying the backend.
-- =============================================================================

UPDATE "passive_nodes" SET "active_magnitude" = 0.6
 WHERE "node_key" = 'warrior.ult.unleash' AND "active_magnitude" > 1;

UPDATE "passive_nodes" SET "active_magnitude" = 0.5
 WHERE "node_key" = 'warrior.ult.champion' AND "active_magnitude" > 1;
