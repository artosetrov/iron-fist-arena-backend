// =============================================================================
// dungeon.ts — Dungeon floor generation
// =============================================================================

// --- Types ---

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
}

export interface DungeonFloor {
  enemies: Enemy[];
  isBoss: boolean;
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

  return {
    enemies: [generateBossForDungeon(dungeonId, bossIndex, diffMult)],
    isBoss: true,
  };
}

/** Total number of bosses for a given dungeon */
export function getDungeonBossCount(dungeonId: string): number {
  return DUNGEON_BOSSES[dungeonId]?.length ?? 10;
}
