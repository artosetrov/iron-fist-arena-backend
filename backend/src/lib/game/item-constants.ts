// Two-handed weapons occupy both weapon and relic (off-hand) slots simultaneously.
// When equipped, the off-hand slot must be cleared.
// Used by: equip route (slot clearing), shop route (UI flag), inventory route (UI flag).
export const TWO_HANDED_CATALOG_IDS = new Set([
  // Hammers & Cleavers
  'wpn_war_hammer',
  'wpn_bonecleaver',
  'wpn_serrated_cleaver',
  // Legendary melee
  'wpn_excalibur',
  'wpn_worldbreaker',
  'wpn_soulreaver',
  // Staves (mage two-handers)
  'wpn_wooden_staff',
  'wpn_frostbite_staff',
  'wpn_nightmare_staff',
  'wpn_crystalcore_staff',
  // Codex (legendary mage two-hander)
  'wpn_astral_codex',
])
