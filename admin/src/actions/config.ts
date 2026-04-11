'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'

export async function getAllConfigs() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.gameConfig.findMany({
    orderBy: [{ category: 'asc' }, { key: 'asc' }],
  })
}

export async function getConfig(key: string) {
  const config = await prisma.gameConfig.findUnique({ where: { key } })
  return config?.value ?? null
}

export async function updateConfig(key: string, value: unknown, adminId?: string) {
  const admin = adminId ? { id: adminId } : await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const config = await prisma.gameConfig.upsert({
    where: { key },
    update: {
      value: value as never,
      updatedBy: admin.id,
    },
    create: {
      key,
      value: value as never,
      category: 'general',
      updatedBy: admin.id,
    },
  })

  await prisma.adminLog.create({
    data: {
      adminId: admin.id,
      action: 'update_config',
      target: key,
      details: { value } as never,
    },
  })

  return config
}

export async function deleteConfig(key: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  await prisma.gameConfig.delete({ where: { key } })
  return { success: true }
}

export async function seedDefaultConfigs() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const defaults: { key: string; value: unknown; category: string; description: string }[] = [
    // Stamina
    { key: 'stamina.max', value: 120, category: 'stamina', description: 'Maximum stamina capacity' },
    { key: 'stamina.regen_rate', value: 1, category: 'stamina', description: 'Stamina points regenerated per tick' },
    { key: 'stamina.regen_interval_minutes', value: 8, category: 'stamina', description: 'Minutes between stamina regeneration ticks' },
    { key: 'stamina.pvp_cost', value: 10, category: 'stamina', description: 'Stamina cost per PvP match' },
    { key: 'stamina.dungeon_easy', value: 15, category: 'stamina', description: 'Stamina cost for easy dungeon' },
    { key: 'stamina.dungeon_normal', value: 20, category: 'stamina', description: 'Stamina cost for normal dungeon' },
    { key: 'stamina.dungeon_hard', value: 25, category: 'stamina', description: 'Stamina cost for hard dungeon' },
    { key: 'stamina.boss', value: 40, category: 'stamina', description: 'Stamina cost for boss fight' },
    { key: 'stamina.training', value: 5, category: 'stamina', description: 'Stamina cost per training session' },
    { key: 'stamina.free_pvp_per_day', value: 3, category: 'stamina', description: 'Free PvP matches per day (no stamina cost)' },

    // Gold Rewards
    { key: 'gold_rewards.pvp_win_base', value: 150, category: 'gold_rewards', description: 'Base gold reward for PvP win' },
    { key: 'gold_rewards.pvp_loss_base', value: 50, category: 'gold_rewards', description: 'Base gold reward for PvP loss' },
    { key: 'gold_rewards.training_win', value: 50, category: 'gold_rewards', description: 'Gold reward for training win' },
    { key: 'gold_rewards.training_loss', value: 20, category: 'gold_rewards', description: 'Gold reward for training loss' },
    { key: 'gold_rewards.revenge_multiplier', value: 1.5, category: 'gold_rewards', description: 'Multiplier for revenge match gold rewards' },

    // XP Rewards
    { key: 'xp_rewards.pvp_win_xp', value: 120, category: 'xp_rewards', description: 'XP reward for PvP win' },
    { key: 'xp_rewards.pvp_loss_xp', value: 40, category: 'xp_rewards', description: 'XP reward for PvP loss' },
    { key: 'xp_rewards.training_win_xp', value: 60, category: 'xp_rewards', description: 'XP reward for training win' },
    { key: 'xp_rewards.training_loss_xp', value: 20, category: 'xp_rewards', description: 'XP reward for training loss' },

    // First Win Bonus
    { key: 'first_win_bonus.gold_mult', value: 2, category: 'first_win_bonus', description: 'Gold multiplier for first win of the day' },
    { key: 'first_win_bonus.xp_mult', value: 2, category: 'first_win_bonus', description: 'XP multiplier for first win of the day' },

    // Drop Chances
    { key: 'drop_chances.pvp', value: 0.15, category: 'drop_chances', description: 'Item drop chance from PvP matches' },
    { key: 'drop_chances.training', value: 0.05, category: 'drop_chances', description: 'Item drop chance from training' },
    { key: 'drop_chances.dungeon_easy', value: 0.20, category: 'drop_chances', description: 'Item drop chance from easy dungeons' },
    { key: 'drop_chances.dungeon_normal', value: 0.30, category: 'drop_chances', description: 'Item drop chance from normal dungeons' },
    { key: 'drop_chances.dungeon_hard', value: 0.40, category: 'drop_chances', description: 'Item drop chance from hard dungeons' },
    { key: 'drop_chances.boss', value: 0.75, category: 'drop_chances', description: 'Item drop chance from boss fights' },

    // Rarity Distribution
    { key: 'rarity_distribution.common', value: 50, category: 'rarity_distribution', description: 'Common item drop weight (%)' },
    { key: 'rarity_distribution.uncommon', value: 30, category: 'rarity_distribution', description: 'Uncommon item drop weight (%)' },
    { key: 'rarity_distribution.rare', value: 15, category: 'rarity_distribution', description: 'Rare item drop weight (%)' },
    { key: 'rarity_distribution.epic', value: 4, category: 'rarity_distribution', description: 'Epic item drop weight (%)' },
    { key: 'rarity_distribution.legendary', value: 1, category: 'rarity_distribution', description: 'Legendary item drop weight (%)' },

    // ELO
    { key: 'elo.k_calibration', value: 48, category: 'elo', description: 'K-factor for calibration matches (higher = more volatile)' },
    { key: 'elo.k_default', value: 32, category: 'elo', description: 'K-factor for regular matches' },
    { key: 'elo.calibration_games', value: 10, category: 'elo', description: 'Number of calibration games before stable rating' },
    { key: 'elo.min_rating', value: 0, category: 'elo', description: 'Minimum possible ELO rating' },

    // PvP Ranks (W3.D5 — Variant A: 8 tiers × 3 divisions, 750 ELO per tier, 250 per division;
    // Master added; Challenger = top-100 by leaderboard rank, computed at query time)
    { key: 'pvp_ranks.bronze', value: 0, category: 'pvp_ranks', description: 'Minimum ELO for Bronze rank (0-749)' },
    { key: 'pvp_ranks.silver', value: 750, category: 'pvp_ranks', description: 'Minimum ELO for Silver rank (750-1499) — starting tier (Silver II)' },
    { key: 'pvp_ranks.gold', value: 1500, category: 'pvp_ranks', description: 'Minimum ELO for Gold rank (1500-2249)' },
    { key: 'pvp_ranks.platinum', value: 2250, category: 'pvp_ranks', description: 'Minimum ELO for Platinum rank (2250-2999)' },
    { key: 'pvp_ranks.diamond', value: 3000, category: 'pvp_ranks', description: 'Minimum ELO for Diamond rank (3000-3749)' },
    { key: 'pvp_ranks.master', value: 3750, category: 'pvp_ranks', description: 'Minimum ELO for Master rank (3750-4249, no divisions) — W3.D5 new' },
    { key: 'pvp_ranks.grandmaster', value: 4250, category: 'pvp_ranks', description: 'Minimum ELO for Grandmaster rank (4250+, no divisions)' },

    // Combat
    { key: 'combat.max_turns', value: 15, category: 'combat', description: 'Maximum turns per combat encounter' },
    { key: 'combat.min_damage', value: 1, category: 'combat', description: 'Minimum damage dealt per attack' },
    { key: 'combat.crit_multiplier', value: 1.5, category: 'combat', description: 'Critical hit damage multiplier' },
    { key: 'combat.max_crit_chance', value: 50, category: 'combat', description: 'Maximum critical hit chance (%)' },
    { key: 'combat.max_dodge_chance', value: 30, category: 'combat', description: 'Maximum dodge chance (%)' },
    { key: 'combat.rogue_dodge_bonus', value: 4, category: 'combat', description: 'Rogue class bonus dodge chance (%) — W3.D2' },
    { key: 'combat.tank_damage_reduction', value: 0.85, category: 'combat', description: 'Tank damage multiplier (0.85 = 15% reduction)' },
    { key: 'combat.damage_variance', value: 0.10, category: 'combat', description: 'Damage variance range (±10%)' },
    { key: 'combat.poison_armor_penetration', value: 0.3, category: 'combat', description: 'Poison ignores this % of armor' },
    { key: 'combat.crit_per_luk', value: 0.6, category: 'combat', description: 'Crit chance per LUK point (%) — W3.D2' },
    { key: 'combat.crit_per_agi', value: 0.2, category: 'combat', description: 'Crit chance per AGI point (%) — W3.D2' },
    { key: 'combat.dodge_per_agi', value: 0.2, category: 'combat', description: 'Dodge chance per AGI point (%)' },
    { key: 'combat.dodge_per_luk', value: 0.1, category: 'combat', description: 'Dodge chance per LUK point (%)' },
    // W3.D1 — CHA miss chance (replaces legacy cha_intimidation_*)
    { key: 'combat.cha_miss_per_point', value: 0.2, category: 'combat', description: 'Miss chance per CHA point of defender (%) — W3.D1' },
    { key: 'combat.cha_miss_cap', value: 20, category: 'combat', description: 'Max CHA-induced miss chance (%) — W3.D1' },
    // W3.D2 — Rogue Execute finisher
    { key: 'combat.rogue_execute_hp_threshold', value: 0.35, category: 'combat', description: 'Defender HP ratio that arms Rogue Execute (W3.D2)' },
    { key: 'combat.rogue_execute_damage_bonus', value: 0.15, category: 'combat', description: 'Final damage bonus when Rogue Execute triggers (W3.D2)' },

    // W3.D4 — Daily training XP diminishing returns (LoL FWoTD + RAID pattern)
    { key: 'training_xp_dr.full_xp_clears', value: 6, category: 'training_xp_dr', description: 'First N dungeon clears/day award 100% XP (W3.D4)' },
    { key: 'training_xp_dr.half_xp_clears', value: 6, category: 'training_xp_dr', description: 'Next M clears award 50% XP before falling to floor (W3.D4)' },
    { key: 'training_xp_dr.floor_multiplier', value: 0.1, category: 'training_xp_dr', description: 'Minimum XP multiplier after half window — never zero (W3.D4)' },

    // W3.D4 — Stamina refill diminishing returns + hard daily cap (Clash Royale / Genshin pattern)
    { key: 'stamina_refill_dr.daily_cap', value: 4, category: 'stamina_refill_dr', description: 'Maximum gem refills per day — hard gate (W3.D4)' },
    { key: 'stamina_refill_dr.cost_multipliers', value: [1, 1.5, 2.5, 4], category: 'stamina_refill_dr', description: 'Cost multipliers applied in order for refills 1..N (W3.D4)' },

    // Win Streaks (W3.D3 — capped at +50% to hit sink-ratio target)
    { key: 'win_streak.3_bonus', value: 0.15, category: 'win_streak', description: '3-win streak gold bonus (W3.D3: +15%, was +20%)' },
    { key: 'win_streak.5_bonus', value: 0.3,  category: 'win_streak', description: '5-win streak gold bonus (W3.D3: +30%, was +50%)' },
    { key: 'win_streak.8_bonus', value: 0.5,  category: 'win_streak', description: '8+ win streak gold bonus (W3.D3: +50%, was +100%)' },

    // Loss Streak Recovery (W3.D3 — capped at +50%)
    { key: 'loss_streak.3_bonus', value: 0.2,  category: 'loss_streak', description: '3-loss streak recovery bonus (W3.D3: +20%, was +30%)' },
    { key: 'loss_streak.5_bonus', value: 0.35, category: 'loss_streak', description: '5-loss streak recovery bonus (W3.D3: +35%, was +50%)' },
    { key: 'loss_streak.7_bonus', value: 0.5,  category: 'loss_streak', description: '7+ loss streak recovery bonus (W3.D3: +50%, was +80%)' },

    // CHA gold bonus cap (W3.D3 — lowered 125% → 80% after CHA moved to miss-chance in W3.D1)
    { key: 'cha.gold_bonus_cap', value: 0.80, category: 'charisma', description: 'Max multiplier chaGoldBonus can return (W3.D3: 0.80, was 1.25)' },

    // Repair costs (W3.D3 — bumped to lift sink ratio into the 55-65% band)
    { key: 'repair.base_cost',   value: 120, category: 'repair', description: 'Base repair cost per item (W3.D3: 120, was 80)' },
    { key: 'repair.per_level',   value: 20,  category: 'repair', description: 'Additional repair cost per item level (W3.D3: 20, was 15)' },

    // Consumable price bump (W3.D3 — 25% up across the board to match inflation-adjusted income)
    { key: 'consumable.price.stamina_potion_small',  value: 125, category: 'consumable_prices', description: 'S. Stamina Potion price (W3.D3: 125, was 100)' },
    { key: 'consumable.price.stamina_potion_medium', value: 315, category: 'consumable_prices', description: 'M. Stamina Potion price (W3.D3: 315, was 250)' },
    { key: 'consumable.price.stamina_potion_large',  value: 625, category: 'consumable_prices', description: 'L. Stamina Potion price (W3.D3: 625, was 500)' },
    { key: 'consumable.price.health_potion_small',   value: 190, category: 'consumable_prices', description: 'S. Health Potion price (W3.D3: 190, was 150)' },
    { key: 'consumable.price.health_potion_medium',  value: 440, category: 'consumable_prices', description: 'M. Health Potion price (W3.D3: 440, was 350)' },
    { key: 'consumable.price.health_potion_large',   value: 875, category: 'consumable_prices', description: 'L. Health Potion price (W3.D3: 875, was 700)' },

    // Matchmaking
    { key: 'matchmaking.level_range', value: 3, category: 'matchmaking', description: 'Level range for opponent matching (±)' },
    { key: 'matchmaking.gear_score_tolerance', value: 0.3, category: 'matchmaking', description: 'Gear score tolerance (±30%)' },

    // Prestige
    { key: 'prestige.max_level', value: 50, category: 'prestige', description: 'Maximum character level before prestige' },
    { key: 'prestige.stat_bonus_per_prestige', value: 0.05, category: 'prestige', description: 'Stat bonus per prestige level (5% each)' },
    { key: 'prestige.stat_points_per_level', value: 3, category: 'prestige', description: 'Stat points awarded per level up' },

    // Upgrade Chances
    { key: 'upgrade_chances', value: [100, 100, 100, 100, 100, 80, 60, 40, 25, 15], category: 'upgrade', description: 'Success rate (%) for each upgrade level (+1 through +10)' },

    // Battle Pass
    { key: 'battle_pass.bp_xp_per_pvp', value: 20, category: 'battle_pass', description: 'Battle Pass XP earned per PvP match' },
    { key: 'battle_pass.bp_xp_per_dungeon_floor', value: 30, category: 'battle_pass', description: 'Battle Pass XP earned per dungeon floor cleared' },
    { key: 'battle_pass.bp_xp_per_quest', value: 50, category: 'battle_pass', description: 'Battle Pass XP earned per daily quest completed' },
    { key: 'battle_pass.bp_xp_per_achievement', value: 100, category: 'battle_pass', description: 'Battle Pass XP earned per achievement completed' },

    // HP Regen
    { key: 'hp_regen.regen_rate', value: 1, category: 'hp_regen', description: '% of maxHP regenerated per tick' },
    { key: 'hp_regen.regen_interval_minutes', value: 5, category: 'hp_regen', description: 'Minutes between HP regen ticks' },

    // Skills
    { key: 'skills.max_equipped_slots', value: 4, category: 'skills', description: 'Maximum equipped skill slots' },
    { key: 'skills.upgrade_gold_base', value: 500, category: 'skills', description: 'Base gold cost to upgrade a skill' },
    { key: 'skills.upgrade_gold_per_rank', value: 500, category: 'skills', description: 'Additional gold per rank for skill upgrade' },
    { key: 'skills.learn_gold_cost', value: 200, category: 'skills', description: 'Gold cost to learn a new skill' },

    // Passives
    { key: 'passives.points_per_level', value: 1, category: 'passives', description: 'Passive points gained per level up' },
    { key: 'passives.max_passive_points', value: 50, category: 'passives', description: 'Maximum total passive points' },
    { key: 'passives.respec_gem_cost', value: 50, category: 'passives', description: 'Gems to reset passive tree' },

    // Gem Costs
    { key: 'gem_costs.stamina_refill', value: 30, category: 'gem_costs', description: 'Gems to fully refill stamina' },
    { key: 'gem_costs.extra_pvp_combat', value: 50, category: 'gem_costs', description: 'Gems for extra PvP when out of stamina' },
    { key: 'gem_costs.battle_pass_premium', value: 500, category: 'gem_costs', description: 'Gems to unlock premium battle pass' },
    { key: 'gem_costs.gold_mine_buy_slot', value: 50, category: 'gem_costs', description: 'Gems to buy additional gold mine slot' },
    { key: 'gem_costs.gold_mine_boost', value: 10, category: 'gem_costs', description: 'Gems to boost gold mine (2x reward)' },

    // Inventory
    // NOTE: `inventory.max_slots` removed (CRIT-04). MAX_SLOTS is derived from
    // base_slots + max_expansions * expand_amount, not a separate configurable key.
    { key: 'inventory.base_slots', value: 28, category: 'inventory', description: 'Starting inventory slots' },
    { key: 'inventory.expand_amount', value: 10, category: 'inventory', description: 'Slots added per expansion' },
    { key: 'inventory.expand_cost_gold', value: 5000, category: 'inventory', description: 'Gold cost per inventory expansion' },
    { key: 'inventory.max_expansions', value: 3, category: 'inventory', description: 'Maximum number of inventory expansions' },
  ]

  let created = 0
  let skipped = 0

  for (const cfg of defaults) {
    const existing = await prisma.gameConfig.findUnique({ where: { key: cfg.key } })
    if (existing) {
      skipped++
      continue
    }
    await prisma.gameConfig.create({
      data: {
        key: cfg.key,
        value: cfg.value as never,
        category: cfg.category,
        description: cfg.description,
      },
    })
    created++
  }

  return { created, skipped, total: defaults.length }
}
