#!/usr/bin/env python3
"""
gen_dungeons_sql.py — One-shot generator for the dungeon seed migration.

Mirrors backend/prisma/seed-dungeons.ts. Output is printed to stdout and
should be pasted into the .sql migration. This script is intentionally
NOT part of the runtime path — it is a source-of-truth-sync tool.

When seed-dungeons.ts is edited, re-run this to regenerate the SQL.
"""

# Formulas from seed-dungeons.ts
def calc_hp(level, mult):       return round(120 * level * mult)
def calc_damage(level, mult):   return round((10 + level * 2.5) * mult)
def calc_defense(level, mult):  return round((6 + level * 2) * mult)
def calc_speed(level, mult):    return round((8 + level * 1.8) * mult)


ABILITY_CATALOG = {
    'crushing_blow':   ('Crushing Blow',    'physical', 220, 4, 'armor_break_30',           'Heavy strike that breaks armor. High physical damage, -30% armor for one hit.'),
    'tail_swipe':      ('Tail Swipe',       'physical', 140, 3, '2_hits',                   'Double tail strike. Two quick hits with medium multiplier.'),
    'frenzy':          ('Frenzy',           'physical', 120, 5, '3_hits',                   'Series of three quick strikes. Less per hit, high total damage.'),
    'ground_slam':     ('Ground Slam',      'physical', 250, 5, 'stun_25_1t',               'Ground pound, stuns nearby. High damage, 25% stun chance for 1 turn.'),
    'impale':          ('Impale',           'physical', 200, 4, 'bleed_35_3t',              'Precise thrust causing bleeding. Good damage, 35% bleed for 3 turns.'),
    'charge':          ('Charge',           'physical', 280, 6, 'first_strike_only',        'Forward rush. Very high damage, only if boss acts first in turn.'),
    'rend':            ('Rend',             'physical', 160, 3, 'bleed_40_3t_crit_10',      'Tearing attack with enhanced crit. Medium damage, 40% bleed 3t, +10% crit.'),
    'shadow_bolt':     ('Shadow Bolt',      'magical',  240, 3, 'weaken_20_2t',             'Dark projectile. High magical damage, 20% weaken for 2 turns.'),
    'frost_breath':    ('Frost Breath',     'magical',  200, 4, 'slow_30_2t',               'Cold breath. Magical damage, 30% slow for 2 turns.'),
    'fire_wave':       ('Fire Wave',        'magical',  180, 4, '2_hits_burn_25_3t',        'Double fire wave. Two magical hits, 25% burn for 3 turns.'),
    'poison_cloud':    ('Poison Cloud',     'magical',  140, 5, 'poison_45_4t',             'Poison cloud. Medium magical damage, 45% poison for 4 turns.'),
    'life_drain':      ('Life Drain',       'magical',  200, 5, 'boss_regen_100_2t',        'Drains life and heals boss. Damage to target + 100% boss regen for 2 turns.'),
    'chain_lightning': ('Chain Lightning',  'magical',  150, 5, '3_hits_stun_15_1t',        'Lightning strikes multiple times. Three magical hits, 15% stun for 1 turn.'),
    'arcane_burst':    ('Arcane Burst',     'magical',  320, 6, 'none',                     'One massive magical explosion. Very high magical damage, no extra effects.'),
    'enrage':          ('Enrage',           'buff',       0, 7, 'str_35',                   'Boss enters rage, boosting strength. +35% STR self.'),
    'stone_skin':      ('Stone Skin',       'buff',       0, 6, 'armor_60',                 'Skin hardens like stone. +60% armor for several turns.'),
    'dark_shield':     ('Dark Shield',      'buff',       0, 6, 'magic_resist_50',          'Dark protection. +50% magic resistance.'),
    'regeneration':    ('Regeneration',     'buff',       0, 7, 'regen_8',                  'Activates health recovery. +8% boss regeneration.'),
    'battle_roar':     ('Battle Roar',      'buff',       0, 6, 'str_20_stun_20_1t',        'Deafening roar: buff boss and fear target. +20% STR self, 20% stun 1t.'),
    'haste':           ('Haste',            'buff',       0, 7, 'dodge_35_3t',              'Sharp speed increase. +35% dodge for boss for 3 turns.'),
}


