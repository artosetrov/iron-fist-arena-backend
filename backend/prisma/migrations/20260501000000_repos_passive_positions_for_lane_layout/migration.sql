-- 20260501000000_repos_passive_positions_for_lane_layout
--
-- Re-positions every Talents v2 passive node onto a clean lane-based grid
-- so the iOS Talents tab can render WoW-style: foundation strip on top,
-- 3-or-4 archetype columns below, keystones and ultimates centered at the
-- bottom. No schema change. Idempotent — safe to re-run.
--
-- Grid (all four classes share the same skeleton):
--   X step 80bp, Y step 80bp.
--   Foundation row:  y=0,   x ∈ {0, 80, 160, 240, 320, 400}  (6 cells)
--   Archetype lanes: y={80, 160, 240}
--     • 3-lane classes (Rogue, Mage, Tank): x ∈ {120, 200, 280}  ← centered under foundation, 80bp tight
--     • Warrior (crus splits into 2 sub-paths → 4 cols): x ∈ {80, 160, 240, 320}
--   Keystones:       y=320,
--     • 3-lane classes: x ∈ {120, 200, 280}
--     • Warrior: x ∈ {80, 200, 320}
--   Ultimates:       y=400,
--     • 3-lane classes: x ∈ {160, 240}
--     • Warrior: x ∈ {80, 200}
--
-- Y is inverted vs the prior 1400×600 world canvas (foundation was y=520,
-- ultimate was y=20). Connections are undirected so unlock logic is
-- unaffected. iOS sortedYs ordering naturally puts foundation at top.

BEGIN;

-- ============================================================
-- WARRIOR (23 nodes, 4 archetype columns due to crus split)
-- ============================================================
UPDATE passive_nodes SET position_x =   0, position_y =   0 WHERE node_key = 'warrior.found.vitality';
UPDATE passive_nodes SET position_x =  80, position_y =   0 WHERE node_key = 'warrior.found.iron_skin';
UPDATE passive_nodes SET position_x = 160, position_y =   0 WHERE node_key = 'warrior.found.wards';
UPDATE passive_nodes SET position_x = 240, position_y =   0 WHERE node_key = 'warrior.found.critical_eye';
UPDATE passive_nodes SET position_x = 320, position_y =   0 WHERE node_key = 'warrior.found.swift_resolve';
UPDATE passive_nodes SET position_x = 400, position_y =   0 WHERE node_key = 'warrior.found.lifesteal';

-- Berserk lane (col 1, x=80)
UPDATE passive_nodes SET position_x =  80, position_y =  80 WHERE node_key = 'warrior.berserk.rage';
UPDATE passive_nodes SET position_x =  80, position_y = 160 WHERE node_key = 'warrior.berserk.momentum';
UPDATE passive_nodes SET position_x =  80, position_y = 240 WHERE node_key = 'warrior.berserk.bloodlust';

-- Crusader-A (Faith) lane (col 2, x=160)
UPDATE passive_nodes SET position_x = 160, position_y =  80 WHERE node_key = 'warrior.crus.iron_will';
UPDATE passive_nodes SET position_x = 160, position_y = 160 WHERE node_key = 'warrior.crus.retribution';
UPDATE passive_nodes SET position_x = 160, position_y = 240 WHERE node_key = 'warrior.crus.sanctified';

-- Crusader-B (Resilience) lane (col 3, x=240)
UPDATE passive_nodes SET position_x = 240, position_y =  80 WHERE node_key = 'warrior.crus.fortitude';
UPDATE passive_nodes SET position_x = 240, position_y = 160 WHERE node_key = 'warrior.crus.second_wind';
UPDATE passive_nodes SET position_x = 240, position_y = 240 WHERE node_key = 'warrior.crus.aegis';

-- Execute lane (col 4, x=320)
UPDATE passive_nodes SET position_x = 320, position_y =  80 WHERE node_key = 'warrior.exec.ruthless';
UPDATE passive_nodes SET position_x = 320, position_y = 160 WHERE node_key = 'warrior.exec.execute';
UPDATE passive_nodes SET position_x = 320, position_y = 240 WHERE node_key = 'warrior.exec.decapitate';

-- Keystones (Frenzy=berserk, Bulwark=crus center, Headsman=execute)
UPDATE passive_nodes SET position_x =  80, position_y = 320 WHERE node_key = 'warrior.key.frenzy';
UPDATE passive_nodes SET position_x = 200, position_y = 320 WHERE node_key = 'warrior.key.bulwark';
UPDATE passive_nodes SET position_x = 320, position_y = 320 WHERE node_key = 'warrior.key.headsman';

