import { PrismaClient, CharacterClass, CharacterOrigin } from '@prisma/client'
import { randomUUID } from 'crypto'

const prisma = new PrismaClient()

const BOT_NAMES = [
  'IronBane', 'ShadowFist', 'CrimsonEdge', 'StormBreaker', 'VoidWalker',
  'BloodThorn', 'AshPyre', 'FrostWarden', 'EmberClaw', 'DuskRaider',
  'NightStalker', 'SteelVeil', 'GrimForge', 'BoneCrusher', 'WildFury',
  'DeathMark', 'SoulReaver', 'IceBreaker', 'ThunderFang', 'DarkBlaze',
]

const CLASSES: CharacterClass[] = ['warrior', 'rogue', 'mage', 'tank']
const ORIGINS: CharacterOrigin[] = ['human', 'orc', 'skeleton', 'demon', 'dogfolk']

function pick<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)]
}

function statsByClass(cls: CharacterClass) {
  switch (cls) {
    case 'warrior': return { str: 18, agi: 12, vit: 14, end: 14, int: 8, wis: 8, luk: 10, cha: 10, maxHp: 130, armor: 10, magicResist: 3 }
    case 'rogue':   return { str: 12, agi: 20, vit: 10, end: 12, int: 10, wis: 10, luk: 15, cha: 8,  maxHp: 110, armor: 5,  magicResist: 2 }
    case 'mage':    return { str: 8,  agi: 10, vit: 8,  end: 10, int: 22, wis: 18, luk: 10, cha: 8,  maxHp: 90,  armor: 2,  magicResist: 15 }
    case 'tank':    return { str: 14, agi: 8,  vit: 20, end: 20, int: 6,  wis: 8,  luk: 8,  cha: 10, maxHp: 160, armor: 18, magicResist: 8 }
  }
}

async function main() {
  console.log('🌱 Seeding bot opponents...')

  // Rating buckets: spread bots across 800–1200 range
  const ratings = [800, 850, 900, 920, 950, 970, 990, 1000, 1010, 1030,
                   1050, 1070, 1100, 1120, 1150, 1170, 1190, 1200, 830, 960]

  let created = 0
  let skipped = 0

  for (let i = 0; i < BOT_NAMES.length; i++) {
    const name = BOT_NAMES[i]
    const cls = CLASSES[i % CLASSES.length]
    const origin = pick(ORIGINS)
    const rating = ratings[i]
    const wins = Math.floor(Math.random() * 40) + 5
    const losses = Math.floor(Math.random() * 30) + 3
    const stats = statsByClass(cls)

    // Check if bot character already exists
    const existing = await prisma.character.findUnique({
      where: { characterName: name },
    })
    if (existing) {
      skipped++
      continue
    }

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
            level: Math.floor(rating / 100),
            pvpRating: rating,
            pvpWins: wins,
            pvpLosses: losses,
            pvpWinStreak: Math.floor(Math.random() * 5),
            highestPvpRank: rating + Math.floor(Math.random() * 50),
            pvpCalibrationGames: 10,
            ...stats,
            currentHp: stats.maxHp,
          },
        },
      },
    })

    created++
    console.log(`  ✓ ${name} (${cls}, rating: ${rating})`)
  }

  console.log(`\n✅ Done: ${created} bots created, ${skipped} already existed.`)
}

main()
  .catch((e) => { console.error(e); process.exit(1) })
  .finally(() => prisma.$disconnect())