DUNGEONS = [
    ('fungal_grotto', 'Fungal Grotto', 'The spores whisper secrets', 30, 14, 3, [
        ('Spore Sprite',       'Tiny, glowing, toxic.',                                    10, 0.80, 'assassin',  ['poison_cloud','haste','tail_swipe']),
        ('Mushroom Brute',     'Thick cap. Thicker skull.',                                11, 0.85, 'aggressive',['ground_slam','stone_skin','enrage']),
        ('Vine Strangler',     'Wraps around legs. Squeezes.',                             12, 0.90, 'berserker', ['rend','poison_cloud','crushing_blow']),
        ('Poison Toad',        'One lick and you see colors.',                             12, 0.95, 'defensive', ['poison_cloud','tail_swipe','regeneration']),
        ('Mycelium Golem',     'A walking ecosystem.',                                     13, 1.00, 'tank',      ['ground_slam','regeneration','stone_skin']),
        ('Rot Witch',          'Brews potions from decay.',                                13, 1.05, 'defensive', ['poison_cloud','life_drain','dark_shield']),
        ('Fungal Hydra',       'Cut one head — two sprout. Covered in mold.',              14, 1.10, 'berserker', ['frenzy','poison_cloud','regeneration']),
        ('Sporeling Hive Mind','Thousands of tiny spores, one terrible will.',             15, 1.15, 'defensive', ['chain_lightning','poison_cloud','dark_shield']),
        ('Blight Treant',      'The ancient tree fell to corruption.',                     15, 1.20, 'aggressive',['crushing_blow','regeneration','enrage']),
        ('The Overgrowth',     'The grotto itself fights back.',                           17, 1.35, 'berserker', ['frenzy','poison_cloud','regeneration']),
    ]),
    ('scorched_mines', 'Scorched Mines', 'Heat rises from below', 35, 16, 4, [
        ('Ember Rat',               'Fast, burning, bites.',                              15, 0.90, 'assassin',  ['fire_wave','haste','rend']),
        ('Magma Slime',             'Bubbles and burns everything it touches.',            16, 0.95, 'defensive', ['fire_wave','regeneration','stone_skin']),
        ('Mine Foreman',            'Swings a red-hot pickaxe.',                          17, 1.00, 'aggressive',['crushing_blow','enrage','impale']),
        ('Lava Beetle',             'Its shell is molten rock.',                          17, 1.05, 'tank',      ['fire_wave','stone_skin','charge']),
        ('Cinder Elemental',        'Pure fire given hateful form.',                       18, 1.10, 'aggressive',['fire_wave','arcane_burst','enrage']),
        ('Soot Dragon Whelp',       'Not full-grown. Still very hot.',                    18, 1.15, 'berserker', ['fire_wave','tail_swipe','frenzy']),
        ('Obsidian Guardian',       'Ancient golem fused from volcanic glass.',            19, 1.20, 'tank',      ['ground_slam','stone_skin','crushing_blow']),
        ('Flame Witch',             'Dances through fire. Controls it.',                  20, 1.25, 'defensive', ['fire_wave','arcane_burst','dark_shield']),
        ('Infernal Siege Engine',   'A mining machine possessed by fire spirits.',         20, 1.30, 'aggressive',['fire_wave','crushing_blow','enrage']),
        ('Pyrax the Molten King',   'The mines bow to him. So does the lava.',            22, 1.45, 'berserker', ['fire_wave','enrage','frenzy']),
    ]),
    ('frozen_abyss', 'Frozen Abyss', 'Where even fire freezes', 40, 18, 5, [
        ('Frost Wisp',             'A floating shard of cold.',                           20, 1.00, 'assassin',  ['frost_breath','haste','shadow_bolt']),
        ('Ice Wolf',               'Hunts in frozen packs.',                              21, 1.05, 'berserker', ['rend','frost_breath','charge']),
        ('Glacier Troll',          'Covered in ice. Hits like an avalanche.',             22, 1.10, 'tank',      ['ground_slam','frost_breath','stone_skin']),
        ('Frozen Sentinel',        'A soldier trapped in ice, still fighting.',           22, 1.15, 'tank',      ['frost_breath','stone_skin','impale']),
        ('Blizzard Harpy',         'Shrieks bring hail.',                                  23, 1.20, 'assassin',  ['frost_breath','chain_lightning','haste']),
        ('Crystal Golem',          'Each facet reflects a different death.',              23, 1.25, 'tank',      ['frost_breath','stone_skin','crushing_blow']),
        ('Frost Wyvern',           'Breathes freezing fog.',                              24, 1.30, 'berserker', ['frost_breath','tail_swipe','frenzy']),
        ('Ice Lich',               'Master of cold magic.',                               25, 1.35, 'defensive', ['frost_breath','arcane_burst','dark_shield']),
        ('Permafrost Colossus',    "Hasn't moved in centuries. Until now.",              25, 1.40, 'aggressive',['frost_breath','ground_slam','enrage']),
        ('Glacius the Eternal',    'Winter incarnate. The abyss itself.',                 27, 1.55, 'aggressive',['frost_breath','arcane_burst','enrage']),
    ]),
    ('realm_of_light', 'Realm of Light', 'Where light burns brighter than fire', 45, 20, 6, [
        ('Light Sprite',           'Blindingly fast, blindingly bright.',                 25, 1.10, 'assassin',  ['arcane_burst','haste','chain_lightning','rend']),
        ('Radiant Archer',         'Arrows of pure light.',                               26, 1.15, 'assassin',  ['impale','arcane_burst','haste','rend']),
        ('Crystal Beast',          'Reflects attacks as beams.',                          27, 1.20, 'defensive', ['arcane_burst','stone_skin','crushing_blow','dark_shield']),
        ('Solar Monk',             'Channels the sun through fists.',                     27, 1.25, 'berserker', ['crushing_blow','enrage','arcane_burst','haste']),
        ('Golden Golem',           'Forged from holy metal.',                             28, 1.30, 'tank',      ['ground_slam','stone_skin','crushing_blow','regeneration']),
        ('Seraph Guardian',        'An angel that asks no questions.',                    28, 1.35, 'defensive', ['arcane_burst','chain_lightning','dark_shield','enrage']),
        ('Prism Dragon',           'Each scale bends light into weapons.',                29, 1.40, 'berserker', ['arcane_burst','fire_wave','frost_breath','tail_swipe']),
        ('Light Weaver',           'Stitches reality with radiance.',                     30, 1.45, 'defensive', ['arcane_burst','chain_lightning','regeneration','dark_shield']),
        ('Solar Colossus',         "The temple's last defender.",                        30, 1.50, 'tank',      ['ground_slam','arcane_burst','stone_skin','enrage']),
        ('The Heart of the Ray',   'An artifact given life. Burning judgment.',           32, 1.65, 'aggressive',['arcane_burst','fire_wave','enrage','frenzy']),
    ]),
    ('shadow_realm', 'Shadow Realm', 'Where the darkness stares back', 50, 22, 7, [
        ('Shadow Wisp',            'A fragment of a nightmare.',                          30, 1.20, 'assassin',  ['shadow_bolt','haste','dark_shield','life_drain']),
        ('Dark Stalker',           'Hunts by sound. Silent footsteps.',                   31, 1.25, 'assassin',  ['shadow_bolt','charge','haste','rend']),
        ('Void Spider',            'Webs that devour light.',                             32, 1.30, 'assassin',  ['poison_cloud','shadow_bolt','haste','tail_swipe']),
        ('Shade Knight',           'Your own silhouette, armored.',                       32, 1.35, 'tank',      ['shadow_bolt','stone_skin','impale','dark_shield']),
        ('Eclipse Wolf',           'Born from a sunless sky.',                            33, 1.40, 'berserker', ['shadow_bolt','frenzy','charge','rend']),
        ('Nightborne Mage',        'Spells woven from absolute darkness.',                33, 1.45, 'defensive', ['shadow_bolt','arcane_burst','dark_shield','life_drain']),
        ('Abyss Hydra',            'Each head a different fear.',                         34, 1.50, 'berserker', ['frenzy','shadow_bolt','poison_cloud','enrage']),
        ('Shadow Dragon',          'Breathes oblivion.',                                  35, 1.55, 'aggressive',['shadow_bolt','arcane_burst','tail_swipe','enrage']),
        ('Void Colossus',          'Where it steps, nothing remains.',                    35, 1.60, 'aggressive',['shadow_bolt','ground_slam','stone_skin','enrage']),
        ('The Whispering Dark',    'Not a creature. A place. That hates.',                37, 1.75, 'aggressive',['shadow_bolt','life_drain','arcane_burst','enrage']),
    ]),
    ('clockwork_citadel', 'Clockwork Citadel', 'Gears never stop turning', 55, 24, 8, [
        ('Gear Sprite',            'Tiny, fast, sparking.',                               35, 1.30, 'assassin',  ['chain_lightning','haste','tail_swipe','rend']),
        ('Clockwork Hound',        'Metal teeth, spring-loaded jaws.',                    36, 1.35, 'berserker', ['frenzy','charge','rend','haste']),
        ('Piston Golem',           'Each punch backed by steam pressure.',                37, 1.40, 'tank',      ['ground_slam','crushing_blow','stone_skin','enrage']),
        ('Sawblade Dancer',        'Spinning blades, deadly rhythm.',                     37, 1.45, 'assassin',  ['frenzy','rend','haste','impale']),
        ('Tesla Turret',           'Zaps anything that moves.',                           38, 1.50, 'defensive', ['chain_lightning','arcane_burst','stone_skin','dark_shield']),
        ('Steam Knight',           'Hisses, clanks, annihilates.',                        38, 1.55, 'tank',      ['crushing_blow','stone_skin','charge','enrage']),
        ('Gear Dragon',            'Wings of interlocking cogs.',                         39, 1.60, 'berserker', ['fire_wave','chain_lightning','tail_swipe','enrage']),
        ('Grand Mechanist',        'Builder of nightmares.',                              40, 1.65, 'defensive', ['chain_lightning','arcane_burst','stone_skin','regeneration']),
        ('Siege Automaton',        'A walking fortress of brass and fury.',               40, 1.70, 'tank',      ['ground_slam','crushing_blow','stone_skin','enrage']),
        ('The Grand Engine',       "The citadel's heart. Infinite gears. One mind.",     42, 1.85, 'aggressive',['chain_lightning','frenzy','enrage','stone_skin']),
    ]),
    ('abyssal_depths', 'Abyssal Depths', 'Beneath the world, something waits', 60, 26, 9, [
        ('Depth Crawler',          'Skitters across the ocean floor.',                    40, 1.40, 'assassin',  ['poison_cloud','tail_swipe','haste','rend']),
        ('Angler Horror',          'Its light lures. Its jaws close.',                    41, 1.45, 'berserker', ['life_drain','crushing_blow','dark_shield','frenzy']),
        ('Coral Golem',            'Living reef with a grudge.',                          42, 1.50, 'tank',      ['ground_slam','stone_skin','regeneration','crushing_blow']),
        ('Siren',                  'Her song drowns reason.',                             42, 1.55, 'defensive', ['shadow_bolt','life_drain','dark_shield','chain_lightning']),
        ('Kraken Spawn',           'One tentacle from something much larger.',            43, 1.60, 'berserker', ['frenzy','crushing_blow','ground_slam','enrage']),
        ('Abyssal Leviathan',      'A whale-sized predator with a temper.',               43, 1.65, 'aggressive',['crushing_blow','ground_slam','enrage','regeneration']),
        ('Deep Sea Dragon',        'Scales covered in barnacles and fury.',               44, 1.70, 'berserker', ['frost_breath','tail_swipe','frenzy','enrage']),
        ('Drowned Admiral',        'Still commands a ghost fleet.',                       45, 1.75, 'assassin',  ['shadow_bolt','life_drain','impale','battle_roar']),
        ('Tidal Colossus',         'The ocean given legs.',                               45, 1.80, 'tank',      ['ground_slam','frost_breath','stone_skin','enrage']),
        ('Charybdis the Devourer', 'The abyss opens. Everything falls in.',               47, 1.95, 'aggressive',['life_drain','frenzy','enrage','arcane_burst']),
    ]),
    ('infernal_throne', 'Infernal Throne', 'The final descent into madness', 65, 30, 10, [
        ('Imp Swarm',              'Small, vicious, everywhere.',                         45, 1.50, 'berserker', ['frenzy','fire_wave','haste','rend']),
        ('Hellhound Alpha',        'Three heads, triple the fury.',                       46, 1.55, 'aggressive',['fire_wave','frenzy','charge','rend']),
        ('Flame Demoness',         'Beauty and annihilation.',                            47, 1.60, 'defensive', ['fire_wave','arcane_burst','dark_shield','life_drain']),
        ('Iron Demon',             'Forged in infernal pits.',                            47, 1.65, 'tank',      ['crushing_blow','stone_skin','enrage','ground_slam']),
        ('Pit Fiend',              'Commander of lesser demons.',                         48, 1.70, 'aggressive',['fire_wave','battle_roar','enrage','frenzy']),
        ('Soul Reaver',            'Steals strength from the fallen.',                    48, 1.75, 'assassin',  ['life_drain','shadow_bolt','dark_shield','enrage']),
        ('Infernal Dragon',        'Fire made flesh, fury made scale.',                   49, 1.80, 'berserker', ['fire_wave','tail_swipe','frenzy','enrage']),
        ('Dark Seraph',            'An angel that chose the wrong side.',                 50, 1.85, 'defensive', ['shadow_bolt','arcane_burst','life_drain','dark_shield']),
        ('The Throne Guardian',    'The last line of defense. Absolute.',                 50, 1.90, 'tank',      ['ground_slam','stone_skin','enrage','crushing_blow']),
        ('Archfiend Malachar',     'He sits on the throne. He waits. He wins.',           52, 2.10, 'aggressive',['fire_wave','arcane_burst','enrage','life_drain']),
    ]),
]


