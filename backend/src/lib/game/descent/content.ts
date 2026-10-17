// =============================================================================
// descent/content.ts — static content for Dungeon Rush v2 "The Descent"
//
// Ported from the approved prototype (artifact "Dungeon Rush Descent", v5) and
// the design doc DUNGEON_RUSH_V2_DESIGN_2026-10-16 §2. Numbers here are the
// tuned prototype values; reward scaling to the real economy happens in
// descent/rewards (route layer), never on the client.
//
// Text markup used in tale/hint strings (rendered by the iOS client):
//   **x**  highlighted (gold)      {+x+}  good (green)      {-x-}  bad (red)
// =============================================================================

export const DESCENT_DUNGEON_ID = 'descent'
export const DESCENT_VERSION = 2

export const DESCENT = {
  STAMINA_COST: 30,
  HERO_HP: 1000,
  START_POTIONS: 3, // decided 2026-10-16
  START_TORCHES: 2,
  MAX_POTIONS: 5,
  MAX_TORCHES: 5,
  POTION_HEAL: 0.35,
  ALCHEMIST_POTION_HEAL: 0.5,
  FLEE_HP_COST: 0.08,
  BRACE_DAMAGE_TAKEN: 0.45,
  /** Share of the bag lost on death (decided 2026-10-16). */
  DEATH_LOSS_SHARE: 0.5,
  /**
   * Prototype gold → real gold before level/CHA/premium scaling.
   * 0.3 keeps a full descent (~1,900 prototype gold kept on average by the
   * reference bot, deaths included) at ≈ 575 gold at L1 and ≈ 1,700 at L50 —
   * at or below the old Dungeon Rush per 30 stamina (BALANCE_AUDIT_2026-10-16 §5).
   */
  GOLD_SCALE: 0.3,
  /** Prototype XP → real XP before level scaling. */
  XP_SCALE: 0.75,
  CAMP_REST_HEAL: 0.3,
  CAMP_SHARPEN: 0.12,
  GUARDIAN_DMG_BONUS: 0.12,
  GUARDIAN_HEAL: 0.25,
  MIMIC_BITE: 0.08,
} as const

export type DepthKey = 'ossuary' | 'warrens' | 'molten'
export type ChestTier = 'wood' | 'iron' | 'gold'
export type TraitKey = 'regen' | 'dodge' | 'heavy' | 'armor' | 'enrage'
export type MobKey =
  | 'skeleton' | 'ghoul' | 'undead' | 'rat' | 'plague' | 'boneking'
  | 'troll' | 'imp' | 'bandit' | 'goblin' | 'assassin' | 'lordshadows'
  | 'sprite' | 'brute' | 'golem' | 'juggernaut' | 'warden' | 'mimic'
export type NodeType = 'combat' | 'elite' | 'treasure' | 'event' | 'camp' | 'merchant' | 'boss'
export type RelicKey =
  | 'bloodstone' | 'ironheart' | 'razorfang' | 'siphon' | 'giantsbelt'
  | 'shadowblade' | 'goldweave' | 'eagleeye' | 'lantern' | 'alchemist'
export type EventId = 'explorer' | 'altar' | 'fountain' | 'bridge' | 'troll' | 'angel' | 'cache' | 'runes'

export interface MobDef {
  name: string
  traits: TraitKey[]
  /** iOS asset name (Assets.xcassets imageset). */
  art: string
  size?: 'small' | 'big'
}

