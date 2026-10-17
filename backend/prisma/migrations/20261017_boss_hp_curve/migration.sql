-- =============================================================================
-- 20261017_boss_hp_curve
--
-- Balance audit 2026-10-16 §5. Boss HP was 120·level·mult; from levelReq 40
-- on, a level-appropriate hero never killed a boss before the 15-turn cap
-- (L50 mid gear vs the L50 dungeon: 10% wins, 100% timeouts). 70·level·mult
-- with the multiplier capped at 1.5 ends those fights by a kill in 8–12
-- rounds on the real engine. Damage/defense/speed take the same cap.
-- Also: clockwork_citadel / abyssal_depths / infernal_throne required levels
-- 55/60/65 against a level cap of 50 — thirty bosses nobody could reach.
--
-- Values are spelled out per boss (name + dungeon slug) so the statement is
-- idempotent and matches prisma/seed-dungeons.ts exactly.
-- Run against prod via Supabase MCP BEFORE deploying the backend.
-- =============================================================================

UPDATE "dungeon_bosses" b SET "hp" = 560, "damage" = 28, "defense" = 21, "speed" = 21 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'fungal_grotto' AND b."name" = 'Spore Sprite';
UPDATE "dungeon_bosses" b SET "hp" = 654, "damage" = 32, "defense" = 24, "speed" = 24 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'fungal_grotto' AND b."name" = 'Mushroom Brute';
UPDATE "dungeon_bosses" b SET "hp" = 756, "damage" = 36, "defense" = 27, "speed" = 27 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'fungal_grotto' AND b."name" = 'Vine Strangler';
UPDATE "dungeon_bosses" b SET "hp" = 798, "damage" = 38, "defense" = 28, "speed" = 28 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'fungal_grotto' AND b."name" = 'Poison Toad';
UPDATE "dungeon_bosses" b SET "hp" = 910, "damage" = 42, "defense" = 32, "speed" = 31 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'fungal_grotto' AND b."name" = 'Mycelium Golem';
UPDATE "dungeon_bosses" b SET "hp" = 956, "damage" = 45, "defense" = 34, "speed" = 33 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'fungal_grotto' AND b."name" = 'Rot Witch';
UPDATE "dungeon_bosses" b SET "hp" = 1078, "damage" = 50, "defense" = 37, "speed" = 37 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'fungal_grotto' AND b."name" = 'Fungal Hydra';
UPDATE "dungeon_bosses" b SET "hp" = 1208, "damage" = 55, "defense" = 41, "speed" = 40 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'fungal_grotto' AND b."name" = 'Sporeling Hive Mind';
UPDATE "dungeon_bosses" b SET "hp" = 1260, "damage" = 57, "defense" = 43, "speed" = 42 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'fungal_grotto' AND b."name" = 'Blight Treant';
UPDATE "dungeon_bosses" b SET "hp" = 1606, "damage" = 71, "defense" = 54, "speed" = 52 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'fungal_grotto' AND b."name" = 'The Overgrowth';
UPDATE "dungeon_bosses" b SET "hp" = 945, "damage" = 43, "defense" = 32, "speed" = 32 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'scorched_mines' AND b."name" = 'Ember Rat';
UPDATE "dungeon_bosses" b SET "hp" = 1064, "damage" = 48, "defense" = 36, "speed" = 35 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'scorched_mines' AND b."name" = 'Magma Slime';
UPDATE "dungeon_bosses" b SET "hp" = 1190, "damage" = 52, "defense" = 40, "speed" = 39 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'scorched_mines' AND b."name" = 'Mine Foreman';
UPDATE "dungeon_bosses" b SET "hp" = 1250, "damage" = 55, "defense" = 42, "speed" = 41 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'scorched_mines' AND b."name" = 'Lava Beetle';
UPDATE "dungeon_bosses" b SET "hp" = 1386, "damage" = 61, "defense" = 46, "speed" = 44 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'scorched_mines' AND b."name" = 'Cinder Elemental';
UPDATE "dungeon_bosses" b SET "hp" = 1449, "damage" = 63, "defense" = 48, "speed" = 46 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'scorched_mines' AND b."name" = 'Soot Dragon Whelp';
UPDATE "dungeon_bosses" b SET "hp" = 1596, "damage" = 69, "defense" = 53, "speed" = 51 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'scorched_mines' AND b."name" = 'Obsidian Guardian';
UPDATE "dungeon_bosses" b SET "hp" = 1750, "damage" = 75, "defense" = 58, "speed" = 55 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'scorched_mines' AND b."name" = 'Flame Witch';
UPDATE "dungeon_bosses" b SET "hp" = 1820, "damage" = 78, "defense" = 60, "speed" = 57 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'scorched_mines' AND b."name" = 'Infernal Siege Engine';
UPDATE "dungeon_bosses" b SET "hp" = 2233, "damage" = 94, "defense" = 72, "speed" = 69 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'scorched_mines' AND b."name" = 'Pyrax the Molten King';
UPDATE "dungeon_bosses" b SET "hp" = 1400, "damage" = 60, "defense" = 46, "speed" = 44 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'frozen_abyss' AND b."name" = 'Frost Wisp';
UPDATE "dungeon_bosses" b SET "hp" = 1544, "damage" = 66, "defense" = 50, "speed" = 48 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'frozen_abyss' AND b."name" = 'Ice Wolf';
UPDATE "dungeon_bosses" b SET "hp" = 1694, "damage" = 72, "defense" = 55, "speed" = 52 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'frozen_abyss' AND b."name" = 'Glacier Troll';
UPDATE "dungeon_bosses" b SET "hp" = 1771, "damage" = 75, "defense" = 57, "speed" = 55 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'frozen_abyss' AND b."name" = 'Frozen Sentinel';
UPDATE "dungeon_bosses" b SET "hp" = 1932, "damage" = 81, "defense" = 62, "speed" = 59 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'frozen_abyss' AND b."name" = 'Blizzard Harpy';
UPDATE "dungeon_bosses" b SET "hp" = 2012, "damage" = 84, "defense" = 65, "speed" = 62 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'frozen_abyss' AND b."name" = 'Crystal Golem';
UPDATE "dungeon_bosses" b SET "hp" = 2184, "damage" = 91, "defense" = 70, "speed" = 67 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'frozen_abyss' AND b."name" = 'Frost Wyvern';
UPDATE "dungeon_bosses" b SET "hp" = 2362, "damage" = 98, "defense" = 76, "speed" = 72 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'frozen_abyss' AND b."name" = 'Ice Lich';
UPDATE "dungeon_bosses" b SET "hp" = 2450, "damage" = 102, "defense" = 78, "speed" = 74 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'frozen_abyss' AND b."name" = 'Permafrost Colossus';
UPDATE "dungeon_bosses" b SET "hp" = 2835, "damage" = 116, "defense" = 90, "speed" = 85 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'frozen_abyss' AND b."name" = 'Glacius the Eternal';
UPDATE "dungeon_bosses" b SET "hp" = 1925, "damage" = 80, "defense" = 62, "speed" = 58 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'realm_of_light' AND b."name" = 'Light Sprite';
UPDATE "dungeon_bosses" b SET "hp" = 2093, "damage" = 86, "defense" = 67, "speed" = 63 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'realm_of_light' AND b."name" = 'Radiant Archer';
UPDATE "dungeon_bosses" b SET "hp" = 2268, "damage" = 93, "defense" = 72, "speed" = 68 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'realm_of_light' AND b."name" = 'Crystal Beast';
UPDATE "dungeon_bosses" b SET "hp" = 2362, "damage" = 97, "defense" = 75, "speed" = 71 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'realm_of_light' AND b."name" = 'Solar Monk';
UPDATE "dungeon_bosses" b SET "hp" = 2548, "damage" = 104, "defense" = 81, "speed" = 76 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'realm_of_light' AND b."name" = 'Golden Golem';
UPDATE "dungeon_bosses" b SET "hp" = 2646, "damage" = 108, "defense" = 84, "speed" = 79 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'realm_of_light' AND b."name" = 'Seraph Guardian';
UPDATE "dungeon_bosses" b SET "hp" = 2842, "damage" = 115, "defense" = 90, "speed" = 84 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'realm_of_light' AND b."name" = 'Prism Dragon';
UPDATE "dungeon_bosses" b SET "hp" = 3045, "damage" = 123, "defense" = 96, "speed" = 90 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'realm_of_light' AND b."name" = 'Light Weaver';
UPDATE "dungeon_bosses" b SET "hp" = 3150, "damage" = 128, "defense" = 99, "speed" = 93 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'realm_of_light' AND b."name" = 'Solar Colossus';
UPDATE "dungeon_bosses" b SET "hp" = 3360, "damage" = 135, "defense" = 105, "speed" = 98 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'realm_of_light' AND b."name" = 'The Heart of the Ray';
UPDATE "dungeon_bosses" b SET "hp" = 2520, "damage" = 102, "defense" = 79, "speed" = 74 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'shadow_realm' AND b."name" = 'Shadow Wisp';
UPDATE "dungeon_bosses" b SET "hp" = 2712, "damage" = 109, "defense" = 85, "speed" = 80 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'shadow_realm' AND b."name" = 'Dark Stalker';
UPDATE "dungeon_bosses" b SET "hp" = 2912, "damage" = 117, "defense" = 91, "speed" = 85 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'shadow_realm' AND b."name" = 'Void Spider';
UPDATE "dungeon_bosses" b SET "hp" = 3024, "damage" = 122, "defense" = 94, "speed" = 89 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'shadow_realm' AND b."name" = 'Shade Knight';
UPDATE "dungeon_bosses" b SET "hp" = 3234, "damage" = 130, "defense" = 101, "speed" = 94 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'shadow_realm' AND b."name" = 'Eclipse Wolf';
UPDATE "dungeon_bosses" b SET "hp" = 3350, "damage" = 134, "defense" = 104, "speed" = 98 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'shadow_realm' AND b."name" = 'Nightborne Mage';
UPDATE "dungeon_bosses" b SET "hp" = 3570, "damage" = 142, "defense" = 111, "speed" = 104 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'shadow_realm' AND b."name" = 'Abyss Hydra';
UPDATE "dungeon_bosses" b SET "hp" = 3675, "damage" = 146, "defense" = 114, "speed" = 106 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'shadow_realm' AND b."name" = 'Shadow Dragon';
UPDATE "dungeon_bosses" b SET "hp" = 3675, "damage" = 146, "defense" = 114, "speed" = 106 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'shadow_realm' AND b."name" = 'Void Colossus';
UPDATE "dungeon_bosses" b SET "hp" = 3885, "damage" = 154, "defense" = 120, "speed" = 112 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'shadow_realm' AND b."name" = 'The Whispering Dark';
UPDATE "dungeon_bosses" b SET "hp" = 3185, "damage" = 127, "defense" = 99, "speed" = 92 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'clockwork_citadel' AND b."name" = 'Gear Sprite';
UPDATE "dungeon_bosses" b SET "hp" = 3402, "damage" = 135, "defense" = 105, "speed" = 98 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'clockwork_citadel' AND b."name" = 'Clockwork Hound';
UPDATE "dungeon_bosses" b SET "hp" = 3626, "damage" = 144, "defense" = 112, "speed" = 104 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'clockwork_citadel' AND b."name" = 'Piston Golem';
UPDATE "dungeon_bosses" b SET "hp" = 3756, "damage" = 149, "defense" = 116, "speed" = 108 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'clockwork_citadel' AND b."name" = 'Sawblade Dancer';
UPDATE "dungeon_bosses" b SET "hp" = 3990, "damage" = 158, "defense" = 123, "speed" = 115 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'clockwork_citadel' AND b."name" = 'Tesla Turret';
UPDATE "dungeon_bosses" b SET "hp" = 3990, "damage" = 158, "defense" = 123, "speed" = 115 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'clockwork_citadel' AND b."name" = 'Steam Knight';
UPDATE "dungeon_bosses" b SET "hp" = 4095, "damage" = 161, "defense" = 126, "speed" = 117 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'clockwork_citadel' AND b."name" = 'Gear Dragon';
UPDATE "dungeon_bosses" b SET "hp" = 4200, "damage" = 165, "defense" = 129, "speed" = 120 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'clockwork_citadel' AND b."name" = 'Grand Mechanist';
UPDATE "dungeon_bosses" b SET "hp" = 4200, "damage" = 165, "defense" = 129, "speed" = 120 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'clockwork_citadel' AND b."name" = 'Siege Automaton';
UPDATE "dungeon_bosses" b SET "hp" = 4410, "damage" = 172, "defense" = 135, "speed" = 125 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'clockwork_citadel' AND b."name" = 'The Grand Engine';
UPDATE "dungeon_bosses" b SET "hp" = 3920, "damage" = 154, "defense" = 120, "speed" = 112 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'abyssal_depths' AND b."name" = 'Depth Crawler';
UPDATE "dungeon_bosses" b SET "hp" = 4162, "damage" = 163, "defense" = 128, "speed" = 119 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'abyssal_depths' AND b."name" = 'Angler Horror';
UPDATE "dungeon_bosses" b SET "hp" = 4410, "damage" = 172, "defense" = 135, "speed" = 125 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'abyssal_depths' AND b."name" = 'Coral Golem';
UPDATE "dungeon_bosses" b SET "hp" = 4410, "damage" = 172, "defense" = 135, "speed" = 125 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'abyssal_depths' AND b."name" = 'Siren';
UPDATE "dungeon_bosses" b SET "hp" = 4515, "damage" = 176, "defense" = 138, "speed" = 128 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'abyssal_depths' AND b."name" = 'Kraken Spawn';
UPDATE "dungeon_bosses" b SET "hp" = 4515, "damage" = 176, "defense" = 138, "speed" = 128 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'abyssal_depths' AND b."name" = 'Abyssal Leviathan';
UPDATE "dungeon_bosses" b SET "hp" = 4620, "damage" = 180, "defense" = 141, "speed" = 131 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'abyssal_depths' AND b."name" = 'Deep Sea Dragon';
UPDATE "dungeon_bosses" b SET "hp" = 4725, "damage" = 184, "defense" = 144, "speed" = 134 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'abyssal_depths' AND b."name" = 'Drowned Admiral';
UPDATE "dungeon_bosses" b SET "hp" = 4725, "damage" = 184, "defense" = 144, "speed" = 134 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'abyssal_depths' AND b."name" = 'Tidal Colossus';
UPDATE "dungeon_bosses" b SET "hp" = 4935, "damage" = 191, "defense" = 150, "speed" = 139 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'abyssal_depths' AND b."name" = 'Charybdis the Devourer';
UPDATE "dungeon_bosses" b SET "hp" = 4725, "damage" = 184, "defense" = 144, "speed" = 134 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'infernal_throne' AND b."name" = 'Imp Swarm';
UPDATE "dungeon_bosses" b SET "hp" = 4830, "damage" = 188, "defense" = 147, "speed" = 136 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'infernal_throne' AND b."name" = 'Hellhound Alpha';
UPDATE "dungeon_bosses" b SET "hp" = 4935, "damage" = 191, "defense" = 150, "speed" = 139 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'infernal_throne' AND b."name" = 'Flame Demoness';
UPDATE "dungeon_bosses" b SET "hp" = 4935, "damage" = 191, "defense" = 150, "speed" = 139 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'infernal_throne' AND b."name" = 'Iron Demon';
UPDATE "dungeon_bosses" b SET "hp" = 5040, "damage" = 195, "defense" = 153, "speed" = 142 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'infernal_throne' AND b."name" = 'Pit Fiend';
UPDATE "dungeon_bosses" b SET "hp" = 5040, "damage" = 195, "defense" = 153, "speed" = 142 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'infernal_throne' AND b."name" = 'Soul Reaver';
UPDATE "dungeon_bosses" b SET "hp" = 5145, "damage" = 199, "defense" = 156, "speed" = 144 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'infernal_throne' AND b."name" = 'Infernal Dragon';
UPDATE "dungeon_bosses" b SET "hp" = 5250, "damage" = 202, "defense" = 159, "speed" = 147 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'infernal_throne' AND b."name" = 'Dark Seraph';
UPDATE "dungeon_bosses" b SET "hp" = 5250, "damage" = 202, "defense" = 159, "speed" = 147 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'infernal_throne' AND b."name" = 'The Throne Guardian';
UPDATE "dungeon_bosses" b SET "hp" = 5460, "damage" = 210, "defense" = 165, "speed" = 152 FROM "dungeons" d WHERE b."dungeon_id" = d."id" AND d."slug" = 'infernal_throne' AND b."name" = 'Archfiend Malachar';

UPDATE "dungeons" SET "level_req" = 42 WHERE "slug" = 'clockwork_citadel' AND "level_req" = 55;
UPDATE "dungeons" SET "level_req" = 46 WHERE "slug" = 'abyssal_depths' AND "level_req" = 60;
UPDATE "dungeons" SET "level_req" = 50 WHERE "slug" = 'infernal_throne' AND "level_req" = 65;
