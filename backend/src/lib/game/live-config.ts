// =============================================================================
// live-config.ts — Centralized live game config reader
// Reads from GameConfig DB with balance.ts constants as fallbacks
// =============================================================================

import { getGameConfig, getGameConfigs } from './config'
import {
  STAMINA, HP_REGEN, GOLD_REWARDS, XP_REWARDS, FIRST_WIN_BONUS,
  COMBAT, STANCE_ZONES, ELO, PRESTIGE, BATTLE_PASS, SKILLS, PASSIVES,
  GEM_COSTS, INVENTORY, EXTRA_PVP, DROP_CHANCES, RARITY_DISTRIBUTION,
  UPGRADE_CHANCES, WIN_STREAK_BONUSES, DAILY_LOGIN_REWARDS, PVP_RANKS,
  type DailyLoginRewardDef,
} from './balance'

// --- Stamina ---
export async function getStaminaConfig() {
  const configs = await getGameConfigs({
    'stamina.max': STAMINA.MAX,
    'stamina.regen_rate': STAMINA.REGEN_RATE,
    'stamina.regen_interval_minutes': STAMINA.REGEN_INTERVAL_MINUTES,
    'stamina.pvp_cost': STAMINA.PVP_COST,
    'stamina.dungeon_easy': STAMINA.DUNGEON_EASY,
    'stamina.dungeon_normal': STAMINA.DUNGEON_NORMAL,
    'stamina.dungeon_hard': STAMINA.DUNGEON_HARD,
    'stamina.boss': STAMINA.BOSS,
    'stamina.training': STAMINA.TRAINING,
    'stamina.free_pvp_per_day': STAMINA.FREE_PVP_PER_DAY,
  })
  return {
    MAX: configs['stamina.max'] as number,
    REGEN_RATE: configs['stamina.regen_rate'] as number,
    REGEN_INTERVAL_MINUTES: configs['stamina.regen_interval_minutes'] as number,
    PVP_COST: configs['stamina.pvp_cost'] as number,
    DUNGEON_EASY: configs['stamina.dungeon_easy'] as number,
    DUNGEON_NORMAL: configs['stamina.dungeon_normal'] as number,
    DUNGEON_HARD: configs['stamina.dungeon_hard'] as number,
    BOSS: configs['stamina.boss'] as number,
    TRAINING: configs['stamina.training'] as number,
    FREE_PVP_PER_DAY: configs['stamina.free_pvp_per_day'] as number,
  }
}

// --- HP Regen ---
export async function getHpRegenConfig() {
  const configs = await getGameConfigs({
    'hp_regen.regen_rate': HP_REGEN.REGEN_RATE,
    'hp_regen.regen_interval_minutes': HP_REGEN.REGEN_INTERVAL_MINUTES,
  })
  return {
    REGEN_RATE: configs['hp_regen.regen_rate'] as number,
    REGEN_INTERVAL_MINUTES: configs['hp_regen.regen_interval_minutes'] as number,
  }
}

// --- Gold Rewards ---
export async function getGoldRewardsConfig() {
  const configs = await getGameConfigs({
    'gold_rewards.pvp_win_base': GOLD_REWARDS.PVP_WIN_BASE,
    'gold_rewards.pvp_loss_base': GOLD_REWARDS.PVP_LOSS_BASE,
    'gold_rewards.training_win': GOLD_REWARDS.TRAINING_WIN,
    'gold_rewards.training_loss': GOLD_REWARDS.TRAINING_LOSS,
    'gold_rewards.revenge_multiplier': GOLD_REWARDS.REVENGE_MULTIPLIER,
  })
  return {
    PVP_WIN_BASE: configs['gold_rewards.pvp_win_base'] as number,
    PVP_LOSS_BASE: configs['gold_rewards.pvp_loss_base'] as number,
    TRAINING_WIN: configs['gold_rewards.training_win'] as number,
    TRAINING_LOSS: configs['gold_rewards.training_loss'] as number,
    REVENGE_MULTIPLIER: configs['gold_rewards.revenge_multiplier'] as number,
  }
}

// --- XP Rewards ---
export async function getXpRewardsConfig() {
  const configs = await getGameConfigs({
    'xp_rewards.pvp_win_xp': XP_REWARDS.PVP_WIN_XP,
    'xp_rewards.pvp_loss_xp': XP_REWARDS.PVP_LOSS_XP,
    'xp_rewards.training_win_xp': XP_REWARDS.TRAINING_WIN_XP,
    'xp_rewards.training_loss_xp': XP_REWARDS.TRAINING_LOSS_XP,
  })
  return {
    PVP_WIN_XP: configs['xp_rewards.pvp_win_xp'] as number,
    PVP_LOSS_XP: configs['xp_rewards.pvp_loss_xp'] as number,
    TRAINING_WIN_XP: configs['xp_rewards.training_win_xp'] as number,
    TRAINING_LOSS_XP: configs['xp_rewards.training_loss_xp'] as number,
  }
}

