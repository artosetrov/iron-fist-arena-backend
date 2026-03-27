// =============================================================================
// dungeon.ts — Dungeon floor generation
// =============================================================================

// --- Types ---

export interface BossAbility {
  name: string;
  type: 'damage_aoe' | 'heal_self' | 'buff_self' | 'debuff_player' | 'summon' | 'enrage';
  trigger: 'hp_threshold' | 'every_n_turns' | 'on_start';
  triggerValue: number; // HP% threshold or turn interval
  power: number;        // Effect magnitude (damage%, heal%, etc.)
  description: string;
}

export interface Enemy {
  id: string;
  name: string;
  level: number;
  maxHp: number;
  str: number;
  agi: number;
  armor: number;
  magicResist: number;
  isBoss: boolean;
  abilities?: BossAbility[];
  damageType?: 'physical' | 'magical' | 'poison';
}

export type RoomType = 'combat' | 'treasure' | 'trap' | 'shrine' | 'merchant' | 'rest';

export interface DungeonRoom {
  type: RoomType;
  floor: number;
  // For combat rooms
  enemies?: Enemy[];
  isBoss?: boolean;
  // For treasure rooms
  goldReward?: number;
  itemChance?: number;
  // For trap rooms
  damagePercent?: number; // % of max HP
  // For shrine rooms
  buffType?: 'attack' | 'defense' | 'speed' | 'heal';
  buffAmount?: number;
  // For rest rooms
  healPercent?: number;
}

export interface DungeonFloor {
  enemies: Enemy[];
  isBoss: boolean;
  room?: DungeonRoom; // Variety room data (null = standard combat)
}

// --- Configuration ---

const DIFFICULTY_MULTIPLIERS: Record<string, number> = {
  easy: 0.8,
  normal: 1.0,
  hard: 1.4,
};

// Boss data per dungeon, matching iOS client definitions exactly.
// Each dungeon has 10 bosses. floor 1 = boss[0], floor 2 = boss[1], etc.
const DUNGEON_BOSSES: Record<string, Array<{ name: string; level: number; hp: number }>> = {
  training_camp: [
    { name: 'Straw Dummy', level: 1, hp: 250 },
    { name: 'Rusty Golem', level: 2, hp: 320 },
    { name: 'Cave Spider', level: 3, hp: 380 },
    { name: 'Bone Warrior', level: 4, hp: 450 },
    { name: 'Fire Imp', level: 5, hp: 500 },
    { name: 'Scarecrow Mage', level: 6, hp: 580 },
    { name: 'Shadow Stalker', level: 7, hp: 650 },
    { name: 'Iron Guardian', level: 8, hp: 750 },
    { name: 'Plague Bearer', level: 9, hp: 850 },
    { name: 'Arena Warden', level: 10, hp: 1000 },
  ],
  desecrated_catacombs: [
    { name: 'Tomb Rat King', level: 10, hp: 600 },
    { name: 'Crypt Walker', level: 11, hp: 700 },
    { name: 'Ghoul Brute', level: 12, hp: 800 },
    { name: 'Banshee', level: 13, hp: 880 },
    { name: 'Skeleton Knight', level: 14, hp: 950 },
    { name: 'Corpse Weaver', level: 15, hp: 1050 },
    { name: 'Wraith Assassin', level: 16, hp: 1150 },
    { name: 'Bone Colossus', level: 17, hp: 1300 },
    { name: 'Necro Priest', level: 18, hp: 1450 },
    { name: 'Lich King Verath', level: 20, hp: 1800 },
  ],
  volcanic_forge: [
    { name: 'Lava Crawler', level: 20, hp: 1000 },
    { name: 'Ember Sprite', level: 21, hp: 1100 },
    { name: 'Slag Brute', level: 22, hp: 1250 },
    { name: 'Flame Hound', level: 23, hp: 1350 },
    { name: 'Molten Shaman', level: 24, hp: 1500 },
    { name: 'Obsidian Knight', level: 25, hp: 1650 },
    { name: 'Furnace Worm', level: 26, hp: 1800 },
    { name: 'Cinderlord', level: 27, hp: 2000 },
    { name: 'Magma Titan', level: 28, hp: 2300 },
    { name: 'Pyrox the Eternal', level: 30, hp: 3000 },
  ],
};

