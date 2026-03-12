import { PrismaClient, CharacterClass, CharacterOrigin, ItemType, Rarity } from '@prisma/client'
import { randomUUID } from 'crypto'

const prisma = new PrismaClient()

const CLASSES: CharacterClass[] = ['warrior', 'rogue', 'mage', 'tank']
const ORIGINS: CharacterOrigin[] = ['human', 'orc', 'skeleton', 'demon', 'dogfolk']
const GENDERS = ['male', 'female'] as const

const AVATARS_BY_GENDER: Record<string, string[]> = {
  male: ['warlord', 'knight', 'barbarian', 'shadow'],
  female: ['valkyrie', 'sorceress', 'enchantress', 'huntress'],
}

const NAME_PREFIXES = [
  'Iron', 'Shadow', 'Crimson', 'Storm', 'Void', 'Blood', 'Ash', 'Frost',
  'Ember', 'Dusk', 'Night', 'Steel', 'Grim', 'Bone', 'Wild', 'Death',
  'Soul', 'Ice', 'Thunder', 'Dark', 'Fire', 'Stone', 'Ghost', 'War',
  'Doom', 'Rage', 'Scar', 'Venom', 'Thorn', 'Rune',
]
const NAME_SUFFIXES = [
  'Bane', 'Fist', 'Edge', 'Breaker', 'Walker', 'Thorn', 'Pyre', 'Warden',
  'Claw', 'Raider', 'Stalker', 'Veil', 'Forge', 'Crusher', 'Fury',
  'Mark', 'Reaver', 'Fang', 'Blaze', 'Strike', 'Guard', 'Blade', 'Horn',
  'Maw', 'Skull', 'Heart', 'Bite', 'Shade', 'Spark', 'Grip',
]

function pick<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)]
}

function randInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min
}

// Generate unique bot names (need 150)
function generateBotNames(count: number): string[] {
  const names = new Set<string>()
  for (const p of NAME_PREFIXES) {
    for (const s of NAME_SUFFIXES) {
      names.add(p + s)
      if (names.size >= count) return Array.from(names)
    }
  }
  return Array.from(names).slice(0, count)
}

// Stat allocation weights by class (STR, AGI, VIT, END, INT, WIS, LUK, CHA)
const CLASS_WEIGHTS: Record<CharacterClass, number[]> = {
  warrior: [30, 12, 20, 18, 3, 3, 7, 7],
  rogue:   [12, 30, 8, 8, 5, 5, 22, 10],
  mage:    [3, 8, 12, 8, 30, 22, 10, 7],
  tank:    [18, 5, 25, 28, 3, 5, 8, 8],
}

function botStatsForLevel(cls: CharacterClass, level: number) {
  const base = { str: 10, agi: 10, vit: 10, end: 10, int: 10, wis: 10, luk: 10, cha: 10 }
  const keys: (keyof typeof base)[] = ['str', 'agi', 'vit', 'end', 'int', 'wis', 'luk', 'cha']
  const weights = CLASS_WEIGHTS[cls]
  const totalWeight = weights.reduce((a, b) => a + b, 0)

  // 3 stat points per level (level 1 = 0 bonus)
  const bonusPoints = 3 * (level - 1)

  // Distribute points by weight with some randomness
  let remaining = bonusPoints
  for (let i = 0; i < keys.length; i++) {
    const share = Math.round((bonusPoints * weights[i]) / totalWeight)
    const jitter = randInt(-1, 1)
    const pts = Math.max(0, Math.min(remaining, share + jitter))
    base[keys[i]] += pts
    remaining -= pts
  }
  // Dump leftover into primary stat
  if (remaining > 0) base[keys[weights.indexOf(Math.max(...weights))]] += remaining

  // Derived stats
  const maxHp = 80 + base.vit * 5 + base.end * 3
  const armor = Math.floor(base.end * 2 + base.str * 0.5)
  const magicResist = Math.floor(base.wis * 2 + base.int * 0.5)

  return { ...base, maxHp, armor, magicResist }
}

