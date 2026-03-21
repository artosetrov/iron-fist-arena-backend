// =============================================================================
// seed-dungeons.ts — Seed 7 new GDD dungeons (after existing 3)
// Run: npx tsx prisma/seed-dungeons.ts
// =============================================================================

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// ---------------------------------------------------------------------------
// Boss Ability Catalog (20 unique abilities from GDD §3)
// ---------------------------------------------------------------------------

interface AbilityDef {
  name: string;
  abilityType: 'physical' | 'magical' | 'buff';
  damage: number;        // multiplier × 100 for int storage (e.g. 2.2 → 220)
  cooldown: number;
  specialEffect: string; // JSON-like description
  description: string;
}

const ABILITY_CATALOG: Record<string, AbilityDef> = {
  // Physical (7)
  crushing_blow: {
    name: 'Crushing Blow',
    abilityType: 'physical',
    damage: 220,
    cooldown: 4,
    specialEffect: 'armor_break_30',
    description: 'Heavy strike that breaks armor. High physical damage, -30% armor for one hit.',
  },
  tail_swipe: {
    name: 'Tail Swipe',
    abilityType: 'physical',
    damage: 140,
    cooldown: 3,
    specialEffect: '2_hits',
    description: 'Double tail strike. Two quick hits with medium multiplier.',
  },
  frenzy: {
    name: 'Frenzy',
    abilityType: 'physical',
    damage: 120,
    cooldown: 5,
    specialEffect: '3_hits',
    description: 'Series of three quick strikes. Less per hit, high total damage.',
  },
  ground_slam: {
    name: 'Ground Slam',
    abilityType: 'physical',
    damage: 250,
    cooldown: 5,
    specialEffect: 'stun_25_1t',
    description: 'Ground pound, stuns nearby. High damage, 25% stun chance for 1 turn.',
  },
  impale: {
    name: 'Impale',
    abilityType: 'physical',
    damage: 200,
    cooldown: 4,
    specialEffect: 'bleed_35_3t',
    description: 'Precise thrust causing bleeding. Good damage, 35% bleed for 3 turns.',
  },
  charge: {
    name: 'Charge',
    abilityType: 'physical',
    damage: 280,
    cooldown: 6,
    specialEffect: 'first_strike_only',
    description: 'Forward rush. Very high damage, only if boss acts first in turn.',
  },
  rend: {
    name: 'Rend',
    abilityType: 'physical',
    damage: 160,
    cooldown: 3,
    specialEffect: 'bleed_40_3t_crit_10',
    description: 'Tearing attack with enhanced crit. Medium damage, 40% bleed 3t, +10% crit.',
  },
  // Magical (7)
  shadow_bolt: {
    name: 'Shadow Bolt',
    abilityType: 'magical',
    damage: 240,
    cooldown: 3,
    specialEffect: 'weaken_20_2t',
    description: 'Dark projectile. High magical damage, 20% weaken for 2 turns.',
  },
  frost_breath: {
    name: 'Frost Breath',
    abilityType: 'magical',
    damage: 200,
    cooldown: 4,
    specialEffect: 'slow_30_2t',
    description: 'Cold breath. Magical damage, 30% slow for 2 turns.',
  },
  fire_wave: {
    name: 'Fire Wave',
    abilityType: 'magical',
    damage: 180,
    cooldown: 4,
    specialEffect: '2_hits_burn_25_3t',
    description: 'Double fire wave. Two magical hits, 25% burn for 3 turns.',
  },
  poison_cloud: {
    name: 'Poison Cloud',
    abilityType: 'magical',
    damage: 140,
    cooldown: 5,
    specialEffect: 'poison_45_4t',
    description: 'Poison cloud. Medium magical damage, 45% poison for 4 turns.',
  },
  life_drain: {
    name: 'Life Drain',
    abilityType: 'magical',
    damage: 200,
    cooldown: 5,
    specialEffect: 'boss_regen_100_2t',
    description: 'Drains life and heals boss. Damage to target + 100% boss regen for 2 turns.',
  },
  chain_lightning: {
    name: 'Chain Lightning',
    abilityType: 'magical',
    damage: 150,
    cooldown: 5,
    specialEffect: '3_hits_stun_15_1t',
    description: 'Lightning strikes multiple times. Three magical hits, 15% stun for 1 turn.',
  },
  arcane_burst: {
    name: 'Arcane Burst',
    abilityType: 'magical',
    damage: 320,
    cooldown: 6,
    specialEffect: 'none',
    description: 'One massive magical explosion. Very high magical damage, no extra effects.',
  },
  // Buffs (6)
  enrage: {
    name: 'Enrage',
    abilityType: 'buff',
    damage: 0,
    cooldown: 7,
    specialEffect: 'str_35',
    description: 'Boss enters rage, boosting strength. +35% STR self.',
  },
  stone_skin: {
    name: 'Stone Skin',
    abilityType: 'buff',
    damage: 0,
    cooldown: 6,
    specialEffect: 'armor_60',
    description: 'Skin hardens like stone. +60% armor for several turns.',
  },
  dark_shield: {
    name: 'Dark Shield',
    abilityType: 'buff',
    damage: 0,
    cooldown: 6,
    specialEffect: 'magic_resist_50',
    description: 'Dark protection. +50% magic resistance.',
  },
  regeneration: {
    name: 'Regeneration',
    abilityType: 'buff',
    damage: 0,
    cooldown: 7,
    specialEffect: 'regen_8',
    description: 'Activates health recovery. +8% boss regeneration.',
  },
  battle_roar: {
    name: 'Battle Roar',
    abilityType: 'buff',
    damage: 0,
    cooldown: 6,
    specialEffect: 'str_20_stun_20_1t',
    description: 'Deafening roar: buff boss and fear target. +20% STR self, 20% stun 1t.',
  },
  haste: {
    name: 'Haste',
    abilityType: 'buff',
    damage: 0,
    cooldown: 7,
    specialEffect: 'dodge_35_3t',
    description: 'Sharp speed increase. +35% dodge for boss for 3 turns.',
  },
};