-- Ultimates (Unleash from frenzy, Champion from bulwark; headsman has no ult)
UPDATE passive_nodes SET position_x =  80, position_y = 400 WHERE node_key = 'warrior.ult.unleash';
UPDATE passive_nodes SET position_x = 200, position_y = 400 WHERE node_key = 'warrior.ult.champion';

-- ============================================================
-- ROGUE (20 nodes, 3 lanes: Assassin / Duelist / Saboteur)
-- ============================================================
UPDATE passive_nodes SET position_x =   0, position_y =   0 WHERE node_key = 'rogue.found.agility';
UPDATE passive_nodes SET position_x =  80, position_y =   0 WHERE node_key = 'rogue.found.precision';
UPDATE passive_nodes SET position_x = 160, position_y =   0 WHERE node_key = 'rogue.found.shadows';
UPDATE passive_nodes SET position_x = 240, position_y =   0 WHERE node_key = 'rogue.found.venom';
UPDATE passive_nodes SET position_x = 320, position_y =   0 WHERE node_key = 'rogue.found.swiftness';
UPDATE passive_nodes SET position_x = 400, position_y =   0 WHERE node_key = 'rogue.found.cunning';

-- Assassin lane
UPDATE passive_nodes SET position_x = 120, position_y =  80 WHERE node_key = 'rogue.asn.backstab';
UPDATE passive_nodes SET position_x = 120, position_y = 160 WHERE node_key = 'rogue.asn.bleed';
UPDATE passive_nodes SET position_x = 120, position_y = 240 WHERE node_key = 'rogue.asn.deep_cut';

-- Duelist lane
UPDATE passive_nodes SET position_x = 200, position_y =  80 WHERE node_key = 'rogue.duel.parry';
UPDATE passive_nodes SET position_x = 200, position_y = 160 WHERE node_key = 'rogue.duel.riposte';
UPDATE passive_nodes SET position_x = 200, position_y = 240 WHERE node_key = 'rogue.duel.finesse';

-- Saboteur lane
UPDATE passive_nodes SET position_x = 280, position_y =  80 WHERE node_key = 'rogue.sab.toxin';
UPDATE passive_nodes SET position_x = 280, position_y = 160 WHERE node_key = 'rogue.sab.paralyze';
UPDATE passive_nodes SET position_x = 280, position_y = 240 WHERE node_key = 'rogue.sab.weaken';

-- Keystones
UPDATE passive_nodes SET position_x = 120, position_y = 320 WHERE node_key = 'rogue.key.shadowstrike';
UPDATE passive_nodes SET position_x = 200, position_y = 320 WHERE node_key = 'rogue.key.riposte_master';
UPDATE passive_nodes SET position_x = 280, position_y = 320 WHERE node_key = 'rogue.key.envenom';

-- Ultimates
UPDATE passive_nodes SET position_x = 160, position_y = 400 WHERE node_key = 'rogue.ult.vanish';
UPDATE passive_nodes SET position_x = 240, position_y = 400 WHERE node_key = 'rogue.ult.shadow_reaper';

-- ============================================================
-- MAGE (20 nodes, 3 lanes: Pyromancer / Arcanist / Cryomancer)
-- ============================================================
UPDATE passive_nodes SET position_x =   0, position_y =   0 WHERE node_key = 'mage.found.intellect';
UPDATE passive_nodes SET position_x =  80, position_y =   0 WHERE node_key = 'mage.found.mana_pool';
UPDATE passive_nodes SET position_x = 160, position_y =   0 WHERE node_key = 'mage.found.focus';
UPDATE passive_nodes SET position_x = 240, position_y =   0 WHERE node_key = 'mage.found.resonance';
UPDATE passive_nodes SET position_x = 320, position_y =   0 WHERE node_key = 'mage.found.arcane_armor';
UPDATE passive_nodes SET position_x = 400, position_y =   0 WHERE node_key = 'mage.found.ward';

-- Pyro lane
UPDATE passive_nodes SET position_x = 120, position_y =  80 WHERE node_key = 'mage.pyro.kindle';
UPDATE passive_nodes SET position_x = 120, position_y = 160 WHERE node_key = 'mage.pyro.conflagration';
UPDATE passive_nodes SET position_x = 120, position_y = 240 WHERE node_key = 'mage.pyro.inferno';

-- Arcane lane
UPDATE passive_nodes SET position_x = 200, position_y =  80 WHERE node_key = 'mage.arc.focus_flow';
UPDATE passive_nodes SET position_x = 200, position_y = 160 WHERE node_key = 'mage.arc.arcane_might';
UPDATE passive_nodes SET position_x = 200, position_y = 240 WHERE node_key = 'mage.arc.chronomancy';