// --- Boss Abilities per dungeon (bosses 5 and 10 get special mechanics) ---
const BOSS_ABILITIES: Record<string, Record<number, BossAbility[]>> = {
  training_camp: {
    4: [{ name: 'Bone Shield', type: 'buff_self', trigger: 'hp_threshold', triggerValue: 50, power: 30, description: 'Raises armor by 30% below 50% HP' }],
    9: [
      { name: 'Arena Challenge', type: 'enrage', trigger: 'hp_threshold', triggerValue: 30, power: 50, description: 'Attack +50% below 30% HP' },
      { name: 'Warden\'s Slam', type: 'damage_aoe', trigger: 'every_n_turns', triggerValue: 3, power: 25, description: 'Deals 25% of max HP as damage every 3 turns' },
    ],
  },
  desecrated_catacombs: {
    4: [{ name: 'Soul Drain', type: 'heal_self', trigger: 'every_n_turns', triggerValue: 4, power: 15, description: 'Heals 15% HP every 4 turns' }],
    5: [{ name: 'Corpse Explosion', type: 'damage_aoe', trigger: 'hp_threshold', triggerValue: 40, power: 30, description: 'Explodes for 30% max HP damage at 40% HP' }],
    9: [
      { name: 'Undead Army', type: 'summon', trigger: 'hp_threshold', triggerValue: 60, power: 2, description: 'Summons 2 skeleton minions at 60% HP' },
      { name: 'Death Pact', type: 'enrage', trigger: 'hp_threshold', triggerValue: 20, power: 75, description: 'Attack +75% below 20% HP (final stand)' },
    ],
  },
  volcanic_forge: {
    4: [{ name: 'Lava Pool', type: 'debuff_player', trigger: 'on_start', triggerValue: 0, power: 10, description: 'Player takes 10% fire damage each turn' }],
    6: [{ name: 'Forge Armor', type: 'buff_self', trigger: 'hp_threshold', triggerValue: 50, power: 50, description: 'Armor +50% below 50% HP' }],
    9: [
      { name: 'Volcanic Eruption', type: 'damage_aoe', trigger: 'every_n_turns', triggerValue: 2, power: 20, description: '20% max HP fire damage every 2 turns' },
      { name: 'Molten Core', type: 'heal_self', trigger: 'hp_threshold', triggerValue: 25, power: 20, description: 'Heals 20% HP at 25% HP (once)' },
      { name: 'Eternal Flame', type: 'enrage', trigger: 'hp_threshold', triggerValue: 15, power: 100, description: 'Attack doubles below 15% HP' },
    ],
  },
};

// --- Variety Room Generation ---
// Non-combat rooms appear on specific floors to break monotony
const VARIETY_ROOM_SCHEDULE: Record<number, RoomType[]> = {
  2: ['treasure', 'shrine'],      // Floor 3 (0-indexed 2): treasure or shrine
  4: ['rest', 'merchant'],         // Floor 5: rest stop or merchant
  6: ['trap', 'shrine', 'treasure'], // Floor 7: variety
  8: ['rest', 'merchant'],         // Floor 9: last stop before final boss
};

function generateVarietyRoom(floor: number, dungeonId: string): DungeonRoom | null {
  const options = VARIETY_ROOM_SCHEDULE[floor];
  if (!options) return null;

  const type = options[Math.floor(Math.random() * options.length)];
  const baseLevel = floor + 1;

  switch (type) {
    case 'treasure':
      return { type, floor, goldReward: 100 + baseLevel * 50, itemChance: 0.4 + floor * 0.05 };
    case 'shrine':
      const buffs: Array<'attack' | 'defense' | 'speed' | 'heal'> = ['attack', 'defense', 'speed', 'heal'];
      return { type, floor, buffType: buffs[Math.floor(Math.random() * buffs.length)], buffAmount: 10 + floor * 2 };
    case 'trap':
      return { type, floor, damagePercent: 10 + floor * 2 };
    case 'rest':
      return { type, floor, healPercent: 25 + floor * 3 };
    case 'merchant':
      return { type, floor, goldReward: 0 }; // Client handles merchant UI
    default:
      return null;
  }
}

// Fallback boss names for unknown dungeon IDs
const FALLBACK_BOSS_NAMES = [
  'Goblin Chieftain',
  'Bone Dragon',
  'Shadow Lord',
  'Infernal Golem',
  'The Lich King',
  'Abyssal Serpent',
  'Demon Overlord',
  'Elder Void Walker',
  'The Crimson Reaper',
  'Titan of the Deep',
];

// --- Helpers ---