// --- First Win Bonus ---
export async function getFirstWinBonusConfig() {
  const configs = await getGameConfigs({
    'first_win_bonus.gold_mult': FIRST_WIN_BONUS.GOLD_MULT,
    'first_win_bonus.xp_mult': FIRST_WIN_BONUS.XP_MULT,
  })
  return {
    GOLD_MULT: configs['first_win_bonus.gold_mult'] as number,
    XP_MULT: configs['first_win_bonus.xp_mult'] as number,
  }
}

// --- Combat ---
export async function getCombatConfig() {
  const configs = await getGameConfigs({
    'combat.max_turns': COMBAT.MAX_TURNS,
    'combat.min_damage': COMBAT.MIN_DAMAGE,
    'combat.crit_multiplier': COMBAT.CRIT_MULTIPLIER,
    'combat.max_crit_chance': COMBAT.MAX_CRIT_CHANCE,
    'combat.max_dodge_chance': COMBAT.MAX_DODGE_CHANCE,
    'combat.rogue_dodge_bonus': COMBAT.ROGUE_DODGE_BONUS,
    'combat.tank_damage_reduction': COMBAT.TANK_DAMAGE_REDUCTION,
    'combat.damage_variance': COMBAT.DAMAGE_VARIANCE,
    'combat.poison_armor_penetration': COMBAT.POISON_ARMOR_PENETRATION,
    'combat.crit_per_luk': COMBAT.CRIT_PER_LUK,
    'combat.crit_per_agi': COMBAT.CRIT_PER_AGI,
    'combat.dodge_per_agi': COMBAT.DODGE_PER_AGI,
    'combat.dodge_per_luk': COMBAT.DODGE_PER_LUK,
    'combat.cha_intimidation_per_point': COMBAT.CHA_INTIMIDATION_PER_POINT,
    'combat.cha_intimidation_cap': COMBAT.CHA_INTIMIDATION_CAP,
  })
  return {
    MAX_TURNS: configs['combat.max_turns'] as number,
    MIN_DAMAGE: configs['combat.min_damage'] as number,
    CRIT_MULTIPLIER: configs['combat.crit_multiplier'] as number,
    MAX_CRIT_CHANCE: configs['combat.max_crit_chance'] as number,
    MAX_DODGE_CHANCE: configs['combat.max_dodge_chance'] as number,
    ROGUE_DODGE_BONUS: configs['combat.rogue_dodge_bonus'] as number,
    TANK_DAMAGE_REDUCTION: configs['combat.tank_damage_reduction'] as number,
    DAMAGE_VARIANCE: configs['combat.damage_variance'] as number,
    POISON_ARMOR_PENETRATION: configs['combat.poison_armor_penetration'] as number,
    CRIT_PER_LUK: configs['combat.crit_per_luk'] as number,
    CRIT_PER_AGI: configs['combat.crit_per_agi'] as number,
    DODGE_PER_AGI: configs['combat.dodge_per_agi'] as number,
    DODGE_PER_LUK: configs['combat.dodge_per_luk'] as number,
    CHA_INTIMIDATION_PER_POINT: configs['combat.cha_intimidation_per_point'] as number,
    CHA_INTIMIDATION_CAP: configs['combat.cha_intimidation_cap'] as number,
  }
}

// --- ELO ---
export async function getEloConfig() {
  const configs = await getGameConfigs({
    'elo.k_calibration': ELO.K_CALIBRATION,
    'elo.k_default': ELO.K_DEFAULT,
    'elo.calibration_games': ELO.CALIBRATION_GAMES,
    'elo.min_rating': ELO.MIN_RATING,
  })
  return {
    K_CALIBRATION: configs['elo.k_calibration'] as number,
    K_DEFAULT: configs['elo.k_default'] as number,
    CALIBRATION_GAMES: configs['elo.calibration_games'] as number,
    MIN_RATING: configs['elo.min_rating'] as number,
  }
}

