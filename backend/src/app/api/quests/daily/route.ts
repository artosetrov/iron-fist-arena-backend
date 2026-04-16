import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { DailyQuest, QuestType } from '@prisma/client'
import { invalidatePassiveCache, invalidateSkillCache } from '@/lib/game/combat-loader'
import { awardBattlePassXp } from '@/lib/game/battle-pass'
import { getBattlePassConfig } from '@/lib/game/live-config'
import { grantRewardEntries } from '@/lib/game/reward-grants'

type QuestPoolEntry = {
  questType: QuestType
  minTarget: number
  maxTarget: number
  rewardGold: number
  rewardXp: number
  rewardGems: number
}

type QuestMetaEntry = {
  title: string
  description: (target: number) => string
  icon: string
}

type QuestMetaMap = Record<QuestType, QuestMetaEntry>

type QuestViewRow = Pick<
  DailyQuest,
  'id' | 'questType' | 'target' | 'progress' | 'completed' | 'rewardGold' | 'rewardXp' | 'rewardGems'
>

type LockedDailyQuestRow = {
  id: string
  character_id: string
  progress: number
  target: number
  completed: boolean
  reward_gold: number
  reward_xp: number
  reward_gems: number
}

// Quest generation config (fallback)
const QUEST_POOL: QuestPoolEntry[] = [
  { questType: 'pvp_wins', minTarget: 2, maxTarget: 5, rewardGold: 300, rewardXp: 150, rewardGems: 0 },
  { questType: 'dungeons_complete', minTarget: 1, maxTarget: 3, rewardGold: 250, rewardXp: 200, rewardGems: 0 },
  { questType: 'gold_spent', minTarget: 500, maxTarget: 2000, rewardGold: 0, rewardXp: 100, rewardGems: 5 },
  { questType: 'item_upgrade', minTarget: 1, maxTarget: 3, rewardGold: 200, rewardXp: 100, rewardGems: 0 },
  { questType: 'consumable_use', minTarget: 1, maxTarget: 3, rewardGold: 150, rewardXp: 80, rewardGems: 0 },
  { questType: 'shell_game_play', minTarget: 2, maxTarget: 5, rewardGold: 200, rewardXp: 50, rewardGems: 3 },
  { questType: 'gold_mine_collect', minTarget: 1, maxTarget: 3, rewardGold: 100, rewardXp: 100, rewardGems: 2 },
]

// Human-readable quest metadata by type (fallback)
const QUEST_META: QuestMetaMap = {
  pvp_wins: { title: 'Warrior', description: (t) => `Win ${t} PvP battles`, icon: 'building-arena' },
  dungeons_complete: { title: 'Dungeon Crawler', description: (t) => `Complete ${t} dungeons`, icon: 'building-dungeon' },
  gold_spent: { title: 'Big Spender', description: (t) => `Spend ${t} gold`, icon: 'building-shop' },
  item_upgrade: { title: 'Blacksmith', description: (t) => `Upgrade ${t} items`, icon: 'item-upgrade' },
  consumable_use: { title: 'Alchemist', description: (t) => `Use ${t} consumables`, icon: 'health-potion-medium' },
  shell_game_play: { title: 'Shell Game', description: (t) => `Play shell game ${t} times`, icon: 'shell-cup' },
  gold_mine_collect: { title: 'Gold Miner', description: (t) => `Collect from gold mine ${t} times`, icon: 'building-gold-mine' },
}

function isQuestType(value: string): value is QuestType {
  return value in QUEST_META
}

async function getQuestPool(): Promise<QuestPoolEntry[]> {
  try {
    const defs = await prisma.questDefinition.findMany({ where: { active: true } })
    if (defs.length > 0) {
      const mappedDefs = defs.flatMap<QuestPoolEntry>((definition) => {
        if (!isQuestType(definition.questType)) return []
        return [{
          questType: definition.questType,
          minTarget: definition.minTarget,
          maxTarget: definition.maxTarget,
          rewardGold: definition.rewardGold,
          rewardXp: definition.rewardXp,
          rewardGems: definition.rewardGems,
        }]
      })

      if (mappedDefs.length > 0) return mappedDefs
    }
  } catch {}
  return QUEST_POOL
}