function pvpRatingForLevel(level: number): number {
  // Level 1 ~ 1000, scales ~16 per level, with jitter
  return Math.max(100, 1000 + (level - 1) * 16 + randInt(-40, 40))
}

const MAX_LEVEL = 50
const BOTS_PER_LEVEL = 3

async function main() {
  console.log('🌱 Seeding bot opponents (3 per level, levels 1–50)...')

  const botNames = generateBotNames(MAX_LEVEL * BOTS_PER_LEVEL)
  let created = 0
  let skipped = 0
  let nameIdx = 0

  for (let level = 1; level <= MAX_LEVEL; level++) {
    for (let b = 0; b < BOTS_PER_LEVEL; b++) {
      const name = botNames[nameIdx++]
      const cls = CLASSES[(level * 3 + b) % CLASSES.length]
      const origin = ORIGINS[(level + b) % ORIGINS.length]
      const gender = GENDERS[(level + b) % 2]
      const avatars = AVATARS_BY_GENDER[gender]
      const avatar = avatars[(level * 3 + b) % avatars.length]
      const rating = pvpRatingForLevel(level)
      const wins = randInt(level * 2, level * 5)
      const losses = randInt(level, level * 3)
      const stats = botStatsForLevel(cls, level)

      const existing = await prisma.character.findUnique({
        where: { characterName: name },
      })
      if (existing) { skipped++; continue }

      const userId = randomUUID()

      await prisma.user.create({
        data: {
          id: userId,
          email: `bot_${name.toLowerCase()}@arena.bot`,
          username: name,
          authProvider: 'bot',
          characters: {
            create: {
              characterName: name,
              class: cls,
              origin,
              gender,
              avatar,
              level,
              pvpRating: rating,
              pvpWins: wins,
              pvpLosses: losses,
              pvpWinStreak: randInt(0, Math.min(level, 10)),
              highestPvpRank: rating + randInt(0, 80),
              pvpCalibrationGames: 10,
              gold: 500 + level * 100,
              ...stats,
              currentHp: stats.maxHp,
            },
          },
        },
      })

      created++
      console.log(`  ✓ Lv${level} ${name} (${cls}, rating: ${rating})`)
    }
  }

  console.log(`\n✅ Bots: ${created} created, ${skipped} already existed.`)

  // =========================================================================
  // Seed shop items
  // =========================================================================
  console.log('\n🗡️  Seeding shop items...')

  interface ItemDef {
    catalogId: string
    itemName: string
    itemType: ItemType
    rarity: Rarity
    itemLevel: number
    buyPrice: number
    sellPrice: number
    baseStats: Record<string, number>
    description: string
    specialEffect?: string
    classRestriction?: string
    setName?: string
  }

  const ITEMS: ItemDef[] = [
    // ── WEAPONS ──────────────────────────────────────────────
    // Common
    { catalogId: 'wpn_rusty_sword', itemName: 'Rusty Sword', itemType: 'weapon', rarity: 'common', itemLevel: 1, buyPrice: 100, sellPrice: 25, baseStats: { str: 3, agi: 1 }, description: 'A worn blade, still sharp enough.' },
    { catalogId: 'wpn_wooden_staff', itemName: 'Wooden Staff', itemType: 'weapon', rarity: 'common', itemLevel: 1, buyPrice: 100, sellPrice: 25, baseStats: { int: 3, wis: 1 }, description: 'A simple mage staff.' },
    { catalogId: 'wpn_iron_dagger', itemName: 'Iron Dagger', itemType: 'weapon', rarity: 'common', itemLevel: 1, buyPrice: 120, sellPrice: 30, baseStats: { agi: 3, luk: 1 }, description: 'Quick and deadly.' },
    { catalogId: 'wpn_training_mace', itemName: 'Training Mace', itemType: 'weapon', rarity: 'common', itemLevel: 1, buyPrice: 110, sellPrice: 28, baseStats: { str: 2, vit: 2 }, description: 'Heavy but reliable.' },
    // Uncommon
    { catalogId: 'wpn_steel_longsword', itemName: 'Steel Longsword', itemType: 'weapon', rarity: 'uncommon', itemLevel: 3, buyPrice: 350, sellPrice: 88, baseStats: { str: 6, agi: 2 }, description: 'A well-forged blade.' },
    { catalogId: 'wpn_arcane_wand', itemName: 'Arcane Wand', itemType: 'weapon', rarity: 'uncommon', itemLevel: 3, buyPrice: 350, sellPrice: 88, baseStats: { int: 6, wis: 2 }, description: 'Pulses with arcane energy.' },
    { catalogId: 'wpn_shadow_knife', itemName: 'Shadow Knife', itemType: 'weapon', rarity: 'uncommon', itemLevel: 3, buyPrice: 380, sellPrice: 95, baseStats: { agi: 5, luk: 3 }, description: 'Vanishes into shadow mid-strike.' },
    { catalogId: 'wpn_war_hammer', itemName: 'War Hammer', itemType: 'weapon', rarity: 'uncommon', itemLevel: 4, buyPrice: 400, sellPrice: 100, baseStats: { str: 7, end: 2 }, description: 'Crushes armor on impact.' },
    // Rare
    { catalogId: 'wpn_flamebrand', itemName: 'Flamebrand', itemType: 'weapon', rarity: 'rare', itemLevel: 6, buyPrice: 900, sellPrice: 225, baseStats: { str: 10, agi: 4 }, description: 'Burns with eternal flame.', specialEffect: '+10% fire damage' },
    { catalogId: 'wpn_frostbite_staff', itemName: 'Frostbite Staff', itemType: 'weapon', rarity: 'rare', itemLevel: 6, buyPrice: 900, sellPrice: 225, baseStats: { int: 10, wis: 4 }, description: 'Chills the air around it.', specialEffect: '+10% ice damage' },
    { catalogId: 'wpn_venom_fang', itemName: 'Venom Fang', itemType: 'weapon', rarity: 'rare', itemLevel: 7, buyPrice: 1100, sellPrice: 275, baseStats: { agi: 8, luk: 5 }, description: 'Drips with deadly poison.', specialEffect: '5% poison on hit' },
    // Epic
    { catalogId: 'wpn_stormbringer', itemName: 'Stormbringer', itemType: 'weapon', rarity: 'epic', itemLevel: 10, buyPrice: 2500, sellPrice: 625, baseStats: { str: 16, agi: 8, luk: 4 }, description: 'Thunder follows every strike.', specialEffect: '+15% crit chance' },
    { catalogId: 'wpn_void_scepter', itemName: 'Void Scepter', itemType: 'weapon', rarity: 'epic', itemLevel: 10, buyPrice: 2500, sellPrice: 625, baseStats: { int: 16, wis: 8, luk: 4 }, description: 'Channels the power of the void.', specialEffect: '+15% spell power' },
    // Legendary
    { catalogId: 'wpn_excalibur', itemName: 'Excalibur', itemType: 'weapon', rarity: 'legendary', itemLevel: 15, buyPrice: 8000, sellPrice: 2000, baseStats: { str: 25, agi: 12, vit: 8, luk: 5 }, description: 'The legendary sword of kings.', specialEffect: '+20% all damage, +10% crit' },

    // ── HELMETS ──────────────────────────────────────────────
    { catalogId: 'helm_leather_cap', itemName: 'Leather Cap', itemType: 'helmet', rarity: 'common', itemLevel: 1, buyPrice: 80, sellPrice: 20, baseStats: { vit: 2 }, description: 'Basic head protection.' },
    { catalogId: 'helm_iron_helm', itemName: 'Iron Helm', itemType: 'helmet', rarity: 'uncommon', itemLevel: 3, buyPrice: 280, sellPrice: 70, baseStats: { vit: 4, end: 2 }, description: 'Sturdy iron headgear.' },
    { catalogId: 'helm_mystic_hood', itemName: 'Mystic Hood', itemType: 'helmet', rarity: 'uncommon', itemLevel: 3, buyPrice: 280, sellPrice: 70, baseStats: { int: 3, wis: 3 }, description: 'Enhances mental focus.' },
    { catalogId: 'helm_dragon_visage', itemName: 'Dragon Visage', itemType: 'helmet', rarity: 'rare', itemLevel: 7, buyPrice: 850, sellPrice: 213, baseStats: { vit: 8, str: 4, end: 3 }, description: 'Forged from dragon scales.', specialEffect: '+5% fire resist' },
    { catalogId: 'helm_crown_of_thorns', itemName: 'Crown of Thorns', itemType: 'helmet', rarity: 'epic', itemLevel: 10, buyPrice: 2200, sellPrice: 550, baseStats: { vit: 12, str: 6, end: 6 }, description: 'Pain grants power.', specialEffect: '+10% damage when HP < 50%' },

    // ── CHEST ARMOR ─────────────────────────────────────────
    { catalogId: 'chest_cloth_robe', itemName: 'Cloth Robe', itemType: 'chest', rarity: 'common', itemLevel: 1, buyPrice: 120, sellPrice: 30, baseStats: { vit: 2, wis: 1 }, description: 'Simple cloth protection.' },
    { catalogId: 'chest_chain_mail', itemName: 'Chain Mail', itemType: 'chest', rarity: 'uncommon', itemLevel: 3, buyPrice: 400, sellPrice: 100, baseStats: { vit: 5, end: 3 }, description: 'Linked metal rings.' },
    { catalogId: 'chest_mage_robe', itemName: 'Enchanted Robe', itemType: 'chest', rarity: 'uncommon', itemLevel: 4, buyPrice: 420, sellPrice: 105, baseStats: { int: 4, wis: 4 }, description: 'Woven with protective spells.' },
    { catalogId: 'chest_plate_armor', itemName: 'Plate Armor', itemType: 'chest', rarity: 'rare', itemLevel: 6, buyPrice: 1000, sellPrice: 250, baseStats: { vit: 10, end: 5, str: 3 }, description: 'Heavy steel plates.', specialEffect: '+5% physical resist' },
    { catalogId: 'chest_shadow_vest', itemName: 'Shadow Vest', itemType: 'chest', rarity: 'rare', itemLevel: 7, buyPrice: 1050, sellPrice: 263, baseStats: { agi: 8, luk: 4, vit: 4 }, description: 'Light as a whisper.', specialEffect: '+5% dodge' },
    { catalogId: 'chest_titan_cuirass', itemName: 'Titan Cuirass', itemType: 'chest', rarity: 'epic', itemLevel: 10, buyPrice: 2800, sellPrice: 700, baseStats: { vit: 15, end: 8, str: 5 }, description: 'Armor of the ancient titans.', specialEffect: '+10% max HP' },

    // ── GLOVES ───────────────────────────────────────────────
    { catalogId: 'glove_cloth_wraps', itemName: 'Cloth Wraps', itemType: 'gloves', rarity: 'common', itemLevel: 1, buyPrice: 60, sellPrice: 15, baseStats: { agi: 1, str: 1 }, description: 'Simple hand protection.' },
    { catalogId: 'glove_iron_gauntlets', itemName: 'Iron Gauntlets', itemType: 'gloves', rarity: 'uncommon', itemLevel: 3, buyPrice: 250, sellPrice: 63, baseStats: { str: 3, vit: 2 }, description: 'Heavy iron gloves.' },
    { catalogId: 'glove_assassin', itemName: 'Assassin Gloves', itemType: 'gloves', rarity: 'rare', itemLevel: 6, buyPrice: 750, sellPrice: 188, baseStats: { agi: 6, luk: 4 }, description: 'Precise and silent.', specialEffect: '+5% crit chance' },
    { catalogId: 'glove_berserker', itemName: 'Berserker Gauntlets', itemType: 'gloves', rarity: 'epic', itemLevel: 10, buyPrice: 2000, sellPrice: 500, baseStats: { str: 10, agi: 5, luk: 3 }, description: 'Rage-infused.', specialEffect: '+8% attack speed' },

    // ── LEGS ─────────────────────────────────────────────────
    { catalogId: 'legs_cloth_pants', itemName: 'Cloth Pants', itemType: 'legs', rarity: 'common', itemLevel: 1, buyPrice: 90, sellPrice: 23, baseStats: { vit: 2, end: 1 }, description: 'Basic leg cover.' },
    { catalogId: 'legs_chain_leggings', itemName: 'Chain Leggings', itemType: 'legs', rarity: 'uncommon', itemLevel: 3, buyPrice: 320, sellPrice: 80, baseStats: { vit: 4, end: 3 }, description: 'Flexible chain protection.' },
    { catalogId: 'legs_shadow_pants', itemName: 'Shadow Leggings', itemType: 'legs', rarity: 'rare', itemLevel: 6, buyPrice: 800, sellPrice: 200, baseStats: { agi: 7, luk: 3, vit: 3 }, description: 'Move without sound.', specialEffect: '+5% evasion' },
    { catalogId: 'legs_titan_greaves', itemName: 'Titan Greaves', itemType: 'legs', rarity: 'epic', itemLevel: 10, buyPrice: 2200, sellPrice: 550, baseStats: { vit: 12, end: 6, str: 4 }, description: 'Immovable legs.', specialEffect: '+8% stun resist' },

    // ── BOOTS ────────────────────────────────────────────────
    { catalogId: 'boot_sandals', itemName: 'Leather Sandals', itemType: 'boots', rarity: 'common', itemLevel: 1, buyPrice: 70, sellPrice: 18, baseStats: { agi: 2 }, description: 'Light footwear.' },
    { catalogId: 'boot_iron_treads', itemName: 'Iron Treads', itemType: 'boots', rarity: 'uncommon', itemLevel: 3, buyPrice: 260, sellPrice: 65, baseStats: { agi: 3, end: 2 }, description: 'Heavy but stable.' },
    { catalogId: 'boot_windwalkers', itemName: 'Windwalker Boots', itemType: 'boots', rarity: 'rare', itemLevel: 6, buyPrice: 780, sellPrice: 195, baseStats: { agi: 7, luk: 3 }, description: 'Fast as the wind.', specialEffect: '+5% movement speed' },
    { catalogId: 'boot_titan_stompers', itemName: 'Titan Stompers', itemType: 'boots', rarity: 'epic', itemLevel: 10, buyPrice: 2100, sellPrice: 525, baseStats: { vit: 8, end: 6, agi: 4 }, description: 'Each step shakes the ground.', specialEffect: '+8% knockback resist' },

    // ── ACCESSORIES ──────────────────────────────────────────
    { catalogId: 'acc_wooden_shield', itemName: 'Wooden Shield', itemType: 'accessory', rarity: 'common', itemLevel: 1, buyPrice: 90, sellPrice: 23, baseStats: { vit: 2, end: 1 }, description: 'Basic shield.' },
    { catalogId: 'acc_iron_shield', itemName: 'Iron Shield', itemType: 'accessory', rarity: 'uncommon', itemLevel: 3, buyPrice: 300, sellPrice: 75, baseStats: { vit: 4, end: 3 }, description: 'Solid iron defense.' },
    { catalogId: 'acc_magic_orb', itemName: 'Arcane Orb', itemType: 'accessory', rarity: 'rare', itemLevel: 6, buyPrice: 850, sellPrice: 213, baseStats: { int: 6, wis: 4 }, description: 'Amplifies magical power.', specialEffect: '+5% spell crit' },

    // ── AMULETS ──────────────────────────────────────────────
    { catalogId: 'amu_copper_chain', itemName: 'Copper Chain', itemType: 'amulet', rarity: 'common', itemLevel: 1, buyPrice: 80, sellPrice: 20, baseStats: { cha: 2 }, description: 'A simple necklace.' },
    { catalogId: 'amu_silver_pendant', itemName: 'Silver Pendant', itemType: 'amulet', rarity: 'uncommon', itemLevel: 3, buyPrice: 300, sellPrice: 75, baseStats: { wis: 3, cha: 2 }, description: 'Gleams in moonlight.' },
    { catalogId: 'amu_phoenix_heart', itemName: 'Phoenix Heart Amulet', itemType: 'amulet', rarity: 'epic', itemLevel: 10, buyPrice: 2400, sellPrice: 600, baseStats: { vit: 8, wis: 6, cha: 4 }, description: 'Burns with inner fire.', specialEffect: 'Revive once per battle with 20% HP' },

    // ── BELTS ────────────────────────────────────────────────
    { catalogId: 'belt_rope', itemName: 'Rope Belt', itemType: 'belt', rarity: 'common', itemLevel: 1, buyPrice: 50, sellPrice: 13, baseStats: { end: 2 }, description: 'Keeps things together.' },
    { catalogId: 'belt_leather', itemName: 'Leather Belt', itemType: 'belt', rarity: 'uncommon', itemLevel: 3, buyPrice: 220, sellPrice: 55, baseStats: { end: 3, vit: 2 }, description: 'Sturdy waist protection.' },
    { catalogId: 'belt_titan', itemName: 'Titan Belt', itemType: 'belt', rarity: 'rare', itemLevel: 7, buyPrice: 900, sellPrice: 225, baseStats: { end: 6, vit: 4, str: 3 }, description: 'Girdle of immense power.', specialEffect: '+5% max stamina' },

    // ── RINGS ────────────────────────────────────────────────
    { catalogId: 'ring_copper', itemName: 'Copper Ring', itemType: 'ring', rarity: 'common', itemLevel: 1, buyPrice: 60, sellPrice: 15, baseStats: { luk: 2 }, description: 'A plain copper band.' },
    { catalogId: 'ring_silver', itemName: 'Silver Ring', itemType: 'ring', rarity: 'uncommon', itemLevel: 3, buyPrice: 250, sellPrice: 63, baseStats: { luk: 3, agi: 2 }, description: 'Polished silver.' },
    { catalogId: 'ring_blood_ruby', itemName: 'Blood Ruby Ring', itemType: 'ring', rarity: 'rare', itemLevel: 7, buyPrice: 950, sellPrice: 238, baseStats: { str: 5, luk: 4, vit: 3 }, description: 'Pulses with crimson light.', specialEffect: '+3% lifesteal' },
    { catalogId: 'ring_void', itemName: 'Void Ring', itemType: 'ring', rarity: 'epic', itemLevel: 10, buyPrice: 2300, sellPrice: 575, baseStats: { int: 8, luk: 6, wis: 4 }, description: 'Bends reality around the wearer.', specialEffect: '+10% magic penetration' },

    // ── NECKLACES ────────────────────────────────────────────
    { catalogId: 'neck_bone_charm', itemName: 'Bone Charm', itemType: 'necklace', rarity: 'common', itemLevel: 1, buyPrice: 70, sellPrice: 18, baseStats: { wis: 2 }, description: 'Crude but effective.' },
    { catalogId: 'neck_emerald', itemName: 'Emerald Necklace', itemType: 'necklace', rarity: 'uncommon', itemLevel: 4, buyPrice: 320, sellPrice: 80, baseStats: { wis: 3, vit: 2 }, description: 'Green gem radiates life.' },
    { catalogId: 'neck_dragon_tooth', itemName: 'Dragon Tooth Necklace', itemType: 'necklace', rarity: 'rare', itemLevel: 7, buyPrice: 900, sellPrice: 225, baseStats: { str: 5, vit: 4, cha: 3 }, description: 'Taken from a slain dragon.', specialEffect: '+5% intimidation' },

    // ── RELICS ───────────────────────────────────────────────
    { catalogId: 'relic_old_coin', itemName: 'Ancient Coin', itemType: 'relic', rarity: 'uncommon', itemLevel: 3, buyPrice: 300, sellPrice: 75, baseStats: { luk: 4 }, description: 'Brings good fortune.' },
    { catalogId: 'relic_skull', itemName: 'Crystal Skull', itemType: 'relic', rarity: 'rare', itemLevel: 7, buyPrice: 1000, sellPrice: 250, baseStats: { int: 6, wis: 4 }, description: 'Whispers forgotten knowledge.', specialEffect: '+5% XP gain' },
    { catalogId: 'relic_orb_of_ages', itemName: 'Orb of Ages', itemType: 'relic', rarity: 'legendary', itemLevel: 15, buyPrice: 7500, sellPrice: 1875, baseStats: { int: 15, wis: 12, luk: 8 }, description: 'Contains the wisdom of millennia.', specialEffect: '+15% all magic, +10% XP' },

    // ── CONSUMABLES (Stamina Potions) ───────────────────────
    { catalogId: 'stamina_potion_small', itemName: 'Small Stamina Potion', itemType: 'consumable', rarity: 'common', itemLevel: 1, buyPrice: 100, sellPrice: 25, baseStats: {}, description: 'Restores 30 stamina.', specialEffect: '+30 stamina' },
    { catalogId: 'stamina_potion_medium', itemName: 'Medium Stamina Potion', itemType: 'consumable', rarity: 'uncommon', itemLevel: 1, buyPrice: 250, sellPrice: 63, baseStats: {}, description: 'Restores 60 stamina.', specialEffect: '+60 stamina' },
    { catalogId: 'stamina_potion_large', itemName: 'Large Stamina Potion', itemType: 'consumable', rarity: 'rare', itemLevel: 1, buyPrice: 500, sellPrice: 125, baseStats: {}, description: 'Fully restores stamina to maximum.', specialEffect: 'Full stamina restore' },

    // ── CONSUMABLES (Health Potions) ────────────────────────
    { catalogId: 'health_potion_small', itemName: 'Small Health Potion', itemType: 'consumable', rarity: 'common', itemLevel: 1, buyPrice: 150, sellPrice: 38, baseStats: {}, description: 'Restores 25% of max HP.', specialEffect: '+25% HP' },
    { catalogId: 'health_potion_medium', itemName: 'Medium Health Potion', itemType: 'consumable', rarity: 'uncommon', itemLevel: 1, buyPrice: 350, sellPrice: 88, baseStats: {}, description: 'Restores 50% of max HP.', specialEffect: '+50% HP' },
    { catalogId: 'health_potion_large', itemName: 'Large Health Potion', itemType: 'consumable', rarity: 'rare', itemLevel: 1, buyPrice: 700, sellPrice: 175, baseStats: {}, description: 'Fully restores HP.', specialEffect: 'Full HP restore' },
  ]

  let itemsCreated = 0
  let itemsSkipped = 0

  for (const item of ITEMS) {
    const existing = await prisma.item.findUnique({ where: { catalogId: item.catalogId } })
    if (existing) { itemsSkipped++; continue }

    await prisma.item.create({
      data: {
        catalogId: item.catalogId,
        itemName: item.itemName,
        itemType: item.itemType,
        rarity: item.rarity,
        itemLevel: item.itemLevel,
        buyPrice: item.buyPrice,
        sellPrice: item.sellPrice,
        baseStats: item.baseStats,
        description: item.description,
        specialEffect: item.specialEffect ?? null,
        classRestriction: item.classRestriction ?? null,
        setName: item.setName ?? null,
      },
    })
    itemsCreated++
  }

  console.log(`\n🗡️  Items: ${itemsCreated} created, ${itemsSkipped} already existed.`)
}

main()
  .catch((e) => { console.error(e); process.exit(1) })
  .finally(() => prisma.$disconnect())
