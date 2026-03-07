import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { QuestType } from '@prisma/client'
import { applyLevelUp } from '@/lib/game/progression'
import { awardBattlePassXp } from '@/lib/game/battle-pass'
import { BATTLE_PASS } from '@/lib/game/balance'

// Quest generation config
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

// Human-readable quest metadata by type
const QUEST_META: Record<QuestType, { title: string; description: (target: number) => string; icon: string }> = {
  pvp_wins: { title: 'Warrior', description: (t) => `Win ${t} PvP battles`, icon: '⚔️' },
  dungeons_complete: { title: 'Dungeon Crawler', description: (t) => `Complete ${t} dungeons`, icon: '🏰' },
  gold_spent: { title: 'Big Spender', description: (t) => `Spend ${t} gold`, icon: '💰' },
  item_upgrade: { title: 'Blacksmith', description: (t) => `Upgrade ${t} items`, icon: '🔨' },
  consumable_use: { title: 'Alchemist', description: (t) => `Use ${t} consumables`, icon: '⚗️' },
  shell_game_play: { title: 'Shell Game', description: (t) => `Play shell game ${t} times`, icon: '🎭' },
  gold_mine_collect: { title: 'Gold Miner', description: (t) => `Collect from gold mine ${t} times`, icon: '⛏️' },
}

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

function formatQuest(q: {
  id: string
  questType: QuestType
  progress: number
  target: number
  rewardGold: number
  rewardXp: number
  rewardGems: number
  completed: boolean
}) {
  const meta = QUEST_META[q.questType]
  return {
    id: q.id,
    type: q.questType,
    title: meta.title,
    description: meta.description(q.target),
    icon: meta.icon,
    target: q.target,
    progress: q.progress,
    completed: q.progress >= q.target,
    reward_claimed: q.completed, // DB `completed` = reward was claimed
    reward_gold: q.rewardGold,
    reward_xp: q.rewardXp,
    reward_gems: q.rewardGems,
  }
}

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({ where: { id: characterId } })
    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const today = getToday()
    let quests = await prisma.dailyQuest.findMany({
      where: { characterId, day: today },
      orderBy: { createdAt: 'asc' },
    })

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

    return NextResponse.json({ quests: quests.map(formatQuest), day: today })
  } catch (error) {
    console.error('get daily quests error:', error)
    return NextResponse.json({ error: 'Failed to fetch daily quests' }, { status: 500 })
  }
}

/**
 * POST /api/quests/daily
 * Body: { character_id, quest_id, action: "claim" }
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, quest_id, action } = body

    if (!character_id || !quest_id) {
      return NextResponse.json({ error: 'character_id and quest_id are required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({ where: { id: character_id } })
    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    if (action === 'claim') {
      const quest = await prisma.dailyQuest.findUnique({ where: { id: quest_id } })
      if (!quest) {
        return NextResponse.json({ error: 'Quest not found' }, { status: 404 })
      }
      if (quest.characterId !== character_id) {
        return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      }
      if (quest.progress < quest.target) {
        return NextResponse.json({ error: 'Quest not completed yet' }, { status: 400 })
      }
      if (quest.completed) {
        return NextResponse.json({ error: 'Reward already claimed' }, { status: 400 })
      }

      // Mark claimed + award rewards
      await prisma.$transaction(async (tx) => {
        await tx.dailyQuest.update({
          where: { id: quest_id },
          data: { completed: true },
        })
        await tx.character.update({
          where: { id: character_id },
          data: {
            gold: { increment: quest.rewardGold },
            currentXp: { increment: quest.rewardXp },
          },
        })
        // Award gems if quest has gem reward (gems live on User, not Character)
        if (quest.rewardGems > 0) {
          await tx.user.update({
            where: { id: user.id },
            data: { gems: { increment: quest.rewardGems } },
          })
        }
      })

      // Award Battle Pass XP for quest completion
      await awardBattlePassXp(prisma, character_id, BATTLE_PASS.BP_XP_PER_QUEST)

      // Check for level-up after XP award
      const levelUpResult = await applyLevelUp(prisma, character_id)

      return NextResponse.json({
        success: true,
        reward_gold: quest.rewardGold,
        reward_xp: quest.rewardXp,
        reward_gems: quest.rewardGems,
        leveled_up: levelUpResult?.leveledUp ?? false,
        new_level: levelUpResult?.newLevel,
        stat_points_awarded: levelUpResult?.statPointsAwarded,
      })
    }

    return NextResponse.json({ error: 'Unknown action' }, { status: 400 })
  } catch (error) {
    console.error('quest claim error:', error)
    return NextResponse.json({ error: 'Failed to process quest' }, { status: 500 })
  }
}