-- Cryo lane
UPDATE passive_nodes SET position_x = 280, position_y =  80 WHERE node_key = 'mage.cryo.frost';
UPDATE passive_nodes SET position_x = 280, position_y = 160 WHERE node_key = 'mage.cryo.freeze';
UPDATE passive_nodes SET position_x = 280, position_y = 240 WHERE node_key = 'mage.cryo.glacial';

-- Keystones
UPDATE passive_nodes SET position_x = 120, position_y = 320 WHERE node_key = 'mage.key.ignite';
UPDATE passive_nodes SET position_x = 200, position_y = 320 WHERE node_key = 'mage.key.manaflow';
UPDATE passive_nodes SET position_x = 280, position_y = 320 WHERE node_key = 'mage.key.frostbite';

-- Ultimates
UPDATE passive_nodes SET position_x = 160, position_y = 400 WHERE node_key = 'mage.ult.meteor';
UPDATE passive_nodes SET position_x = 240, position_y = 400 WHERE node_key = 'mage.ult.timewarp';

-- ============================================================
-- TANK (20 nodes, 3 lanes: Protector / Warder / Juggernaut)
-- ============================================================
UPDATE passive_nodes SET position_x =   0, position_y =   0 WHERE node_key = 'tank.found.stoneform';
UPDATE passive_nodes SET position_x =  80, position_y =   0 WHERE node_key = 'tank.found.plate';
UPDATE passive_nodes SET position_x = 160, position_y =   0 WHERE node_key = 'tank.found.resilience';
UPDATE passive_nodes SET position_x = 240, position_y =   0 WHERE node_key = 'tank.found.rebuke';
UPDATE passive_nodes SET position_x = 320, position_y =   0 WHERE node_key = 'tank.found.stability';
UPDATE passive_nodes SET position_x = 400, position_y =   0 WHERE node_key = 'tank.found.vigor';

-- Protector lane
UPDATE passive_nodes SET position_x = 120, position_y =  80 WHERE node_key = 'tank.prot.cleave';
UPDATE passive_nodes SET position_x = 120, position_y = 160 WHERE node_key = 'tank.prot.challenge';
UPDATE passive_nodes SET position_x = 120, position_y = 240 WHERE node_key = 'tank.prot.retaliation';

-- Warder lane
UPDATE passive_nodes SET position_x = 200, position_y =  80 WHERE node_key = 'tank.ward.shield';
UPDATE passive_nodes SET position_x = 200, position_y = 160 WHERE node_key = 'tank.ward.reflect';
UPDATE passive_nodes SET position_x = 200, position_y = 240 WHERE node_key = 'tank.ward.absolution';

-- Juggernaut lane
UPDATE passive_nodes SET position_x = 280, position_y =  80 WHERE node_key = 'tank.jug.fortify';
UPDATE passive_nodes SET position_x = 280, position_y = 160 WHERE node_key = 'tank.jug.immovable';
UPDATE passive_nodes SET position_x = 280, position_y = 240 WHERE node_key = 'tank.jug.unbreakable';

-- Keystones
UPDATE passive_nodes SET position_x = 120, position_y = 320 WHERE node_key = 'tank.key.taunt';
UPDATE passive_nodes SET position_x = 200, position_y = 320 WHERE node_key = 'tank.key.aegis_wall';
UPDATE passive_nodes SET position_x = 280, position_y = 320 WHERE node_key = 'tank.key.unstoppable';

-- Ultimates
UPDATE passive_nodes SET position_x = 160, position_y = 400 WHERE node_key = 'tank.ult.fortress';
UPDATE passive_nodes SET position_x = 240, position_y = 400 WHERE node_key = 'tank.ult.earthshatter';

-- ============================================================
-- Cache invalidation: bump cacheKey from `passives:tree:v3` to v4
-- on next deploy via /lib/cache TTL expiry. No-op here.
-- ============================================================

COMMIT;

-- ---------------------------------------------------------------------------
-- Sanity check (manual, run after migration):
--
-- SELECT class_restriction, COUNT(*),
--        MIN(position_x), MAX(position_x), MIN(position_y), MAX(position_y)
-- FROM passive_nodes
-- WHERE node_key LIKE '%.v2.%' OR node_key SIMILAR TO '(warrior|rogue|mage|tank)\.%'
-- GROUP BY class_restriction
-- ORDER BY class_restriction;
--
-- Expected: 4 rows, each with x∈[0,400], y∈[0,400].
-- ---------------------------------------------------------------------------