async function getQuestMeta(): Promise<QuestMetaMap> {
  try {
    const defs = await prisma.questDefinition.findMany({ where: { active: true } })
    if (defs.length > 0) {
      const meta: Partial<QuestMetaMap> = {}
      for (const definition of defs) {
        if (!isQuestType(definition.questType)) continue

        meta[definition.questType] = {
          title: definition.title,
          description: (target: number) =>
            definition.description.includes('${t}')
              ? definition.description.replace('${t}', String(target))
              : `${definition.description} (${target})`,
          icon: definition.icon,
        }
      }

      return { ...QUEST_META, ...meta }
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
  quest: QuestViewRow,
  meta: QuestMetaMap
) {
  const questType = quest.questType
  const questMeta = meta[questType] || QUEST_META[questType]
  return {
    id: quest.id,
    type: quest.questType,
    title: questMeta.title,
    description: questMeta.description(quest.target),
    icon: questMeta.icon,
    target: quest.target,
    progress: quest.progress,
    completed: quest.progress >= quest.target,
    reward_claimed: quest.completed, // DB `completed` = reward was claimed
    reward_gold: quest.rewardGold,
    reward_xp: quest.rewardXp,
    reward_gems: quest.rewardGems,
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
      const createData = selected.map((quest) => ({
        characterId,
        questType: quest.questType,
        target: randomInt(quest.minTarget, quest.maxTarget),
        rewardGold: quest.rewardGold,
        rewardXp: quest.rewardXp,
        rewardGems: quest.rewardGems,
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
      quests: quests.map((quest) => formatQuest(quest, questMeta)),
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
      const result = await prisma.$transaction(async (tx) => {
        // Set lock timeout to prevent indefinite hangs on concurrent claims
        await tx.$executeRawUnsafe(`SET LOCAL lock_timeout = '5s'`)
        // Lock the quest row with FOR UPDATE (table mapped to "daily_quests", columns are snake_case)
        const rows = await tx.$queryRawUnsafe<LockedDailyQuestRow[]>(
          `SELECT * FROM "daily_quests" WHERE "id" = $1 FOR UPDATE`,
          quest_id
        )
        const q = rows[0]
        if (!q) throw new Error('QUEST_NOT_FOUND')
        if (q.character_id !== character_id) throw new Error('FORBIDDEN')
        if (q.progress < q.target) throw new Error('NOT_COMPLETED')
        if (q.completed) throw new Error('ALREADY_CLAIMED')

        const rewardResult = await grantRewardEntries(tx, {
          userId: user.id,
          characterId: character_id,
          rewards: [
            { type: 'gold', quantity: q.reward_gold },
            { type: 'xp', quantity: q.reward_xp },
            { type: 'gems', quantity: q.reward_gems },
          ],
        })

        await tx.dailyQuest.update({
          where: { id: quest_id },
          data: { completed: true },
        })

        await awardBattlePassXp(tx, character_id, BATTLE_PASS.BP_XP_PER_QUEST)

        return { quest: q, rewardResult }
      })

      if (result.rewardResult.levelUpResult?.leveledUp) {
        await Promise.all([
          invalidateSkillCache(character_id),
          invalidatePassiveCache(character_id),
        ])
      }

      return NextResponse.json({
        success: true,
        reward_gold: result.quest.reward_gold,
        reward_xp: result.quest.reward_xp,
        reward_gems: result.quest.reward_gems,
        gold: result.rewardResult.gold,
        gems: result.rewardResult.gems,
        xp: result.rewardResult.xp,
        leveled_up: result.rewardResult.levelUpResult?.leveledUp ?? false,
        new_level: result.rewardResult.levelUpResult?.newLevel,
        stat_points_awarded: result.rewardResult.levelUpResult?.statPointsAwarded,
      })
    }

    return NextResponse.json({ error: 'Unknown action' }, { status: 400 })
  } catch (error) {
    const message = error instanceof Error ? error.message : ''

    if (message === 'QUEST_NOT_FOUND') return NextResponse.json({ error: 'Quest not found' }, { status: 404 })
    if (message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    if (message === 'NOT_COMPLETED') return NextResponse.json({ error: 'Quest not completed yet' }, { status: 400 })
    if (message === 'ALREADY_CLAIMED') return NextResponse.json({ error: 'Reward already claimed' }, { status: 400 })
    console.error('quest claim error:', error)
    return NextResponse.json({ error: 'Failed to process quest' }, { status: 500 })
  }
}