// ---------------------------------------------------------------------------
// Dungeon & Boss Definitions (GDD dungeons 3–9, since 0–2 already exist)
// ---------------------------------------------------------------------------

interface BossDef {
  name: string;
  description: string;
  level: number;
  statMultiplier: number;
  stance: string;
  abilities: string[]; // keys from ABILITY_CATALOG
}

interface DungeonDef {
  slug: string;
  name: string;
  subtitle: string;
  levelReq: number;
  energyCost: number;
  sortOrder: number;
  bosses: BossDef[];
}

// HP formula: base_hp * statMultiplier * levelScale
// Using the existing pattern from volcanic_forge (level 20 → 1000 HP, level 30 → 3000 HP)
// Approx: HP = 120 * level * statMultiplier
function calcBossHp(level: number, mult: number): number {
  return Math.round(120 * level * mult);
}

function calcBossDamage(level: number, mult: number): number {
  return Math.round((10 + level * 2.5) * mult);
}

function calcBossDefense(level: number, mult: number): number {
  return Math.round((6 + level * 2) * mult);
}

function calcBossSpeed(level: number, mult: number): number {
  return Math.round((8 + level * 1.8) * mult);
}

const NEW_DUNGEONS: DungeonDef[] = [
  // =========================================================================
  // 3. Fungal Grotto (after volcanic_forge, sortOrder=3)
  // =========================================================================
  {
    slug: 'fungal_grotto',
    name: 'Fungal Grotto',
    subtitle: 'The spores whisper secrets',
    levelReq: 30,
    energyCost: 14,
    sortOrder: 3,
    bosses: [
      { name: 'Spore Sprite', description: 'Tiny, glowing, toxic.', level: 10, statMultiplier: 0.80, stance: 'assassin', abilities: ['poison_cloud', 'haste', 'tail_swipe'] },
      { name: 'Mushroom Brute', description: 'Thick cap. Thicker skull.', level: 11, statMultiplier: 0.85, stance: 'aggressive', abilities: ['ground_slam', 'stone_skin', 'enrage'] },
      { name: 'Vine Strangler', description: 'Wraps around legs. Squeezes.', level: 12, statMultiplier: 0.90, stance: 'berserker', abilities: ['rend', 'poison_cloud', 'crushing_blow'] },
      { name: 'Poison Toad', description: 'One lick and you see colors.', level: 12, statMultiplier: 0.95, stance: 'defensive', abilities: ['poison_cloud', 'tail_swipe', 'regeneration'] },
      { name: 'Mycelium Golem', description: 'A walking ecosystem.', level: 13, statMultiplier: 1.00, stance: 'tank', abilities: ['ground_slam', 'regeneration', 'stone_skin'] },
      { name: 'Rot Witch', description: 'Brews potions from decay.', level: 13, statMultiplier: 1.05, stance: 'defensive', abilities: ['poison_cloud', 'life_drain', 'dark_shield'] },
      { name: 'Fungal Hydra', description: 'Cut one head — two sprout. Covered in mold.', level: 14, statMultiplier: 1.10, stance: 'berserker', abilities: ['frenzy', 'poison_cloud', 'regeneration'] },
      { name: 'Sporeling Hive Mind', description: 'Thousands of tiny spores, one terrible will.', level: 15, statMultiplier: 1.15, stance: 'defensive', abilities: ['chain_lightning', 'poison_cloud', 'dark_shield'] },
      { name: 'Blight Treant', description: 'The ancient tree fell to corruption.', level: 15, statMultiplier: 1.20, stance: 'aggressive', abilities: ['crushing_blow', 'regeneration', 'enrage'] },
      { name: 'The Overgrowth', description: 'The grotto itself fights back.', level: 17, statMultiplier: 1.35, stance: 'berserker', abilities: ['frenzy', 'poison_cloud', 'regeneration'] },
    ],
  },
  // =========================================================================
  // 4. Scorched Mines
  // =========================================================================
  {
    slug: 'scorched_mines',
    name: 'Scorched Mines',
    subtitle: 'Heat rises from below',
    levelReq: 35,
    energyCost: 16,
    sortOrder: 4,
    bosses: [
      { name: 'Ember Rat', description: 'Fast, burning, bites.', level: 15, statMultiplier: 0.90, stance: 'assassin', abilities: ['fire_wave', 'haste', 'rend'] },
      { name: 'Magma Slime', description: 'Bubbles and burns everything it touches.', level: 16, statMultiplier: 0.95, stance: 'defensive', abilities: ['fire_wave', 'regeneration', 'stone_skin'] },
      { name: 'Mine Foreman', description: 'Swings a red-hot pickaxe.', level: 17, statMultiplier: 1.00, stance: 'aggressive', abilities: ['crushing_blow', 'enrage', 'impale'] },
      { name: 'Lava Beetle', description: 'Its shell is molten rock.', level: 17, statMultiplier: 1.05, stance: 'tank', abilities: ['fire_wave', 'stone_skin', 'charge'] },
      { name: 'Cinder Elemental', description: 'Pure fire given hateful form.', level: 18, statMultiplier: 1.10, stance: 'aggressive', abilities: ['fire_wave', 'arcane_burst', 'enrage'] },
      { name: 'Soot Dragon Whelp', description: 'Not full-grown. Still very hot.', level: 18, statMultiplier: 1.15, stance: 'berserker', abilities: ['fire_wave', 'tail_swipe', 'frenzy'] },
      { name: 'Obsidian Guardian', description: 'Ancient golem fused from volcanic glass.', level: 19, statMultiplier: 1.20, stance: 'tank', abilities: ['ground_slam', 'stone_skin', 'crushing_blow'] },
      { name: 'Flame Witch', description: 'Dances through fire. Controls it.', level: 20, statMultiplier: 1.25, stance: 'defensive', abilities: ['fire_wave', 'arcane_burst', 'dark_shield'] },
      { name: 'Infernal Siege Engine', description: 'A mining machine possessed by fire spirits.', level: 20, statMultiplier: 1.30, stance: 'aggressive', abilities: ['fire_wave', 'crushing_blow', 'enrage'] },
      { name: 'Pyrax the Molten King', description: 'The mines bow to him. So does the lava.', level: 22, statMultiplier: 1.45, stance: 'berserker', abilities: ['fire_wave', 'enrage', 'frenzy'] },
    ],
  },
  // =========================================================================
  // 5. Frozen Abyss
  // =========================================================================
  {
    slug: 'frozen_abyss',
    name: 'Frozen Abyss',
    subtitle: 'Where even fire freezes',
    levelReq: 40,
    energyCost: 18,
    sortOrder: 5,
    bosses: [
      { name: 'Frost Wisp', description: 'A floating shard of cold.', level: 20, statMultiplier: 1.00, stance: 'assassin', abilities: ['frost_breath', 'haste', 'shadow_bolt'] },
      { name: 'Ice Wolf', description: 'Hunts in frozen packs.', level: 21, statMultiplier: 1.05, stance: 'berserker', abilities: ['rend', 'frost_breath', 'charge'] },
      { name: 'Glacier Troll', description: 'Covered in ice. Hits like an avalanche.', level: 22, statMultiplier: 1.10, stance: 'tank', abilities: ['ground_slam', 'frost_breath', 'stone_skin'] },
      { name: 'Frozen Sentinel', description: 'A soldier trapped in ice, still fighting.', level: 22, statMultiplier: 1.15, stance: 'tank', abilities: ['frost_breath', 'stone_skin', 'impale'] },
      { name: 'Blizzard Harpy', description: 'Shrieks bring hail.', level: 23, statMultiplier: 1.20, stance: 'assassin', abilities: ['frost_breath', 'chain_lightning', 'haste'] },
      { name: 'Crystal Golem', description: 'Each facet reflects a different death.', level: 23, statMultiplier: 1.25, stance: 'tank', abilities: ['frost_breath', 'stone_skin', 'crushing_blow'] },
      { name: 'Frost Wyvern', description: 'Breathes freezing fog.', level: 24, statMultiplier: 1.30, stance: 'berserker', abilities: ['frost_breath', 'tail_swipe', 'frenzy'] },
      { name: 'Ice Lich', description: 'Master of cold magic.', level: 25, statMultiplier: 1.35, stance: 'defensive', abilities: ['frost_breath', 'arcane_burst', 'dark_shield'] },
      { name: 'Permafrost Colossus', description: "Hasn't moved in centuries. Until now.", level: 25, statMultiplier: 1.40, stance: 'aggressive', abilities: ['frost_breath', 'ground_slam', 'enrage'] },
      { name: 'Glacius the Eternal', description: 'Winter incarnate. The abyss itself.', level: 27, statMultiplier: 1.55, stance: 'aggressive', abilities: ['frost_breath', 'arcane_burst', 'enrage'] },
    ],
  },
  // =========================================================================
  // 6. Realm of Light
  // =========================================================================
  {
    slug: 'realm_of_light',
    name: 'Realm of Light',
    subtitle: 'Where light burns brighter than fire',
    levelReq: 45,
    energyCost: 20,
    sortOrder: 6,
    bosses: [
      { name: 'Light Sprite', description: 'Blindingly fast, blindingly bright.', level: 25, statMultiplier: 1.10, stance: 'assassin', abilities: ['arcane_burst', 'haste', 'chain_lightning', 'rend'] },
      { name: 'Radiant Archer', description: 'Arrows of pure light.', level: 26, statMultiplier: 1.15, stance: 'assassin', abilities: ['impale', 'arcane_burst', 'haste', 'rend'] },
      { name: 'Crystal Beast', description: 'Reflects attacks as beams.', level: 27, statMultiplier: 1.20, stance: 'defensive', abilities: ['arcane_burst', 'stone_skin', 'crushing_blow', 'dark_shield'] },
      { name: 'Solar Monk', description: 'Channels the sun through fists.', level: 27, statMultiplier: 1.25, stance: 'berserker', abilities: ['crushing_blow', 'enrage', 'arcane_burst', 'haste'] },
      { name: 'Golden Golem', description: 'Forged from holy metal.', level: 28, statMultiplier: 1.30, stance: 'tank', abilities: ['ground_slam', 'stone_skin', 'crushing_blow', 'regeneration'] },
      { name: 'Seraph Guardian', description: 'An angel that asks no questions.', level: 28, statMultiplier: 1.35, stance: 'defensive', abilities: ['arcane_burst', 'chain_lightning', 'dark_shield', 'enrage'] },
      { name: 'Prism Dragon', description: 'Each scale bends light into weapons.', level: 29, statMultiplier: 1.40, stance: 'berserker', abilities: ['arcane_burst', 'fire_wave', 'frost_breath', 'tail_swipe'] },
      { name: 'Light Weaver', description: 'Stitches reality with radiance.', level: 30, statMultiplier: 1.45, stance: 'defensive', abilities: ['arcane_burst', 'chain_lightning', 'regeneration', 'dark_shield'] },
      { name: 'Solar Colossus', description: "The temple's last defender.", level: 30, statMultiplier: 1.50, stance: 'tank', abilities: ['ground_slam', 'arcane_burst', 'stone_skin', 'enrage'] },
      { name: 'The Heart of the Ray', description: 'An artifact given life. Burning judgment.', level: 32, statMultiplier: 1.65, stance: 'aggressive', abilities: ['arcane_burst', 'fire_wave', 'enrage', 'frenzy'] },
    ],
  },
  // =========================================================================
  // 7. Shadow Realm
  // =========================================================================
  {
    slug: 'shadow_realm',
    name: 'Shadow Realm',
    subtitle: 'Where the darkness stares back',
    levelReq: 50,
    energyCost: 22,
    sortOrder: 7,
    bosses: [
      { name: 'Shadow Wisp', description: 'A fragment of a nightmare.', level: 30, statMultiplier: 1.20, stance: 'assassin', abilities: ['shadow_bolt', 'haste', 'dark_shield', 'life_drain'] },
      { name: 'Dark Stalker', description: 'Hunts by sound. Silent footsteps.', level: 31, statMultiplier: 1.25, stance: 'assassin', abilities: ['shadow_bolt', 'charge', 'haste', 'rend'] },
      { name: 'Void Spider', description: 'Webs that devour light.', level: 32, statMultiplier: 1.30, stance: 'assassin', abilities: ['poison_cloud', 'shadow_bolt', 'haste', 'tail_swipe'] },
      { name: 'Shade Knight', description: 'Your own silhouette, armored.', level: 32, statMultiplier: 1.35, stance: 'tank', abilities: ['shadow_bolt', 'stone_skin', 'impale', 'dark_shield'] },
      { name: 'Eclipse Wolf', description: 'Born from a sunless sky.', level: 33, statMultiplier: 1.40, stance: 'berserker', abilities: ['shadow_bolt', 'frenzy', 'charge', 'rend'] },
      { name: 'Nightborne Mage', description: 'Spells woven from absolute darkness.', level: 33, statMultiplier: 1.45, stance: 'defensive', abilities: ['shadow_bolt', 'arcane_burst', 'dark_shield', 'life_drain'] },
      { name: 'Abyss Hydra', description: 'Each head a different fear.', level: 34, statMultiplier: 1.50, stance: 'berserker', abilities: ['frenzy', 'shadow_bolt', 'poison_cloud', 'enrage'] },
      { name: 'Shadow Dragon', description: 'Breathes oblivion.', level: 35, statMultiplier: 1.55, stance: 'aggressive', abilities: ['shadow_bolt', 'arcane_burst', 'tail_swipe', 'enrage'] },
      { name: 'Void Colossus', description: 'Where it steps, nothing remains.', level: 35, statMultiplier: 1.60, stance: 'aggressive', abilities: ['shadow_bolt', 'ground_slam', 'stone_skin', 'enrage'] },
      { name: 'The Whispering Dark', description: 'Not a creature. A place. That hates.', level: 37, statMultiplier: 1.75, stance: 'aggressive', abilities: ['shadow_bolt', 'life_drain', 'arcane_burst', 'enrage'] },
    ],
  },
  // =========================================================================
  // 8. Clockwork Citadel
  // =========================================================================
  {
    slug: 'clockwork_citadel',
    name: 'Clockwork Citadel',
    subtitle: 'Gears never stop turning',
    levelReq: 55,
    energyCost: 24,
    sortOrder: 8,
    bosses: [
      { name: 'Gear Sprite', description: 'Tiny, fast, sparking.', level: 35, statMultiplier: 1.30, stance: 'assassin', abilities: ['chain_lightning', 'haste', 'tail_swipe', 'rend'] },
      { name: 'Clockwork Hound', description: 'Metal teeth, spring-loaded jaws.', level: 36, statMultiplier: 1.35, stance: 'berserker', abilities: ['frenzy', 'charge', 'rend', 'haste'] },
      { name: 'Piston Golem', description: 'Each punch backed by steam pressure.', level: 37, statMultiplier: 1.40, stance: 'tank', abilities: ['ground_slam', 'crushing_blow', 'stone_skin', 'enrage'] },
      { name: 'Sawblade Dancer', description: 'Spinning blades, deadly rhythm.', level: 37, statMultiplier: 1.45, stance: 'assassin', abilities: ['frenzy', 'rend', 'haste', 'impale'] },
      { name: 'Tesla Turret', description: 'Zaps anything that moves.', level: 38, statMultiplier: 1.50, stance: 'defensive', abilities: ['chain_lightning', 'arcane_burst', 'stone_skin', 'dark_shield'] },
      { name: 'Steam Knight', description: 'Hisses, clanks, annihilates.', level: 38, statMultiplier: 1.55, stance: 'tank', abilities: ['crushing_blow', 'stone_skin', 'charge', 'enrage'] },
      { name: 'Gear Dragon', description: 'Wings of interlocking cogs.', level: 39, statMultiplier: 1.60, stance: 'berserker', abilities: ['fire_wave', 'chain_lightning', 'tail_swipe', 'enrage'] },
      { name: 'Grand Mechanist', description: 'Builder of nightmares.', level: 40, statMultiplier: 1.65, stance: 'defensive', abilities: ['chain_lightning', 'arcane_burst', 'stone_skin', 'regeneration'] },
      { name: 'Siege Automaton', description: 'A walking fortress of brass and fury.', level: 40, statMultiplier: 1.70, stance: 'tank', abilities: ['ground_slam', 'crushing_blow', 'stone_skin', 'enrage'] },
      { name: 'The Grand Engine', description: "The citadel's heart. Infinite gears. One mind.", level: 42, statMultiplier: 1.85, stance: 'aggressive', abilities: ['chain_lightning', 'frenzy', 'enrage', 'stone_skin'] },
    ],
  },
  // =========================================================================
  // 9. Abyssal Depths
  // =========================================================================
  {
    slug: 'abyssal_depths',
    name: 'Abyssal Depths',
    subtitle: 'Beneath the world, something waits',
    levelReq: 60,
    energyCost: 26,
    sortOrder: 9,
    bosses: [
      { name: 'Depth Crawler', description: 'Skitters across the ocean floor.', level: 40, statMultiplier: 1.40, stance: 'assassin', abilities: ['poison_cloud', 'tail_swipe', 'haste', 'rend'] },
      { name: 'Angler Horror', description: 'Its light lures. Its jaws close.', level: 41, statMultiplier: 1.45, stance: 'berserker', abilities: ['life_drain', 'crushing_blow', 'dark_shield', 'frenzy'] },
      { name: 'Coral Golem', description: 'Living reef with a grudge.', level: 42, statMultiplier: 1.50, stance: 'tank', abilities: ['ground_slam', 'stone_skin', 'regeneration', 'crushing_blow'] },
      { name: 'Siren', description: 'Her song drowns reason.', level: 42, statMultiplier: 1.55, stance: 'defensive', abilities: ['shadow_bolt', 'life_drain', 'dark_shield', 'chain_lightning'] },
      { name: 'Kraken Spawn', description: 'One tentacle from something much larger.', level: 43, statMultiplier: 1.60, stance: 'berserker', abilities: ['frenzy', 'crushing_blow', 'ground_slam', 'enrage'] },
      { name: 'Abyssal Leviathan', description: 'A whale-sized predator with a temper.', level: 43, statMultiplier: 1.65, stance: 'aggressive', abilities: ['crushing_blow', 'ground_slam', 'enrage', 'regeneration'] },
      { name: 'Deep Sea Dragon', description: 'Scales covered in barnacles and fury.', level: 44, statMultiplier: 1.70, stance: 'berserker', abilities: ['frost_breath', 'tail_swipe', 'frenzy', 'enrage'] },
      { name: 'Drowned Admiral', description: 'Still commands a ghost fleet.', level: 45, statMultiplier: 1.75, stance: 'assassin', abilities: ['shadow_bolt', 'life_drain', 'impale', 'battle_roar'] },
      { name: 'Tidal Colossus', description: 'The ocean given legs.', level: 45, statMultiplier: 1.80, stance: 'tank', abilities: ['ground_slam', 'frost_breath', 'stone_skin', 'enrage'] },
      { name: 'Charybdis the Devourer', description: 'The abyss opens. Everything falls in.', level: 47, statMultiplier: 1.95, stance: 'aggressive', abilities: ['life_drain', 'frenzy', 'enrage', 'arcane_burst'] },
    ],
  },
  // =========================================================================
  // 10. Infernal Throne
  // =========================================================================
  {
    slug: 'infernal_throne',
    name: 'Infernal Throne',
    subtitle: 'The final descent into madness',
    levelReq: 65,
    energyCost: 30,
    sortOrder: 10,
    bosses: [
      { name: 'Imp Swarm', description: 'Small, vicious, everywhere.', level: 45, statMultiplier: 1.50, stance: 'berserker', abilities: ['frenzy', 'fire_wave', 'haste', 'rend'] },
      { name: 'Hellhound Alpha', description: 'Three heads, triple the fury.', level: 46, statMultiplier: 1.55, stance: 'aggressive', abilities: ['fire_wave', 'frenzy', 'charge', 'rend'] },
      { name: 'Flame Demoness', description: 'Beauty and annihilation.', level: 47, statMultiplier: 1.60, stance: 'defensive', abilities: ['fire_wave', 'arcane_burst', 'dark_shield', 'life_drain'] },
      { name: 'Iron Demon', description: 'Forged in infernal pits.', level: 47, statMultiplier: 1.65, stance: 'tank', abilities: ['crushing_blow', 'stone_skin', 'enrage', 'ground_slam'] },
      { name: 'Pit Fiend', description: 'Commander of lesser demons.', level: 48, statMultiplier: 1.70, stance: 'aggressive', abilities: ['fire_wave', 'battle_roar', 'enrage', 'frenzy'] },
      { name: 'Soul Reaver', description: 'Steals strength from the fallen.', level: 48, statMultiplier: 1.75, stance: 'assassin', abilities: ['life_drain', 'shadow_bolt', 'dark_shield', 'enrage'] },
      { name: 'Infernal Dragon', description: 'Fire made flesh, fury made scale.', level: 49, statMultiplier: 1.80, stance: 'berserker', abilities: ['fire_wave', 'tail_swipe', 'frenzy', 'enrage'] },
      { name: 'Dark Seraph', description: 'An angel that chose the wrong side.', level: 50, statMultiplier: 1.85, stance: 'defensive', abilities: ['shadow_bolt', 'arcane_burst', 'life_drain', 'dark_shield'] },
      { name: 'The Throne Guardian', description: 'The last line of defense. Absolute.', level: 50, statMultiplier: 1.90, stance: 'tank', abilities: ['ground_slam', 'stone_skin', 'enrage', 'crushing_blow'] },
      { name: 'Archfiend Malachar', description: 'He sits on the throne. He waits. He wins.', level: 52, statMultiplier: 2.10, stance: 'aggressive', abilities: ['fire_wave', 'arcane_burst', 'enrage', 'life_drain'] },
    ],
  },
];