// --- PvP Ranks ---
export async function getPvpRanksConfig() {
  const configs = await getGameConfigs({
    'pvp_ranks.bronze': PVP_RANKS.BRONZE,
    'pvp_ranks.silver': PVP_RANKS.SILVER,
    'pvp_ranks.gold': PVP_RANKS.GOLD,
    'pvp_ranks.platinum': PVP_RANKS.PLATINUM,
    'pvp_ranks.diamond': PVP_RANKS.DIAMOND,
    'pvp_ranks.grandmaster': PVP_RANKS.GRANDMASTER,
  })
  return {
    BRONZE: configs['pvp_ranks.bronze'] as number,
    SILVER: configs['pvp_ranks.silver'] as number,
    GOLD: configs['pvp_ranks.gold'] as number,
    PLATINUM: configs['pvp_ranks.platinum'] as number,
    DIAMOND: configs['pvp_ranks.diamond'] as number,
    GRANDMASTER: configs['pvp_ranks.grandmaster'] as number,
  }
}

// --- Prestige ---
export async function getPrestigeConfig() {
  const configs = await getGameConfigs({
    'prestige.max_level': PRESTIGE.MAX_LEVEL,
    'prestige.stat_bonus_per_prestige': PRESTIGE.STAT_BONUS_PER_PRESTIGE,
    'prestige.stat_points_per_level': PRESTIGE.STAT_POINTS_PER_LEVEL,
  })
  return {
    MAX_LEVEL: configs['prestige.max_level'] as number,
    STAT_BONUS_PER_PRESTIGE: configs['prestige.stat_bonus_per_prestige'] as number,
    STAT_POINTS_PER_LEVEL: configs['prestige.stat_points_per_level'] as number,
  }
}

// --- Battle Pass ---
export async function getBattlePassConfig() {
  const configs = await getGameConfigs({
    'battle_pass.bp_xp_per_pvp': BATTLE_PASS.BP_XP_PER_PVP,
    'battle_pass.bp_xp_per_dungeon_floor': BATTLE_PASS.BP_XP_PER_DUNGEON_FLOOR,
    'battle_pass.bp_xp_per_quest': BATTLE_PASS.BP_XP_PER_QUEST,
    'battle_pass.bp_xp_per_achievement': BATTLE_PASS.BP_XP_PER_ACHIEVEMENT,
  })
  return {
    BP_XP_PER_PVP: configs['battle_pass.bp_xp_per_pvp'] as number,
    BP_XP_PER_DUNGEON_FLOOR: configs['battle_pass.bp_xp_per_dungeon_floor'] as number,
    BP_XP_PER_QUEST: configs['battle_pass.bp_xp_per_quest'] as number,
    BP_XP_PER_ACHIEVEMENT: configs['battle_pass.bp_xp_per_achievement'] as number,
  }
}

// --- Skills ---
export async function getSkillsConfig() {
  const configs = await getGameConfigs({
    'skills.max_equipped_slots': SKILLS.MAX_EQUIPPED_SLOTS,
    'skills.upgrade_gold_base': SKILLS.UPGRADE_GOLD_BASE,
    'skills.upgrade_gold_per_rank': SKILLS.UPGRADE_GOLD_PER_RANK,
    'skills.learn_gold_cost': SKILLS.LEARN_GOLD_COST,
  })
  return {
    MAX_EQUIPPED_SLOTS: configs['skills.max_equipped_slots'] as number,
    UPGRADE_GOLD_BASE: configs['skills.upgrade_gold_base'] as number,
    UPGRADE_GOLD_PER_RANK: configs['skills.upgrade_gold_per_rank'] as number,
    LEARN_GOLD_COST: configs['skills.learn_gold_cost'] as number,
  }
}

// --- Passives ---
export async function getPassivesConfig() {
  const configs = await getGameConfigs({
    'passives.points_per_level': PASSIVES.POINTS_PER_LEVEL,
    'passives.max_passive_points': PASSIVES.MAX_PASSIVE_POINTS,
    'passives.respec_gem_cost': PASSIVES.RESPEC_GEM_COST,
  })
  return {
    POINTS_PER_LEVEL: configs['passives.points_per_level'] as number,
    MAX_PASSIVE_POINTS: configs['passives.max_passive_points'] as number,
    RESPEC_GEM_COST: configs['passives.respec_gem_cost'] as number,
  }
}

// --- Gem Costs ---
export async function getGemCostsConfig() {
  const configs = await getGameConfigs({
    'gem_costs.stamina_refill': GEM_COSTS.STAMINA_REFILL,
    'gem_costs.extra_pvp_combat': GEM_COSTS.EXTRA_PVP_COMBAT,
    'gem_costs.battle_pass_premium': GEM_COSTS.BATTLE_PASS_PREMIUM,
    'gem_costs.gold_mine_buy_slot': GEM_COSTS.GOLD_MINE_BUY_SLOT,
    'gem_costs.gold_mine_boost': GEM_COSTS.GOLD_MINE_BOOST,
  })
  return {
    STAMINA_REFILL: configs['gem_costs.stamina_refill'] as number,
    EXTRA_PVP_COMBAT: configs['gem_costs.extra_pvp_combat'] as number,
    BATTLE_PASS_PREMIUM: configs['gem_costs.battle_pass_premium'] as number,
    GOLD_MINE_BUY_SLOT: configs['gem_costs.gold_mine_buy_slot'] as number,
    GOLD_MINE_BOOST: configs['gem_costs.gold_mine_boost'] as number,
  }
}

