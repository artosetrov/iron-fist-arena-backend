import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { QuestType } from '@prisma/client'
import { applyLevelUp } from '@/lib/game/progression'
import { awardBattlePassXp } from '@/lib/game/battle-pass'
import { getBattlePassConfig } from '@/lib/game/live-config'

// Quest generation config (fallback)
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

// Human-readable quest metadata by type (fallback)
const QUEST_META: Record<QuestType, { title: string; description: (target: number) => string; icon: string }> = {
  pvp_wins: { title: 'Warrior', description: (t) => `Win ${t} PvP battles`, icon: '⚔️' },
  dungeons_complete: { title: 'Dungeon Crawler', description: (t) => `Complete ${t} dungeons`, icon: '🏰' },
  gold_spent: { title: 'Big Spender', description: (t) => `Spend ${t} gold`, icon: '💰' },
  item_upgrade: { title: 'Blacksmith', description: (t) => `Upgrade ${t} items`, icon: '🔨' },
  consumable_use: { title: 'Alchemist', description: (t) => `Use ${t} consumables`, icon: '⚗️' },
  shell_game_play: { title: 'Shell Game', description: (t) => `Play shell game ${t} times`, icon: '🎭' },
  gold_mine_collect: { title: 'Gold Miner', description: (t) => `Collect from gold mine ${t} times`, icon: '⛏️' },
}

async function getQuestPool() {
  try {
    const defs = await prisma.questDefinition.findMany({ where: { active: true } })
    if (defs.length > 0) {
      return defs.map((d: any) => ({
        questType: d.questType as QuestType,
        minTarget: d.minTarget,
        maxTarget: d.maxTarget,
        rewardGold: d.rewardGold,
        rewardXp: d.rewardXp,
        rewardGems: d.rewardGems,
      }))
    }
  } catch {}
  return QUEST_POOL
}

async function getQuestMeta(): Promise<Record<QuestType, { title: string; description: (target: number) => string; icon: string }>> {
  try {
    const defs = await prisma.questDefinition.findMany({ where: { active: true } })
    if (defs.length > 0) {
      const meta: Record<string, { title: string; description: (target: number) => string; icon: string }> = {}
      for (const d of defs as any[]) {
        meta[d.questType] = {
          title: d.title,
          description: (t: number) => d.description.includes('${t}') ? d.description.replace('${t}', String(t)) : `${d.description} (${t})`,
          icon: d.icon,
        }
      }
      return meta as Record<QuestType, { title: string; description: (target: number) => string; icon: string }>
    }
  } catch {}
  return QUEST_META
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

function formatQuest(
  q: any,
  meta: Record<QuestType, { title: string; description: (target: number) => string; icon: string }>
) {
  const questType = q.questType as QuestType
  const questMeta = meta[questType] || QUEST_META[questType]
  return {
    id: q.id,
    type: q.questType,
    title: questMeta.title,
    description: questMeta.description(q.target),
    icon: questMeta.icon,
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

    const today = getToday()

    // Parallel: verify ownership + fetch today's quests + get quest definitions
    const [character, quests_raw, questPool, questMeta] = await Promise.all([
      prisma.character.findUnique({
        where: { id: characterId },
        select: { id: true, userId: true, dailyBonusDate: true },
      }),
      prisma.dailyQuest.findMany({
        where: { characterId, day: today },
        orderBy: { createdAt: 'asc' },
      }),
      getQuestPool(),
      getQuestMeta(),
    ])

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    let quests = quests_raw

    if (quests.length === 0) {
      const selected = pickRandom(questPool, 3)
      const createData = selected.map((q: any) => ({
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

    const dailyBonusClaimed =
      character.dailyBonusDate !== null &&
      character.dailyBonusDate.toISOString().slice(0, 10) === today

    return NextResponse.json({
      quests: quests.map((q: any) => formatQuest(q, questMeta)),
      day: today,
      daily_bonus_claimed: dailyBonusClaimed,
    })
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
    const BATTLE_PASS = await getBattlePassConfig()
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
      // Atomic read-check-write to prevent double-claim
      const quest = await prisma.$transaction(async (tx) => {
        // Lock the quest row with FOR UPDATE (table mapped to "daily_quests", columns are snake_case)
        const rows = await tx.$queryRawUnsafe<any[]>(
          `SELECT * FROM "daily_quests" WHERE "id" = $1 FOR UPDATE`,
          quest_id
        )
        const q = rows[0]
        if (!q) throw new Error('QUEST_NOT_FOUND')
        if (q.character_id !== character_id) throw new Error('FORBIDDEN')
        if (q.progress < q.target) throw new Error('NOT_COMPLETED')
        if (q.completed) throw new Error('ALREADY_CLAIMED')

        // Mark claimed + award rewards
        await tx.dailyQuest.update({
          where: { id: quest_id },
          data: { completed: true },
        })
        await tx.character.update({
          where: { id: character_id },
          data: {
            gold: { increment: q.reward_gold },
            currentXp: { increment: q.reward_xp },
          },
        })
        // Award gems if quest has gem reward (gems live on User, not Character)
        if (q.reward_gems > 0) {
          await tx.user.update({
            where: { id: user.id },
            data: { gems: { increment: q.reward_gems } },
          })
        }

        return q
      })

      // Award Battle Pass XP for quest completion
      await awardBattlePassXp(prisma, character_id, BATTLE_PASS.BP_XP_PER_QUEST)

      // Check for level-up after XP award
      const levelUpResult = await applyLevelUp(prisma, character_id)

      return NextResponse.json({
        success: true,
        reward_gold: quest.reward_gold,
        reward_xp: quest.reward_xp,
        reward_gems: quest.reward_gems,
        leveled_up: levelUpResult?.leveledUp ?? false,
        new_level: levelUpResult?.newLevel,
        stat_points_awarded: levelUpResult?.statPointsAwarded,
      })
    }

    return NextResponse.json({ error: 'Unknown action' }, { status: 400 })
  } catch (error: any) {
    if (error.message === 'QUEST_NOT_FOUND') return NextResponse.json({ error: 'Quest not found' }, { status: 404 })
    if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    if (error.message === 'NOT_COMPLETED') return NextResponse.json({ error: 'Quest not completed yet' }, { status: 400 })
    if (error.message === 'ALREADY_CLAIMED') return NextResponse.json({ error: 'Reward already claimed' }, { status: 400 })
    console.error('quest claim error:', error)
    return NextResponse.json({ error: 'Failed to process quest' }, { status: 500 })
  }
}