export const MOBS: Record<MobKey, MobDef> = {
  skeleton: { name: 'Skeleton Warrior', traits: [], art: 'rush2-mob-skeleton' },
  ghoul: { name: 'Feral Ghoul', traits: ['enrage'], art: 'rush2-mob-ghoul' },
  undead: { name: 'Undead Soldier', traits: ['regen'], art: 'rush2-mob-undead' },
  rat: { name: 'Dungeon Rat', traits: ['dodge'], art: 'rush2-mob-rat', size: 'small' },
  plague: { name: 'Plague Knight', traits: ['armor', 'heavy'], art: 'rush2-elite-plague' },
  boneking: { name: 'The Bone King', traits: ['regen'], art: 'rush2-boss-boneking' },
  troll: { name: 'Cave Troll', traits: ['heavy'], art: 'rush2-mob-troll', size: 'big' },
  imp: { name: 'Dark Imp', traits: ['dodge'], art: 'rush2-mob-imp', size: 'small' },
  bandit: { name: 'Cursed Bandit', traits: [], art: 'rush2-mob-bandit' },
  goblin: { name: 'Goblin Scout', traits: ['dodge'], art: 'rush2-mob-goblin', size: 'small' },
  assassin: { name: 'Shadow Assassin', traits: ['dodge', 'enrage'], art: 'rush2-elite-assassin' },
  lordshadows: { name: 'Lord of Shadows', traits: ['dodge', 'heavy'], art: 'rush2-boss-lordshadows' },
  sprite: { name: 'Flame Sprite', traits: ['dodge'], art: 'rush2-mob-sprite', size: 'small' },
  brute: { name: 'Infernal Brute', traits: ['heavy'], art: 'rush2-mob-brute' },
  golem: { name: 'Stone Golem', traits: ['armor'], art: 'rush2-mob-golem', size: 'big' },
  juggernaut: { name: 'Iron Juggernaut', traits: ['heavy'], art: 'rush2-elite-juggernaut', size: 'big' },
  warden: { name: 'Warden of the Depths', traits: ['enrage', 'heavy'], art: 'rush2-boss-warden' },
  mimic: { name: 'Mimic', traits: ['heavy'], art: 'rush2-mimic' },
}

export const TRAITS: Record<TraitKey, string> = {
  regen: 'Mends every 3rd round',
  dodge: 'Evasive',
  heavy: 'Crushing blow every 3rd round',
  armor: 'Armored',
  enrage: 'Frenzy below 35% HP',
}

export interface DepthDef {
  key: DepthKey
  name: string
  blurb: string
  mobs: MobKey[]
  elite: MobKey
  boss: MobKey
  rows: number
  dark: number
  hp: number
  dmg: number
  gold: number
  xp: number
  bossHp: number
  bossDmg: number
  chests: Array<[ChestTier, number]>
}

export const DEPTHS: DepthDef[] = [
  {
    key: 'ossuary', name: 'The Ossuary',
    blurb: 'Bones of forgotten kings line the walls. Nothing down here stays dead for long.',
    mobs: ['skeleton', 'ghoul', 'undead', 'rat'], elite: 'plague', boss: 'boneking', rows: 4, dark: 0.3,
    hp: 270, dmg: 60, gold: 45, xp: 30, bossHp: 640, bossDmg: 78,
    chests: [['wood', 70], ['iron', 25], ['gold', 5]],
  },
  {
    key: 'warrens', name: 'The Shadow Warrens',
    blurb: 'Tunnels dug by things that hate the light. Every torch you carry matters here.',
    mobs: ['troll', 'imp', 'bandit', 'goblin'], elite: 'assassin', boss: 'lordshadows', rows: 5, dark: 0.42,
    hp: 330, dmg: 72, gold: 65, xp: 45, bossHp: 720, bossDmg: 80,
    chests: [['wood', 30], ['iron', 50], ['gold', 20]],
  },
  {
    key: 'molten', name: 'The Molten Heart',
    blurb: 'The rock itself glows. The Warden has kept this gate for a thousand years.',
    mobs: ['sprite', 'brute', 'golem'], elite: 'juggernaut', boss: 'warden', rows: 5, dark: 0.5,
    // Guardian III: +15% HP (900 → 1035) and +11% damage (90 → 100), decided 2026-10-16.
    hp: 390, dmg: 82, gold: 90, xp: 65, bossHp: 1035, bossDmg: 100,
    chests: [['wood', 10], ['iron', 45], ['gold', 45]],
  },
]

export interface ChestDef {
  name: string
  goldMult: number
  /** Added to the base item-drop chance (rarity stays on the global table, R14.1). */
  itemBoost: number
}

export const CHESTS: Record<ChestTier, ChestDef> = {
  wood: { name: 'Old oak chest', goldMult: 1, itemBoost: 0 },
  iron: { name: 'Iron-bound strongbox', goldMult: 1.35, itemBoost: 0.15 },
  gold: { name: 'Gilded royal coffer', goldMult: 1.9, itemBoost: 0.35 },
}

export interface RelicDef {
  name: string
  desc: string
}