// ---------------------------------------------------------------------------
// Main seed function
// ---------------------------------------------------------------------------

async function main() {
  console.log('🏰 Seeding 7 new GDD dungeons...\n');

  for (const dungeon of NEW_DUNGEONS) {
    // Check if already exists
    const existing = await prisma.dungeon.findUnique({ where: { slug: dungeon.slug } });
    if (existing) {
      console.log(`  ⏭️  ${dungeon.name} (${dungeon.slug}) already exists — skipping`);
      continue;
    }

    const created = await prisma.dungeon.create({
      data: {
        slug: dungeon.slug,
        name: dungeon.name,
        description: dungeon.subtitle,
        lore: dungeon.subtitle,
        levelReq: dungeon.levelReq,
        difficulty: 'normal',
        dungeonType: 'story',
        energyCost: dungeon.energyCost,
        isActive: true,
        sortOrder: dungeon.sortOrder,
        goldReward: 0,
        xpReward: 0,
        bosses: {
          create: dungeon.bosses.map((boss, i) => ({
            name: boss.name,
            bossType: boss.stance,
            level: boss.level,
            hp: calcBossHp(boss.level, boss.statMultiplier),
            damage: calcBossDamage(boss.level, boss.statMultiplier),
            defense: calcBossDefense(boss.level, boss.statMultiplier),
            speed: calcBossSpeed(boss.level, boss.statMultiplier),
            critChance: 5 + i * 0.5,
            description: boss.description,
            floorNumber: i + 1,
            sortOrder: i,
            abilities: {
              create: boss.abilities.map((abilityKey) => {
                const a = ABILITY_CATALOG[abilityKey];
                if (!a) throw new Error(`Unknown ability: ${abilityKey}`);
                return {
                  name: a.name,
                  abilityType: a.abilityType,
                  damage: a.damage,
                  cooldown: a.cooldown,
                  specialEffect: a.specialEffect,
                  description: a.description,
                };
              }),
            },
          })),
        },
      },
      include: {
        bosses: { include: { abilities: true } },
      },
    });

    const totalAbilities = created.bosses.reduce((sum, b) => sum + b.abilities.length, 0);
    console.log(`  ✅ ${created.name} — ${created.bosses.length} bosses, ${totalAbilities} abilities`);
  }

  console.log('\n🎉 Done! 7 dungeons seeded.');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => await prisma.$disconnect());
