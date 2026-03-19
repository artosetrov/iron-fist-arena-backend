import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { calculateCurrentHp } from '@/lib/game/hp-regen'
import { canClaimDailyLogin } from '@/lib/game/daily-login'
import {
  getStaminaConfig,
  getHpRegenConfig,
  getUpgradeChancesConfig,
  getCombatConfig,
  getPrestigeConfig,
  getGoldRewardsConfig,
  getXpRewardsConfig,
  getDailyLoginRewardsConfig,
  getEloConfig,
  getPvpRanksConfig,
  getBattlePassConfig,
} from '@/lib/game/live-config'
import { resolveAllFlags } from '@/lib/game/feature-flags'
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
      achievementsTotal,
      achievementsCompleted,
      achievementsClaimable,
      activeEvents,
      userRecord,
      hubLayoutConfig,
    ] = await Promise.all([
      prisma.character.findUnique({
        where: { id: characterId },
        select: {
          id: true, userId: true, characterName: true, class: true, origin: true,
          gender: true, avatar: true, level: true,
          str: true, agi: true, vit: true, end: true, int: true, wis: true, luk: true, cha: true,
          statPointsAvailable: true, currentXp: true,
          gold: true, currentStamina: true, maxStamina: true, lastStaminaUpdate: true,
          currentHp: true, maxHp: true, lastHpUpdate: true,
          armor: true, magicResist: true,
          pvpRating: true, pvpWins: true, pvpLosses: true, pvpWinStreak: true, pvpLossStreak: true,
          pvpCalibrationGames: true, highestPvpRank: true,
          freePvpToday: true, freePvpDate: true, firstWinToday: true, firstWinDate: true,
          combatStance: true, inventorySlots: true, goldMineSlots: true,
          createdAt: true, lastPlayed: true,
        },
      }),
      prisma.equipmentInventory.findMany({
        where: { characterId },
        include: {
          item: {
            select: {
              id: true, itemName: true, itemType: true, rarity: true, itemLevel: true,
              baseStats: true, setName: true, specialEffect: true, uniquePassive: true,
              imageUrl: true, imageKey: true, classRestriction: true, description: true,
            },
          },
        },
      }),
      prisma.consumableInventory.findMany({
        where: { characterId },
        select: {
          id: true,
          consumableType: true,
          quantity: true,
          acquiredAt: true,
        },
      }),
      prisma.dailyQuest.findMany({
        where: { characterId, day: today },
        orderBy: { createdAt: 'asc' },
        select: {
          id: true,
          questType: true,
          progress: true,
          target: true,
          completed: true,
          rewardGold: true,
          rewardXp: true,
          rewardGems: true,
        },
      }),
      prisma.dailyLoginReward.findUnique({
        where: { characterId },
      }),
      prisma.achievement.count({
        where: { characterId },
      }),
      prisma.achievement.count({
        where: { characterId, completed: true },
      }),
      prisma.achievement.count({
        where: { characterId, completed: true, rewardClaimed: false },
      }),
      prisma.event.findMany({
        where: {
          isActive: true,
          startAt: { lte: now },
          endAt: { gte: now },
        },
        orderBy: { startAt: 'asc' },
        select: {
          id: true,
          eventKey: true,
          title: true,
          description: true,
          eventType: true,
          config: true,
          startAt: true,
          endAt: true,
          isActive: true,
        },
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
      prisma.gameConfig.findUnique({
        where: { key: 'hub_layout' },
        select: { value: true },
      }),
    ])

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Compute current stamina without writing to DB
    const staminaResult = await calculateCurrentStamina(
      character.currentStamina,
      character.maxStamina,
      character.lastStaminaUpdate ?? new Date()
    )

    // Compute current HP with regen
    const hpResult = await calculateCurrentHp(
      character.currentHp,
      character.maxHp,
      character.lastHpUpdate ?? new Date()
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
      total: achievementsTotal,
      completed: achievementsCompleted,
      claimable: achievementsClaimable,
    }

    // Game balance constants the client needs for local calculations
    const [
      staminaConfig,
      hpRegenConfig,
      prestigeConfig,
      goldRewardsConfig,
      xpRewardsConfig,
      combatConfig,
      upgradeChancesConfig,
      dailyLoginRewardsConfig,
      eloConfig,
      pvpRanksConfig,
      battlePassConfig,
      featureFlags,
    ] = await Promise.all([
      getStaminaConfig(),
      getHpRegenConfig(),
      getPrestigeConfig(),
      getGoldRewardsConfig(),
      getXpRewardsConfig(),
      getCombatConfig(),
      getUpgradeChancesConfig(),
      getDailyLoginRewardsConfig(),
      getEloConfig(),
      getPvpRanksConfig(),
      getBattlePassConfig(),
      resolveAllFlags(user.id, { id: character.id, level: character.level, class: character.class }),
    ])

    const config = {
      staminaMax: staminaConfig.MAX,
      staminaRegenMinutes: staminaConfig.REGEN_INTERVAL_MINUTES,
      hpRegenPercent: hpRegenConfig.REGEN_RATE,
      hpRegenMinutes: hpRegenConfig.REGEN_INTERVAL_MINUTES,
      pvpStaminaCost: staminaConfig.PVP_COST,
      freePvpPerDay: staminaConfig.FREE_PVP_PER_DAY,
      upgradeChances: upgradeChancesConfig,
      maxLevel: prestigeConfig.MAX_LEVEL,
      statPointsPerLevel: prestigeConfig.STAT_POINTS_PER_LEVEL,
      pvpWinGold: goldRewardsConfig.PVP_WIN_BASE,
      pvpLossGold: goldRewardsConfig.PVP_LOSS_BASE,
      pvpWinXp: xpRewardsConfig.PVP_WIN_XP,
      pvpLossXp: xpRewardsConfig.PVP_LOSS_XP,
      critMultiplier: combatConfig.CRIT_MULTIPLIER,
      maxCritChance: combatConfig.MAX_CRIT_CHANCE,
      maxDodgeChance: combatConfig.MAX_DODGE_CHANCE,
      dailyLoginRewards: dailyLoginRewardsConfig,
      eloCalibrationGames: eloConfig.CALIBRATION_GAMES,
      pvpRanks: pvpRanksConfig,
      battlePass: battlePassConfig,
    }

    return NextResponse.json({
      user: userRecord,
      character: {
        ...character,
        currentStamina: staminaResult.stamina,
        currentHp: hpResult.hp,
      },
      equipment,
      consumables,
      quests: formattedQuests,
      dailyLogin: dailyLoginStatus,
      achievementsSummary,
      activeEvents,
      config,
      featureFlags,
      hubLayout: hubLayoutConfig?.value ?? {},
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