function generateId(): string {
  return `enemy_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}

/**
 * Generate a boss enemy for a specific dungeon and floor (boss index).
 * Uses the exact boss data matching the iOS client.
 */
function generateBossForDungeon(
  dungeonId: string,
  bossIndex: number,
  difficultyMult: number,
): Enemy {
  const bosses = DUNGEON_BOSSES[dungeonId];

  if (bosses && bossIndex < bosses.length) {
    const boss = bosses[bossIndex];
    const abilities = BOSS_ABILITIES[dungeonId]?.[bossIndex] ?? [];
    return {
      id: generateId(),
      name: boss.name,
      level: boss.level,
      maxHp: Math.round(boss.hp * difficultyMult),
      str: Math.round((10 + boss.level * 2.5) * difficultyMult),
      agi: Math.round((8 + boss.level * 1.8) * difficultyMult),
      armor: Math.round((6 + boss.level * 2) * difficultyMult),
      magicResist: Math.round((5 + boss.level * 1.5) * difficultyMult),
      isBoss: true,
      abilities: abilities.length > 0 ? abilities : undefined,
    };
  }

  // Fallback for unknown dungeons — scale by bossIndex
  const level = Math.max(1, (bossIndex + 1) * 3);
  const name = FALLBACK_BOSS_NAMES[bossIndex % FALLBACK_BOSS_NAMES.length];

  return {
    id: generateId(),
    name,
    level: Math.round(level * difficultyMult),
    maxHp: Math.round((200 + level * 50) * difficultyMult),
    str: Math.round((15 + level * 3) * difficultyMult),
    agi: Math.round((10 + level * 2) * difficultyMult),
    armor: Math.round((10 + level * 2.5) * difficultyMult),
    magicResist: Math.round((8 + level * 2) * difficultyMult),
    isBoss: true,
  };
}

// --- Public API ---

/**
 * Generate enemies for a dungeon floor.
 *
 * Each floor = one boss fight (matching the iOS client's 10-boss-per-dungeon model).
 * Floor 1 = boss #1, floor 2 = boss #2, etc.
 *
 * @param floor      The floor number (1-based). Boss index = floor - 1.
 * @param difficulty  'easy' | 'normal' | 'hard'
 * @param dungeonId   The dungeon identifier (e.g. 'training_camp')
 * @returns           A single boss enemy for this floor
 */
export function generateDungeonFloor(
  floor: number,
  difficulty: string,
  dungeonId: string = 'training_camp',
): DungeonFloor {
  const diffMult = DIFFICULTY_MULTIPLIERS[difficulty] ?? 1.0;
  const bossIndex = Math.max(0, floor - 1);

  // Check for variety room (non-combat floors)
  const varietyRoom = generateVarietyRoom(bossIndex, dungeonId);
  if (varietyRoom) {
    return {
      enemies: [],
      isBoss: false,
      room: varietyRoom,
    };
  }

  return {
    enemies: [generateBossForDungeon(dungeonId, bossIndex, diffMult)],
    isBoss: true,
  };
}

/** Total number of bosses for a given dungeon */
export function getDungeonBossCount(dungeonId: string): number {
  return DUNGEON_BOSSES[dungeonId]?.length ?? 10;
}

// --- DB-backed boss generation ---

import { prisma } from '@/lib/prisma';

/**
 * Try to load boss data from the database for a dungeon slug.
 * Falls back to hardcoded DUNGEON_BOSSES if DB has no bosses for this dungeon.
 */
export async function generateDungeonFloorFromDB(
  floor: number,
  difficulty: string,
  dungeonSlug: string,
): Promise<DungeonFloor> {
  const diffMult = DIFFICULTY_MULTIPLIERS[difficulty] ?? 1.0;
  const bossIndex = Math.max(0, floor - 1);

  // Try DB first: find dungeon by slug, get boss at floor_number
  try {
    const dungeon = await prisma.dungeon.findFirst({
      where: { slug: dungeonSlug, isActive: true },
      select: { id: true },
    });

    if (dungeon) {
      const boss = await prisma.dungeonBoss.findFirst({
        where: { dungeonId: dungeon.id, floorNumber: floor },
      });

      if (boss) {
        return {
          enemies: [{
            id: generateId(),
            name: boss.name,
            level: Math.round(boss.level * diffMult),
            maxHp: Math.round(boss.hp * diffMult),
            str: Math.round((boss.damage ?? 15) * diffMult),
            agi: Math.round((boss.speed ?? 10) * diffMult),
            armor: Math.round((boss.defense ?? 10) * diffMult),
            magicResist: Math.round(((boss.defense ?? 10) * 0.7) * diffMult),
            isBoss: true,
          }],
          isBoss: true,
        };
      }
    }
  } catch {
    // DB error — fall through to hardcoded
  }

  // Fallback to hardcoded
  return generateDungeonFloor(floor, difficulty, dungeonSlug);
}

/** Get total boss count from DB first, fallback to hardcoded */
export async function getDungeonBossCountFromDB(dungeonSlug: string): Promise<number> {
  try {
    const dungeon = await prisma.dungeon.findFirst({
      where: { slug: dungeonSlug, isActive: true },
      select: { id: true },
    });
    if (dungeon) {
      const count = await prisma.dungeonBoss.count({ where: { dungeonId: dungeon.id } });
      if (count > 0) return count;
    }
  } catch {
    // fallback
  }
  return getDungeonBossCount(dungeonSlug);
}
