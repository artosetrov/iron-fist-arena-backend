-- =============================================================================
-- 20261014_item_icon_keys
--
-- 63 catalog items had no art anywhere: 44 image_keys pointed at files that
-- were never uploaded to storage (assets/items/<key>.png → 404) and were not in
-- the iOS bundle, and 19 later items (Dawnbreaker, the Ascendant set, Titanbind,
-- Starbound Chain, …) borrowed another item's key. Every one of them now ships
-- its own pen-and-ink icon in Assets.xcassets/Items/<catalog_id>.imageset, so
-- image_key becomes the item's own catalog_id and the dead storage URL is
-- cleared (AssetManager resolves bundle → disk cache → network).
-- =============================================================================

UPDATE "items"
   SET "image_key"  = "catalog_id",
       "image_url"  = NULL,
       "updated_at" = NOW()
 WHERE "catalog_id" IN (
  'acc_aegis',
  'acc_aegis_of_dawn',
  'acc_mirror_shield',
  'acc_tower_shield',
  'amu_doomward',
  'amu_eye_of_the_ascendant',
  'amu_heart_of_eternity',
  'amu_soulchain',
  'belt_titanbind',
  'belt_warbrand',
  'belt_worldserpent',
  'belt_wyrmskin',
  'boot_ascendant_treads',
  'boot_eternaltread',
  'boot_stormstriders',
  'boot_wraithstep',
  'chest_ascendant_plate',
  'chest_bloodweave',
  'chest_dragonhide',
  'chest_godplate',
  'chest_spiritweave',
  'glove_ascendant_grips',
  'glove_demongrasps',
  'glove_irongrip',
  'glove_plaguegrip',
  'helm_abyssal_crown',
  'helm_ascendant_crown',
  'helm_dread_visor',
  'helm_moonveil',
  'helm_warskull',
  'legs_ascendant_greaves',
  'legs_boneguard',
  'legs_nightstalker',
  'legs_voidwalker',
  'neck_bloodstone',
  'neck_dreadstone',
  'neck_soulbinder',
  'neck_starbound_chain',
  'relic_crown_of_ashes',
  'relic_demon_eye',
  'relic_heart_of_the_void',
  'relic_warhorn',
  'ring_eclipse',
  'ring_oblivion',
  'ring_shadowfang',
  'ring_singularity',
  'wpn_ascendant_blade',
  'wpn_ascendant_bulwark',
  'wpn_ascendant_edge',
  'wpn_ascendant_staff',
  'wpn_astral_codex',
  'wpn_bonecleaver',
  'wpn_colossus_maul',
  'wpn_crystalcore_staff',
  'wpn_dawnbreaker',
  'wpn_eclipse_fangs',
  'wpn_fey_bow',
  'wpn_hellfire_blade',
  'wpn_nightmare_staff',
  'wpn_serrated_cleaver',
  'wpn_soulreaver',
  'wpn_starfall_codex',
  'wpn_worldbreaker'
 );