export const RELICS: Record<RelicKey, RelicDef> = {
  bloodstone: { name: 'Bloodstone Amulet', desc: 'Heal 10% of the damage you deal.' },
  ironheart: { name: 'Iron Heart', desc: 'Take 12% less damage.' },
  razorfang: { name: 'Razorfang Pendant', desc: 'Critical hits deal +40% damage.' },
  siphon: { name: 'Soul Siphon', desc: 'Heal 12% HP after every kill.' },
  giantsbelt: { name: "Giant's Belt", desc: '+200 max HP.' },
  shadowblade: { name: 'Shadow Blade', desc: '+15% damage.' },
  goldweave: { name: 'Goldweave Cloak', desc: '+50% gold from fights and chests.' },
  eagleeye: { name: 'Eagle Eye', desc: '+10% critical chance.' },
  lantern: { name: 'Everburning Lantern', desc: '+1 torch at the start of every depth.' },
  alchemist: { name: "Alchemist's Sash", desc: 'Potions heal 50% instead of 35%.' },
}

export const RELIC_KEYS = Object.keys(RELICS) as RelicKey[]

export const TYPE_NAME: Record<NodeType, string> = {
  combat: 'Monster', elite: 'Elite', treasure: 'Treasure', event: 'Mystery',
  camp: 'Campfire', merchant: 'Merchant', boss: 'Guardian',
}

/** Cues heard at a fork, per node type, per depth. */
export const CUES: Record<Exclude<NodeType, 'boss'>, string[][]> = {
  combat: [
    ['Bones rattle somewhere ahead.', 'Wet footsteps. Something is feeding.', 'A low hiss, then silence.'],
    ['A low growl rolls down the tunnel.', 'Claws scrape on stone.', 'Someone laughs in the dark. Not kindly.'],
    ['The air shimmers with heat. Something crackles.', 'Rock grinds against rock.', 'A snarl, and the smell of burnt hair.'],
  ],
  elite: [
    ['Heavy armored steps. Coughing, wet and sick.'],
    ['A blade is being sharpened. Slowly.'],
    ['A chain drags across the floor. The ground shakes.'],
  ],
  treasure: [
    ['A faint golden glint in the dark.', 'The smell of old oak and iron.'],
    ['Coins clink as something settles.', 'A glint of gold beneath the cobwebs.'],
    ['Gold gleams in the red light.', 'A treasure chest, half-melted into the rock.'],
  ],
  event: [
    ['Whispers. Someone is waiting.', 'A strange violet light pulses.'],
    ['Running water, and faint singing.', 'A voice asks for help.'],
    ['A low hum, like a prayer.', 'Runes glow on a sealed door.'],
  ],
  camp: [['Warm firelight flickers on the walls.'], ['Smoke and the smell of roasting meat.'], ['A safe hollow. Embers still glow.']],
  merchant: [['A lantern sways. Someone hums a trade song.'], ['The jingle of a hundred trinkets.'], ['"Potions! Torches! Fair prices, mostly!"']],
}
export const CUE_DARK = 'Pitch black. Not a sound.'
export const CUE_FLED = 'It is still in there, waiting.'
export const BOSS_CUE = 'A sealed gate. Behind it, something ancient wakes.'
export const FORK_LINES: Record<number, string> = {
  1: 'The tunnel runs on into the dark.',
  2: 'The passage splits in two.',
  3: 'Three tunnels yawn ahead.',
}
export const DEPTH_OPENINGS = [
  'The crypt opens before you.',
  'The roots part and the warrens swallow the light.',
  'Heat rolls up the stairs. The rock is glowing.',
]

export const ZONES = ['head', 'head', 'chest', 'chest', 'legs', 'legs'] as const
export type Zone = (typeof ZONES)[number]
export const ZONE_MULT: Record<Zone, number> = { head: 1.25, chest: 1, legs: 0.85 }

export const EVENT_IDS: EventId[] = ['explorer', 'altar', 'fountain', 'bridge', 'troll', 'angel', 'cache', 'runes']

/** iOS scene asset per event (the subject is painted into the scene). */
export const EVENT_SCENE: Record<EventId | 'mimic', string> = {
  explorer: 'rush2-ev-explorer', altar: 'rush2-ev-altar', fountain: 'rush2-ev-fountain', bridge: 'rush2-ev-bridge',
  troll: 'rush2-ev-troll', angel: 'rush2-ev-angel', cache: 'rush2-ev-cache', runes: 'rush2-ev-runedoor',
  mimic: 'rush2-bg-treasure',
}
