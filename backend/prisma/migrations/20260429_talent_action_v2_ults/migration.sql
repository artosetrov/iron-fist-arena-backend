-- Talents v2 — 4 new TalentSlotAction values for Rogue/Mage/Tank ultimates.
-- Spec: docs/06_game_systems/SKILL_TREE_DESIGN_V2.md §8
--
-- Map (1v1 round-based):
--   stealth        → next attack auto-crits (Vanish, Rogue ult, CD 60s)
--   aoe_damage     → alias of burst_damage with distinct VFX (Cataclysm, Mage, CD 90s)
--   cooldown_reset → resets cooldown_remaining=0 for all OTHER non-consumable
--                    talent slots (Rewind, Mage, CD 180s)
--   aoe_stun       → stuns opponent for `magnitude` rounds, default 2
--                    (Quake, Tank, CD 120s)
--
-- IMPORTANT: apply via Supabase MCP BEFORE code deploy.
-- Reason: pvp/strike/route.ts will start sending these enum values; if the
-- Postgres type doesn't accept them yet, every ult-firing strike returns 500.
-- This bug bit us 3× before (Interactive Combat 04-13, Premium Pass, Stash).
--
-- Idempotent: IF NOT EXISTS guards make this safe to re-run on any environment.

ALTER TYPE "public"."TalentSlotAction" ADD VALUE IF NOT EXISTS 'stealth';
ALTER TYPE "public"."TalentSlotAction" ADD VALUE IF NOT EXISTS 'aoe_damage';
ALTER TYPE "public"."TalentSlotAction" ADD VALUE IF NOT EXISTS 'cooldown_reset';
ALTER TYPE "public"."TalentSlotAction" ADD VALUE IF NOT EXISTS 'aoe_stun';