// --- Inventory ---
export async function getInventoryConfig() {
  const configs = await getGameConfigs({
    'inventory.max_slots': INVENTORY.MAX_SLOTS,
    'inventory.base_slots': INVENTORY.BASE_SLOTS,
    'inventory.expand_amount': INVENTORY.EXPAND_AMOUNT,
    'inventory.expand_cost_gold': INVENTORY.EXPAND_COST_GOLD,
    'inventory.max_expansions': INVENTORY.MAX_EXPANSIONS,
  })
  return {
    MAX_SLOTS: configs['inventory.max_slots'] as number,
    BASE_SLOTS: configs['inventory.base_slots'] as number,
    EXPAND_AMOUNT: configs['inventory.expand_amount'] as number,
    EXPAND_COST_GOLD: configs['inventory.expand_cost_gold'] as number,
    MAX_EXPANSIONS: configs['inventory.max_expansions'] as number,
  }
}

// --- Drop Chances ---
export async function getDropChancesConfig() {
  const configs = await getGameConfigs({
    'drop_chances.pvp': DROP_CHANCES.pvp,
    'drop_chances.training': DROP_CHANCES.training,
    'drop_chances.dungeon_easy': DROP_CHANCES.dungeon_easy,
    'drop_chances.dungeon_normal': DROP_CHANCES.dungeon_normal,
    'drop_chances.dungeon_hard': DROP_CHANCES.dungeon_hard,
    'drop_chances.boss': DROP_CHANCES.boss,
  })
  return {
    pvp: configs['drop_chances.pvp'] as number,
    training: configs['drop_chances.training'] as number,
    dungeon_easy: configs['drop_chances.dungeon_easy'] as number,
    dungeon_normal: configs['drop_chances.dungeon_normal'] as number,
    dungeon_hard: configs['drop_chances.dungeon_hard'] as number,
    boss: configs['drop_chances.boss'] as number,
  }
}

// --- Rarity Distribution ---
export async function getRarityDistributionConfig() {
  const configs = await getGameConfigs({
    'rarity_distribution.common': RARITY_DISTRIBUTION.common,
    'rarity_distribution.uncommon': RARITY_DISTRIBUTION.uncommon,
    'rarity_distribution.rare': RARITY_DISTRIBUTION.rare,
    'rarity_distribution.epic': RARITY_DISTRIBUTION.epic,
    'rarity_distribution.legendary': RARITY_DISTRIBUTION.legendary,
  })
  return {
    common: configs['rarity_distribution.common'] as number,
    uncommon: configs['rarity_distribution.uncommon'] as number,
    rare: configs['rarity_distribution.rare'] as number,
    epic: configs['rarity_distribution.epic'] as number,
    legendary: configs['rarity_distribution.legendary'] as number,
  }
}

// --- Upgrade Chances ---
export async function getUpgradeChancesConfig(): Promise<number[]> {
  return await getGameConfig<number[]>('upgrade_chances', [...UPGRADE_CHANCES])
}

// --- Win Streak Bonuses ---
export async function getWinStreakConfig() {
  const configs = await getGameConfigs({
    'win_streak.3_bonus': WIN_STREAK_BONUSES[3] ?? 0.2,
    'win_streak.5_bonus': WIN_STREAK_BONUSES[5] ?? 0.5,
    'win_streak.8_bonus': WIN_STREAK_BONUSES[8] ?? 1.0,
  })
  return {
    BONUS_3: configs['win_streak.3_bonus'] as number,
    BONUS_5: configs['win_streak.5_bonus'] as number,
    BONUS_8: configs['win_streak.8_bonus'] as number,
  }
}

// --- Daily Login Rewards ---
export async function getDailyLoginRewardsConfig(): Promise<readonly DailyLoginRewardDef[]> {
  return await getGameConfig<readonly DailyLoginRewardDef[]>(
    'daily_login_rewards',
    DAILY_LOGIN_REWARDS,
  )
}

// --- Extra PVP ---
export async function getExtraPvpConfig() {
  const configs = await getGameConfigs({
    'extra_pvp.stamina_granted': EXTRA_PVP.STAMINA_GRANTED,
  })
  return {
    STAMINA_GRANTED: configs['extra_pvp.stamina_granted'] as number,
  }
}
