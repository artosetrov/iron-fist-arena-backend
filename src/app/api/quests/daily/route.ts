import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { QuestType } from '@prisma/client'

// Quest generation config: questType -> { minTarget, maxTarget, rewardGold, rewardXp, rewardGems }
const QUEST_POOL: {
  questType: QuestType
  minTarget: number
  maxTarget: number
  rewardGold: number
  rewardXp: number
  rewardGems: number
}[] = [
  { questType: 'pvp_wins', minTarget: 2, maxTarget: 5, rewardGold: 300, rewardXp: 150, rewardGems: 0 },
  { questType: 'dungeons_complete', minTarget: 1, maxTarget: 3, rewardGold: 250, rewardXp: 200, rewardGems: 0 },
  { questType: 'gold_spent', minTarget: 500, maxTarget: 2000, rewardGold: 0, rewardXp: 100, rewardGems: 5 },
  { questType: 'item_upgrade', minTarget: 1, maxTarget: 3, rewardGold: 200, rewardXp: 100, rewardGems: 0 },
  { questType: 'consumable_use', minTarget: 1, maxTarget: 3, rewardGold: 150, rewardXp: 80, rewardGems: 0 },
  { questType: 'shell_game_play', minTarget: 2, maxTarget: 5, rewardGold: 200, rewardXp: 50, rewardGems: 3 },
  { questType: 'gold_mine_collect', minTarget: 1, maxTarget: 3, rewardGold: 100, rewardXp: 100, rewardGems: 2 },
]

function getToday(): string {
  return new Date().toISOString().slice(0, 10)
}

function randomInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min
}

function pickRandom<T>(arr: T[], count: number): T[] {
  const shuffled = [...arr].sort(() => Math.random() - 0.5)
  return shuffled.slice(0, count)
}

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')

    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const today = getToday()

    // Check for existing quests today
    let quests = await prisma.dailyQuest.findMany({
      where: { characterId, day: today },
      orderBy: { createdAt: 'asc' },
    })

    // Auto-generate 3 random quests if none exist for today
    if (quests.length === 0) {
      const selected = pickRandom(QUEST_POOL, 3)

      const createData = selected.map((q) => ({
        characterId,
        questType: q.questType,
        target: randomInt(q.minTarget, q.maxTarget),
        rewardGold: q.rewardGold,
        rewardXp: q.rewardXp,
        rewardGems: q.rewardGems,
        day: today,
      }))

      await prisma.dailyQuest.createMany({ data: createData })

      quests = await prisma.dailyQuest.findMany({
        where: { characterId, day: today },
        orderBy: { createdAt: 'asc' },
      })
    }

    return NextResponse.json({ quests, day: today })
  } catch (error) {
    console.error('get daily quests error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch daily quests' },
      { status: 500 }
    )
  }
}