def sql_escape(s):
    return s.replace("'", "''")


def emit_dungeon_block(slug, name, subtitle, level_req, energy_cost, sort_order, bosses):
    """Emit one dungeon + its bosses + their abilities using a CTE chain.

    On conflict (slug), the CTE returns zero rows → downstream boss / ability
    inserts silently skip, preserving full idempotency.
    """
    lines = []
    lines.append(f"-- ---------------------------------------------------------------------------")
    lines.append(f"-- {sort_order}. {name} (slug={slug})")
    lines.append(f"-- ---------------------------------------------------------------------------")
    lines.append("")
    lines.append("WITH new_dungeon AS (")
    lines.append(f"  INSERT INTO \"dungeons\" (")
    lines.append(f"    \"id\", \"slug\", \"name\", \"description\", \"lore\",")
    lines.append(f"    \"level_req\", \"difficulty\", \"dungeon_type\", \"energy_cost\",")
    lines.append(f"    \"is_active\", \"sort_order\", \"gold_reward\", \"xp_reward\",")
    lines.append(f"    \"created_at\", \"updated_at\"")
    lines.append(f"  ) VALUES (")
    lines.append(f"    gen_random_uuid(), '{slug}', '{sql_escape(name)}', '{sql_escape(subtitle)}', '{sql_escape(subtitle)}',")
    lines.append(f"    {level_req}, 'normal', 'story', {energy_cost},")
    lines.append(f"    true, {sort_order}, 0, 0,")
    lines.append(f"    NOW(), NOW()")
    lines.append(f"  )")
    lines.append(f"  ON CONFLICT (\"slug\") DO NOTHING")
    lines.append(f"  RETURNING \"id\"")
    lines.append("),")

    # Bosses inserted from a VALUES list joined with new_dungeon
    lines.append("bosses_to_insert (\"name\", \"boss_type\", \"level\", \"hp\", \"damage\", \"defense\", \"speed\", \"crit_chance\", \"tagline\", \"description\", \"floor_number\", \"sort_order\") AS (")
    lines.append("  VALUES")
    boss_value_lines = []
    for i, (bname, bdesc, blevel, bmult, bstance, babilities) in enumerate(bosses):
        hp = calc_hp(blevel, bmult)
        dmg = calc_damage(blevel, bmult)
        dfs = calc_defense(blevel, bmult)
        spd = calc_speed(blevel, bmult)
        crit = 5 + i * 0.5
        tagline = bdesc  # boss.tagline ?? boss.description
        desc = bdesc
        boss_value_lines.append(
            f"    ('{sql_escape(bname)}', '{bstance}', {blevel}, {hp}, {dmg}, {dfs}, {spd}, {crit}, "
            f"'{sql_escape(tagline)}', '{sql_escape(desc)}', {i+1}, {i})"
        )
    lines.append(",\n".join(boss_value_lines))
    lines.append("),")

    lines.append("new_bosses AS (")
    lines.append("  INSERT INTO \"dungeon_bosses\" (")
    lines.append("    \"id\", \"dungeon_id\", \"name\", \"boss_type\", \"level\",")
    lines.append("    \"hp\", \"damage\", \"defense\", \"speed\", \"crit_chance\",")
    lines.append("    \"tagline\", \"description\", \"floor_number\", \"sort_order\",")
    lines.append("    \"created_at\", \"updated_at\"")
    lines.append("  )")
    lines.append("  SELECT")
    lines.append("    gen_random_uuid(), nd.\"id\", b.\"name\", b.\"boss_type\", b.\"level\",")
    lines.append("    b.\"hp\", b.\"damage\", b.\"defense\", b.\"speed\", b.\"crit_chance\",")
    lines.append("    b.\"tagline\", b.\"description\", b.\"floor_number\", b.\"sort_order\",")
    lines.append("    NOW(), NOW()")
    lines.append("  FROM new_dungeon nd CROSS JOIN bosses_to_insert b")
    lines.append("  RETURNING \"id\", \"name\"")
    lines.append("),")

    # Abilities: one row per (boss, ability)
    lines.append("abilities_to_insert (\"boss_name\", \"name\", \"ability_type\", \"damage\", \"cooldown\", \"special_effect\", \"description\") AS (")
    lines.append("  VALUES")
    ability_value_lines = []
    for (bname, _, _, _, _, babilities) in bosses:
        for ability_key in babilities:
            (aname, atype, adam, acd, asp, adesc) = ABILITY_CATALOG[ability_key]
            ability_value_lines.append(
                f"    ('{sql_escape(bname)}', '{sql_escape(aname)}', '{atype}', {adam}, {acd}, "
                f"'{asp}', '{sql_escape(adesc)}')"
            )
    lines.append(",\n".join(ability_value_lines))
    lines.append(")")

    lines.append("INSERT INTO \"boss_abilities\" (")
    lines.append("  \"id\", \"boss_id\", \"name\", \"ability_type\", \"damage\", \"cooldown\", \"special_effect\", \"description\", \"created_at\"")
    lines.append(")")
    lines.append("SELECT")
    lines.append("  gen_random_uuid(), nb.\"id\", a.\"name\", a.\"ability_type\", a.\"damage\", a.\"cooldown\", a.\"special_effect\", a.\"description\", NOW()")
    lines.append("FROM new_bosses nb JOIN abilities_to_insert a ON nb.\"name\" = a.\"boss_name\";")

    lines.append("")
    return "\n".join(lines)


