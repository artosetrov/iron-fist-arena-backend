import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { canClaimDailyLogin } from '@/lib/game/daily-login'
import {
  STAMINA,
  UPGRADE_CHANCES,
  COMBAT,
  PRESTIGE,
  GOLD_REWARDS,
  XP_REWARDS,
  DAILY_LOGIN_REWARDS,
  ELO,
} from '@/lib/game/balance'
import { QuestType } from '@prisma/client'

// Quest metadata for formatting
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

/**
 * GET /api/game/init?character_id=xxx
 *
 * Returns all data needed to populate the game hub in a single request.
 * Replaces 5+ individual API calls the client would otherwise make.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const now = new Date()
    const today = getToday()

    // Run all queries in parallel for maximum speed
    const [
      character,
      equipment,
      consumables,
      quests,
      dailyLogin,
      achievements,
      activeEvents,
      userRecord,
    ] = await Promise.all([
      prisma.character.findUnique({
        where: { id: characterId },
      }),
      prisma.equipmentInventory.findMany({
        where: { characterId },
        include: { item: true },
      }),
      prisma.consumableInventory.findMany({
        where: { characterId },
      }),
      prisma.dailyQuest.findMany({
        where: { characterId, day: today },
        orderBy: { createdAt: 'asc' },
      }),
      prisma.dailyLoginReward.findUnique({
        where: { characterId },
      }),
      prisma.achievement.findMany({
        where: { characterId },
        select: { completed: true, rewardClaimed: true },
      }),
      prisma.event.findMany({
        where: {
          isActive: true,
          startAt: { lte: now },
          endAt: { gte: now },
        },
        orderBy: { startAt: 'asc' },
      }),
      prisma.user.findUnique({
        where: { id: user.id },
        select: {
          id: true,
          email: true,
          username: true,
          gems: true,
          premiumUntil: true,
          role: true,
          createdAt: true,
          lastLogin: true,
        },
      }),
    ])

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Compute current stamina without writing to DB
    const staminaResult = calculateCurrentStamina(
      character.currentStamina,
      character.maxStamina,
      character.lastStaminaUpdate ?? new Date()
    )

    // Format quests with metadata
    const formattedQuests = quests.map((q) => {
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
        reward_claimed: q.completed,
        reward_gold: q.rewardGold,
        reward_xp: q.rewardXp,
        reward_gems: q.rewardGems,
      }
    })

    // Daily login status
    const dailyLoginStatus = {
      currentDay: dailyLogin?.currentDay ?? 1,
      streak: dailyLogin?.streak ?? 0,
      totalClaims: dailyLogin?.totalClaims ?? 0,
      lastClaimDate: dailyLogin?.lastClaimDate ?? null,
      canClaim: canClaimDailyLogin(dailyLogin?.lastClaimDate ?? null),
    }

    // Achievement summary (counts only — full list fetched on demand)
    const achievementsSummary = {
      total: achievements.length,
      completed: achievements.filter((a) => a.completed).length,
      claimable: achievements.filter((a) => a.completed && !a.rewardClaimed).length,
    }

    // Game balance constants the client needs for local calculations
    const config = {
      staminaMax: STAMINA.MAX,
      staminaRegenMinutes: STAMINA.REGEN_INTERVAL_MINUTES,
      pvpStaminaCost: STAMINA.PVP_COST,
      freePvpPerDay: STAMINA.FREE_PVP_PER_DAY,
      upgradeChances: UPGRADE_CHANCES,
      maxLevel: PRESTIGE.MAX_LEVEL,
      statPointsPerLevel: PRESTIGE.STAT_POINTS_PER_LEVEL,
      pvpWinGold: GOLD_REWARDS.PVP_WIN_BASE,
      pvpLossGold: GOLD_REWARDS.PVP_LOSS_BASE,
      pvpWinXp: XP_REWARDS.PVP_WIN_XP,
      pvpLossXp: XP_REWARDS.PVP_LOSS_XP,
      critMultiplier: COMBAT.CRIT_MULTIPLIER,
      maxCritChance: COMBAT.MAX_CRIT_CHANCE,
      maxDodgeChance: COMBAT.MAX_DODGE_CHANCE,
      dailyLoginRewards: DAILY_LOGIN_REWARDS,
      eloCalibrationGames: ELO.CALIBRATION_GAMES,
    }

    return NextResponse.json({
      user: userRecord,
      character: {
        ...character,
        currentStamina: staminaResult.stamina,
      },
      equipment,
      consumables,
      quests: formattedQuests,
      dailyLogin: dailyLoginStatus,
      achievementsSummary,
      activeEvents,
      config,
      serverTime: now.toISOString(),
    })
  } catch (error) {
    console.error('game init error:', error)
    return NextResponse.json(
      { error: 'Failed to initialize game data' },
      { status: 500 }
    )
  }
}
