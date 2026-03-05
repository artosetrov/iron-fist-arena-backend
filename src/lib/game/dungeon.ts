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

const ENEMY_NAMES_NORMAL = [
  'Goblin Scout',
  'Skeleton Soldier',
  'Cave Bat',
  'Dark Imp',
  'Corrupted Rat',
  'Shadow Wisp',
  'Undead Archer',
  'Venomous Spider',
  'Cursed Wraith',
  'Fungal Horror',
];

const BOSS_NAMES = [
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

// Boss appears every 5 floors
const BOSS_FLOOR_INTERVAL = 5;

// --- Helpers ---

function generateId(): string {
  return `enemy_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}

function pickRandom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

/**
 * Generate a single normal enemy scaled to the given floor and difficulty.
 */
function generateEnemy(floor: number, difficultyMult: number): Enemy {
  const baseLevel = Math.max(1, floor);
  const level = Math.max(1, Math.round(baseLevel * difficultyMult));

  return {
    id: generateId(),
    name: pickRandom(ENEMY_NAMES_NORMAL),
    level,
    maxHp: Math.round((80 + level * 20) * difficultyMult),
    str: Math.round((8 + level * 2) * difficultyMult),
    agi: Math.round((6 + level * 1.5) * difficultyMult),
    armor: Math.round((3 + level * 1.2) * difficultyMult),
    magicResist: Math.round((2 + level * 1) * difficultyMult),
    isBoss: false,
  };
}

/**
 * Generate a boss enemy. Bosses are significantly stronger.
 */
function generateBoss(floor: number, difficultyMult: number): Enemy {
  const baseLevel = Math.max(1, floor);
  const level = Math.max(1, Math.round(baseLevel * difficultyMult));
  const bossIndex = Math.floor(floor / BOSS_FLOOR_INTERVAL) - 1;
  const bossName = BOSS_NAMES[bossIndex % BOSS_NAMES.length];

  return {
    id: generateId(),
    name: bossName,
    level: level + 3,
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
 * - Every BOSS_FLOOR_INTERVAL floors (5, 10, 15, ...) is a boss floor with a single boss.
 * - Normal floors have 2-4 enemies depending on difficulty.
 *
 * @param floor      The floor number (1-based)
 * @param difficulty 'easy' | 'normal' | 'hard'
 * @returns          The list of enemies and whether this is a boss floor
 */
export function generateDungeonFloor(
  floor: number,
  difficulty: string,
): DungeonFloor {
  const diffMult = DIFFICULTY_MULTIPLIERS[difficulty] ?? 1.0;
  const isBoss = floor > 0 && floor % BOSS_FLOOR_INTERVAL === 0;

  if (isBoss) {
    return {
      enemies: [generateBoss(floor, diffMult)],
      isBoss: true,
    };
  }

  // Normal floors: 2-4 enemies
  const enemyCount = difficulty === 'easy' ? 2 : difficulty === 'hard' ? 4 : 3;
  const enemies: Enemy[] = [];

  for (let i = 0; i < enemyCount; i++) {
    enemies.push(generateEnemy(floor, diffMult));
  }

  return {
    enemies,
    isBoss: false,
  };
}