def main():
    header = """-- Seed 2026-04-21: idempotently repopulate 7 GDD dungeons (3-9) + bosses + abilities.
--
-- Source of truth: `backend/prisma/seed-dungeons.ts` (NEW_DUNGEONS + ABILITY_CATALOG).
-- This .sql mirrors that TS seed 1:1 so a prod / staging snapshot-restore can
-- reseed without needing Node tooling. Generated by `scripts/gen_dungeons_sql.py`.
--
-- When editing: update BOTH `seed-dungeons.ts` AND regenerate this file in the
-- same commit. Use the seed script to bootstrap a new local DB; use this
-- migration to recover production.
--
-- Idempotency: each dungeon block uses ON CONFLICT (slug) DO NOTHING on
-- `dungeons`. If the conflict fires, the RETURNING clause is empty, so the
-- downstream boss + ability inserts silently skip via CROSS JOIN on the empty
-- CTE. Re-running this migration against a DB that already has these dungeons
-- is a no-op.
--
-- Related incidents: Gold Mine (2026-04-11), Stash (2026-04-13), Degon admin
-- role (2026-04-19), Appearance Skins (2026-04-20). See gatekeeper/SKILL.md §6c.

"""
    print(header, end="")
    for (slug, name, subtitle, level_req, energy_cost, sort_order, bosses) in DUNGEONS:
        print(emit_dungeon_block(slug, name, subtitle, level_req, energy_cost, sort_order, bosses))


if __name__ == "__main__":
    main()
