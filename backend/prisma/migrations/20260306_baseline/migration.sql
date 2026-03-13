-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "public"."CharacterClass" AS ENUM ('warrior', 'rogue', 'mage', 'tank');

-- CreateEnum
CREATE TYPE "public"."CharacterGender" AS ENUM ('male', 'female');

-- CreateEnum
CREATE TYPE "public"."CharacterOrigin" AS ENUM ('human', 'orc', 'skeleton', 'demon', 'dogfolk');

-- CreateEnum
CREATE TYPE "public"."ConsumableType" AS ENUM ('stamina_potion_small', 'stamina_potion_medium', 'stamina_potion_large', 'health_potion_small', 'health_potion_medium', 'health_potion_large');

-- CreateEnum
CREATE TYPE "public"."CosmeticType" AS ENUM ('frame', 'title', 'effect', 'skin');

-- CreateEnum
CREATE TYPE "public"."DungeonDifficulty" AS ENUM ('easy', 'normal', 'hard', 'nightmare', 'rush');

-- CreateEnum
CREATE TYPE "public"."DungeonType" AS ENUM ('story', 'side', 'event', 'endgame');

-- CreateEnum
CREATE TYPE "public"."EquippedSlot" AS ENUM ('weapon', 'weapon_offhand', 'helmet', 'chest', 'gloves', 'legs', 'boots', 'accessory', 'amulet', 'belt', 'relic', 'necklace', 'ring', 'ring2');

-- CreateEnum
CREATE TYPE "public"."EventType" AS ENUM ('boss_rush', 'gold_rush', 'class_spotlight', 'tournament');

-- CreateEnum
CREATE TYPE "public"."ItemType" AS ENUM ('weapon', 'helmet', 'chest', 'gloves', 'legs', 'boots', 'accessory', 'amulet', 'belt', 'relic', 'necklace', 'ring', 'consumable');

-- CreateEnum
CREATE TYPE "public"."PassiveBonusType" AS ENUM ('flat_stat', 'percent_stat', 'flat_damage', 'percent_damage', 'flat_crit_chance', 'flat_dodge_chance', 'flat_hp', 'percent_hp', 'flat_armor', 'flat_magic_resist', 'percent_armor', 'percent_magic_resist', 'lifesteal', 'cooldown_reduction', 'damage_reduction');

-- CreateEnum
CREATE TYPE "public"."QuestType" AS ENUM ('pvp_wins', 'dungeons_complete', 'gold_spent', 'item_upgrade', 'consumable_use', 'shell_game_play', 'gold_mine_collect');

-- CreateEnum
CREATE TYPE "public"."Rarity" AS ENUM ('common', 'uncommon', 'rare', 'epic', 'legendary');

-- CreateEnum
CREATE TYPE "public"."SkillDamageType" AS ENUM ('physical', 'magical', 'true_damage', 'poison');

-- CreateEnum
CREATE TYPE "public"."SkillTargetType" AS ENUM ('single_enemy', 'self_buff', 'aoe');

-- CreateTable
CREATE TABLE "public"."achievements" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "achievement_key" TEXT NOT NULL,
    "progress" INTEGER NOT NULL DEFAULT 0,
    "target" INTEGER NOT NULL,
    "completed" BOOLEAN NOT NULL DEFAULT false,
    "completed_at" TIMESTAMP(3),
    "reward_claimed" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "achievements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."admin_logs" (
    "id" TEXT NOT NULL,
    "admin_id" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "target" TEXT,
    "details" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "admin_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."appearance_skins" (
    "id" TEXT NOT NULL,
    "skin_key" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "gender" "public"."CharacterGender" NOT NULL,
    "rarity" TEXT NOT NULL DEFAULT 'common',
    "price_gold" INTEGER NOT NULL DEFAULT 0,
    "price_gems" INTEGER NOT NULL DEFAULT 0,
    "image_url" TEXT,
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "origin" "public"."CharacterOrigin" NOT NULL,
    "image_key" TEXT,

    CONSTRAINT "appearance_skins_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."balance_simulation_runs" (
    "id" TEXT NOT NULL,
    "run_type" TEXT NOT NULL,
    "config" JSONB NOT NULL,
    "results" JSONB NOT NULL,
    "summary" TEXT,
    "created_by" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "balance_simulation_runs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."battle_pass" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "season_id" TEXT NOT NULL,
    "premium" BOOLEAN NOT NULL DEFAULT false,
    "bp_xp" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "battle_pass_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."battle_pass_claims" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "battle_pass_id" TEXT NOT NULL,
    "reward_id" TEXT NOT NULL,
    "claimed_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "battle_pass_claims_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."battle_pass_rewards" (
    "id" TEXT NOT NULL,
    "season_id" TEXT NOT NULL,
    "bp_level" INTEGER NOT NULL,
    "is_premium" BOOLEAN NOT NULL DEFAULT false,
    "reward_type" TEXT NOT NULL,
    "reward_id" TEXT,
    "reward_amount" INTEGER NOT NULL DEFAULT 1,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "battle_pass_rewards_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."boss_abilities" (
    "id" TEXT NOT NULL,
    "boss_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "ability_type" TEXT NOT NULL,
    "damage" INTEGER NOT NULL DEFAULT 0,
    "cooldown" INTEGER NOT NULL DEFAULT 0,
    "special_effect" TEXT,
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "boss_abilities_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."character_passives" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "node_id" TEXT NOT NULL,
    "unlocked_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "character_passives_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."character_skills" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "skill_id" TEXT NOT NULL,
    "rank" INTEGER NOT NULL DEFAULT 1,
    "is_equipped" BOOLEAN NOT NULL DEFAULT false,
    "slot_index" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "character_skills_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."characters" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "character_name" TEXT NOT NULL,
    "class" "public"."CharacterClass" NOT NULL,
    "origin" "public"."CharacterOrigin" NOT NULL,
    "level" INTEGER NOT NULL DEFAULT 1,
    "current_xp" INTEGER NOT NULL DEFAULT 0,
    "prestige_level" INTEGER NOT NULL DEFAULT 0,
    "stat_points_available" INTEGER NOT NULL DEFAULT 0,
    "str" INTEGER NOT NULL DEFAULT 10,
    "agi" INTEGER NOT NULL DEFAULT 10,
    "vit" INTEGER NOT NULL DEFAULT 10,
    "end" INTEGER NOT NULL DEFAULT 10,
    "int" INTEGER NOT NULL DEFAULT 10,
    "wis" INTEGER NOT NULL DEFAULT 10,
    "luk" INTEGER NOT NULL DEFAULT 10,
    "cha" INTEGER NOT NULL DEFAULT 10,
    "gold" INTEGER NOT NULL DEFAULT 500,
    "arena_tokens" INTEGER NOT NULL DEFAULT 0,
    "max_hp" INTEGER NOT NULL DEFAULT 100,
    "current_hp" INTEGER NOT NULL DEFAULT 100,
    "armor" INTEGER NOT NULL DEFAULT 0,
    "magic_resist" INTEGER NOT NULL DEFAULT 0,
    "combat_stance" JSONB,
    "current_stamina" INTEGER NOT NULL DEFAULT 120,
    "max_stamina" INTEGER NOT NULL DEFAULT 120,
    "last_stamina_update" TIMESTAMP(3),
    "bonus_trainings" INTEGER NOT NULL DEFAULT 0,
    "bonus_trainings_date" TIMESTAMP(3),
    "bonus_trainings_buys" INTEGER NOT NULL DEFAULT 0,
    "pvp_rating" INTEGER NOT NULL DEFAULT 1000,
    "pvp_wins" INTEGER NOT NULL DEFAULT 0,
    "pvp_losses" INTEGER NOT NULL DEFAULT 0,
    "pvp_win_streak" INTEGER NOT NULL DEFAULT 0,
    "pvp_loss_streak" INTEGER NOT NULL DEFAULT 0,
    "highest_pvp_rank" INTEGER NOT NULL DEFAULT 1000,
    "pvp_calibration_games" INTEGER NOT NULL DEFAULT 0,
    "first_win_today" BOOLEAN NOT NULL DEFAULT false,
    "first_win_date" TIMESTAMP(3),
    "free_pvp_today" INTEGER NOT NULL DEFAULT 0,
    "free_pvp_date" TIMESTAMP(3),
    "gold_mine_slots" INTEGER NOT NULL DEFAULT 1,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_played" TIMESTAMP(3),
    "avatar" TEXT NOT NULL DEFAULT 'warlord',
    "gender" "public"."CharacterGender" NOT NULL DEFAULT 'male',
    "daily_bonus_date" TIMESTAMP(3),
    "passive_points_available" INTEGER NOT NULL DEFAULT 0,
    "last_hp_update" TIMESTAMP(3),
    "inventory_slots" INTEGER NOT NULL DEFAULT 28,
    "gear_score" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "characters_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."consumable_inventory" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "consumable_type" "public"."ConsumableType" NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 0,
    "acquired_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "consumable_inventory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."cosmetics" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "type" "public"."CosmeticType" NOT NULL,
    "ref_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "cosmetics_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."daily_login_rewards" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "current_day" INTEGER NOT NULL DEFAULT 1,
    "last_claim_date" TIMESTAMP(3),
    "streak" INTEGER NOT NULL DEFAULT 0,
    "total_claims" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "daily_login_rewards_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."daily_quests" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "quest_type" "public"."QuestType" NOT NULL,
    "progress" INTEGER NOT NULL DEFAULT 0,
    "target" INTEGER NOT NULL,
    "reward_gold" INTEGER NOT NULL DEFAULT 0,
    "reward_xp" INTEGER NOT NULL DEFAULT 0,
    "reward_gems" INTEGER NOT NULL DEFAULT 0,
    "completed" BOOLEAN NOT NULL DEFAULT false,
    "day" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "daily_quests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."design_tokens" (
    "id" TEXT NOT NULL DEFAULT 'global',
    "tokens" JSONB NOT NULL,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "updated_by" TEXT,

    CONSTRAINT "design_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."dungeon_bosses" (
    "id" TEXT NOT NULL,
    "dungeon_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "boss_type" TEXT,
    "level" INTEGER NOT NULL,
    "hp" INTEGER NOT NULL,
    "damage" INTEGER NOT NULL DEFAULT 0,
    "defense" INTEGER NOT NULL DEFAULT 0,
    "speed" INTEGER NOT NULL DEFAULT 0,
    "crit_chance" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "description" TEXT,
    "lore" TEXT,
    "image_url" TEXT,
    "image_prompt" TEXT,
    "floor_number" INTEGER NOT NULL,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "dungeon_bosses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."dungeon_drops" (
    "id" TEXT NOT NULL,
    "dungeon_id" TEXT NOT NULL,
    "item_id" TEXT NOT NULL,
    "drop_chance" DOUBLE PRECISION NOT NULL,
    "min_quantity" INTEGER NOT NULL DEFAULT 1,
    "max_quantity" INTEGER NOT NULL DEFAULT 1,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "dungeon_drops_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."dungeon_progress" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "dungeon_id" TEXT NOT NULL,
    "boss_index" INTEGER NOT NULL DEFAULT 0,
    "completed" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "dungeon_progress_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."dungeon_runs" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "current_floor" INTEGER NOT NULL DEFAULT 1,
    "state" JSONB,
    "seed" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "dungeon_id" TEXT NOT NULL DEFAULT 'training_camp',
    "difficulty" "public"."DungeonDifficulty" NOT NULL DEFAULT 'normal',

    CONSTRAINT "dungeon_runs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."dungeon_wave_enemies" (
    "id" TEXT NOT NULL,
    "wave_id" TEXT NOT NULL,
    "enemy_type" TEXT NOT NULL,
    "level" INTEGER NOT NULL,
    "count" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "dungeon_wave_enemies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."dungeon_waves" (
    "id" TEXT NOT NULL,
    "dungeon_id" TEXT NOT NULL,
    "wave_number" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "dungeon_waves_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."dungeons" (
    "id" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "lore" TEXT,
    "level_req" INTEGER NOT NULL DEFAULT 1,
    "energy_cost" INTEGER NOT NULL DEFAULT 20,
    "image_url" TEXT,
    "background_url" TEXT,
    "image_prompt" TEXT,
    "image_style" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "gold_reward" INTEGER NOT NULL DEFAULT 0,
    "xp_reward" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "difficulty" "public"."DungeonDifficulty" NOT NULL DEFAULT 'normal',
    "dungeon_type" "public"."DungeonType" NOT NULL DEFAULT 'story',

    CONSTRAINT "dungeons_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."equipment_inventory" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "item_id" TEXT NOT NULL,
    "upgrade_level" INTEGER NOT NULL DEFAULT 0,
    "durability" INTEGER NOT NULL DEFAULT 100,
    "max_durability" INTEGER NOT NULL DEFAULT 100,
    "is_equipped" BOOLEAN NOT NULL DEFAULT false,
    "equipped_slot" "public"."EquippedSlot",
    "rolled_stats" JSONB,
    "acquired_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "equipment_inventory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."events" (
    "id" TEXT NOT NULL,
    "event_key" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "event_type" "public"."EventType" NOT NULL,
    "config" JSONB NOT NULL,
    "start_at" TIMESTAMP(3) NOT NULL,
    "end_at" TIMESTAMP(3) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."game_config" (
    "key" TEXT NOT NULL,
    "value" JSONB NOT NULL,
    "category" TEXT NOT NULL DEFAULT 'general',
    "description" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "updated_by" TEXT,

    CONSTRAINT "game_config_pkey" PRIMARY KEY ("key")
);

-- CreateTable
CREATE TABLE "public"."gold_mine_sessions" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "slot_index" INTEGER NOT NULL,
    "started_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ends_at" TIMESTAMP(3) NOT NULL,
    "collected" BOOLEAN NOT NULL DEFAULT false,
    "reward" INTEGER NOT NULL DEFAULT 0,
    "boosted" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "gem_reward" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "gold_mine_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."iap_transactions" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "product_id" TEXT NOT NULL,
    "transaction_id" TEXT NOT NULL,
    "receipt_data" TEXT NOT NULL,
    "gems_awarded" INTEGER NOT NULL DEFAULT 0,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "verified_at" TIMESTAMP(3),

    CONSTRAINT "iap_transactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."item_balance_profiles" (
    "id" TEXT NOT NULL,
    "item_type" "public"."ItemType" NOT NULL,
    "stat_weights" JSONB NOT NULL,
    "power_weight" DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    "description" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "updated_by" TEXT,

    CONSTRAINT "item_balance_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."items" (
    "id" TEXT NOT NULL,
    "catalog_id" TEXT NOT NULL,
    "item_name" TEXT NOT NULL,
    "item_type" "public"."ItemType" NOT NULL,
    "rarity" "public"."Rarity" NOT NULL,
    "item_level" INTEGER NOT NULL DEFAULT 1,
    "base_stats" JSONB,
    "special_effect" TEXT,
    "unique_passive" TEXT,
    "class_restriction" TEXT,
    "set_name" TEXT,
    "buy_price" INTEGER NOT NULL DEFAULT 0,
    "sell_price" INTEGER NOT NULL DEFAULT 0,
    "description" TEXT,
    "image_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "drop_chance" DOUBLE PRECISION DEFAULT 0,
    "item_class" TEXT,
    "upgrade_config" JSONB,
    "image_key" TEXT,

    CONSTRAINT "items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."legendary_shards" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "shard_count" INTEGER NOT NULL DEFAULT 0,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "legendary_shards_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."minigame_sessions" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "game_type" TEXT NOT NULL,
    "bet_amount" INTEGER NOT NULL DEFAULT 0,
    "secret_data" JSONB,
    "status" TEXT NOT NULL DEFAULT 'active',
    "result" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "minigame_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."passive_connections" (
    "id" TEXT NOT NULL,
    "from_id" TEXT NOT NULL,
    "to_id" TEXT NOT NULL,

    CONSTRAINT "passive_connections_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."passive_nodes" (
    "id" TEXT NOT NULL,
    "node_key" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "bonus_type" "public"."PassiveBonusType" NOT NULL,
    "bonus_stat" TEXT,
    "bonus_value" DOUBLE PRECISION NOT NULL,
    "tier" INTEGER NOT NULL DEFAULT 1,
    "position_x" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "position_y" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "cost" INTEGER NOT NULL DEFAULT 1,
    "icon" TEXT,
    "class_restriction" "public"."CharacterClass",
    "is_start_node" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "passive_nodes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."push_tokens" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "push_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."pvp_matches" (
    "id" TEXT NOT NULL,
    "player1_id" TEXT NOT NULL,
    "player2_id" TEXT NOT NULL,
    "player1_rating_before" INTEGER NOT NULL,
    "player1_rating_after" INTEGER NOT NULL,
    "player2_rating_before" INTEGER NOT NULL,
    "player2_rating_after" INTEGER NOT NULL,
    "winner_id" TEXT,
    "loser_id" TEXT,
    "combat_log" JSONB NOT NULL,
    "match_duration" INTEGER NOT NULL DEFAULT 0,
    "turns_taken" INTEGER NOT NULL DEFAULT 0,
    "gold_reward" INTEGER NOT NULL DEFAULT 0,
    "xp_reward" INTEGER NOT NULL DEFAULT 0,
    "match_type" TEXT NOT NULL DEFAULT 'ranked',
    "season_number" INTEGER,
    "is_revenge" BOOLEAN NOT NULL DEFAULT false,
    "played_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "pvp_matches_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."revenge_queue" (
    "id" TEXT NOT NULL,
    "victim_id" TEXT NOT NULL,
    "attacker_id" TEXT NOT NULL,
    "match_id" TEXT NOT NULL,
    "is_seen" BOOLEAN NOT NULL DEFAULT false,
    "is_used" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "revenge_queue_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."seasons" (
    "id" TEXT NOT NULL,
    "number" INTEGER NOT NULL,
    "theme" TEXT,
    "start_at" TIMESTAMP(3) NOT NULL,
    "end_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "seasons_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."skills" (
    "id" TEXT NOT NULL,
    "skill_key" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "class_restriction" "public"."CharacterClass",
    "damage_base" INTEGER NOT NULL DEFAULT 0,
    "damage_scaling" JSONB,
    "damage_type" "public"."SkillDamageType" NOT NULL DEFAULT 'physical',
    "target_type" "public"."SkillTargetType" NOT NULL DEFAULT 'single_enemy',
    "cooldown" INTEGER NOT NULL DEFAULT 0,
    "mana_cost" INTEGER NOT NULL DEFAULT 0,
    "effect_json" JSONB,
    "unlock_level" INTEGER NOT NULL DEFAULT 1,
    "max_rank" INTEGER NOT NULL DEFAULT 5,
    "rank_scaling" DOUBLE PRECISION NOT NULL DEFAULT 0.1,
    "icon" TEXT,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "skills_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."training_sessions" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "xp_awarded" INTEGER NOT NULL DEFAULT 0,
    "won" BOOLEAN NOT NULL DEFAULT false,
    "turns" INTEGER NOT NULL DEFAULT 0,
    "opponent_type" TEXT,
    "played_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "training_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."users" (
    "id" TEXT NOT NULL,
    "email" TEXT,
    "username" TEXT,
    "password_hash" TEXT,
    "auth_provider" TEXT,
    "gems" INTEGER NOT NULL DEFAULT 0,
    "premium_until" TIMESTAMP(3),
    "role" TEXT NOT NULL DEFAULT 'player',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_login" TIMESTAMP(3),
    "is_banned" BOOLEAN NOT NULL DEFAULT false,
    "ban_reason" TEXT,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "achievements_character_id_achievement_key_key" ON "public"."achievements"("character_id" ASC, "achievement_key" ASC);

-- CreateIndex
CREATE INDEX "achievements_character_id_completed_idx" ON "public"."achievements"("character_id" ASC, "completed" ASC);

-- CreateIndex
CREATE INDEX "appearance_skins_origin_gender_idx" ON "public"."appearance_skins"("origin" ASC, "gender" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "appearance_skins_skin_key_key" ON "public"."appearance_skins"("skin_key" ASC);

-- CreateIndex
CREATE INDEX "balance_simulation_runs_run_type_created_at_idx" ON "public"."balance_simulation_runs"("run_type" ASC, "created_at" DESC);

-- CreateIndex
CREATE INDEX "battle_pass_character_id_idx" ON "public"."battle_pass"("character_id" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "battle_pass_character_id_season_id_key" ON "public"."battle_pass"("character_id" ASC, "season_id" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "battle_pass_claims_character_id_reward_id_key" ON "public"."battle_pass_claims"("character_id" ASC, "reward_id" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "battle_pass_rewards_season_id_bp_level_is_premium_key" ON "public"."battle_pass_rewards"("season_id" ASC, "bp_level" ASC, "is_premium" ASC);

-- CreateIndex
CREATE INDEX "character_passives_character_id_idx" ON "public"."character_passives"("character_id" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "character_passives_character_id_node_id_key" ON "public"."character_passives"("character_id" ASC, "node_id" ASC);

-- CreateIndex
CREATE INDEX "character_skills_character_id_is_equipped_idx" ON "public"."character_skills"("character_id" ASC, "is_equipped" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "character_skills_character_id_skill_id_key" ON "public"."character_skills"("character_id" ASC, "skill_id" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "characters_character_name_key" ON "public"."characters"("character_name" ASC);

-- CreateIndex
CREATE INDEX "characters_gold_idx" ON "public"."characters"("gold" ASC);

-- CreateIndex
CREATE INDEX "characters_level_gear_score_idx" ON "public"."characters"("level" ASC, "gear_score" ASC);

-- CreateIndex
CREATE INDEX "characters_level_idx" ON "public"."characters"("level" ASC);

-- CreateIndex
CREATE INDEX "characters_pvp_rating_idx" ON "public"."characters"("pvp_rating" ASC);

-- CreateIndex
CREATE INDEX "characters_pvp_rating_pvp_calibration_games_idx" ON "public"."characters"("pvp_rating" ASC, "pvp_calibration_games" ASC);

-- CreateIndex
CREATE INDEX "characters_user_id_idx" ON "public"."characters"("user_id" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "consumable_inventory_character_id_consumable_type_key" ON "public"."consumable_inventory"("character_id" ASC, "consumable_type" ASC);

-- CreateIndex
CREATE INDEX "cosmetics_user_id_idx" ON "public"."cosmetics"("user_id" ASC);

-- CreateIndex
CREATE INDEX "cosmetics_user_id_type_idx" ON "public"."cosmetics"("user_id" ASC, "type" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "daily_login_rewards_character_id_key" ON "public"."daily_login_rewards"("character_id" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "daily_quests_character_id_quest_type_day_key" ON "public"."daily_quests"("character_id" ASC, "quest_type" ASC, "day" ASC);

-- CreateIndex
CREATE INDEX "dungeon_progress_character_id_completed_idx" ON "public"."dungeon_progress"("character_id" ASC, "completed" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "dungeon_progress_character_id_dungeon_id_key" ON "public"."dungeon_progress"("character_id" ASC, "dungeon_id" ASC);

-- CreateIndex
CREATE INDEX "dungeon_runs_character_id_difficulty_idx" ON "public"."dungeon_runs"("character_id" ASC, "difficulty" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "dungeon_waves_dungeon_id_wave_number_key" ON "public"."dungeon_waves"("dungeon_id" ASC, "wave_number" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "dungeons_slug_key" ON "public"."dungeons"("slug" ASC);

-- CreateIndex
CREATE INDEX "equipment_inventory_character_id_idx" ON "public"."equipment_inventory"("character_id" ASC);

-- CreateIndex
CREATE INDEX "equipment_inventory_character_id_is_equipped_idx" ON "public"."equipment_inventory"("character_id" ASC, "is_equipped" ASC);

-- CreateIndex
CREATE INDEX "equipment_inventory_item_id_idx" ON "public"."equipment_inventory"("item_id" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "events_event_key_key" ON "public"."events"("event_key" ASC);

-- CreateIndex
CREATE INDEX "events_is_active_start_at_end_at_idx" ON "public"."events"("is_active" ASC, "start_at" ASC, "end_at" ASC);

-- CreateIndex
CREATE INDEX "gold_mine_sessions_character_id_collected_idx" ON "public"."gold_mine_sessions"("character_id" ASC, "collected" ASC);

-- CreateIndex
CREATE INDEX "gold_mine_sessions_character_id_ends_at_idx" ON "public"."gold_mine_sessions"("character_id" ASC, "ends_at" ASC);

-- CreateIndex
CREATE INDEX "gold_mine_sessions_character_id_idx" ON "public"."gold_mine_sessions"("character_id" ASC);

-- CreateIndex
CREATE INDEX "iap_transactions_status_created_at_idx" ON "public"."iap_transactions"("status" ASC, "created_at" DESC);

-- CreateIndex
CREATE INDEX "iap_transactions_transaction_id_idx" ON "public"."iap_transactions"("transaction_id" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "iap_transactions_transaction_id_key" ON "public"."iap_transactions"("transaction_id" ASC);

-- CreateIndex
CREATE INDEX "iap_transactions_user_id_created_at_idx" ON "public"."iap_transactions"("user_id" ASC, "created_at" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "item_balance_profiles_item_type_key" ON "public"."item_balance_profiles"("item_type" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "items_catalog_id_key" ON "public"."items"("catalog_id" ASC);

-- CreateIndex
CREATE INDEX "items_item_type_item_level_idx" ON "public"."items"("item_type" ASC, "item_level" ASC);

-- CreateIndex
CREATE INDEX "items_rarity_idx" ON "public"."items"("rarity" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "legendary_shards_character_id_key" ON "public"."legendary_shards"("character_id" ASC);

-- CreateIndex
CREATE INDEX "minigame_sessions_character_id_idx" ON "public"."minigame_sessions"("character_id" ASC);

-- CreateIndex
CREATE INDEX "minigame_sessions_character_id_status_idx" ON "public"."minigame_sessions"("character_id" ASC, "status" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "passive_connections_from_id_to_id_key" ON "public"."passive_connections"("from_id" ASC, "to_id" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "passive_nodes_node_key_key" ON "public"."passive_nodes"("node_key" ASC);

-- CreateIndex
CREATE INDEX "push_tokens_user_id_is_active_idx" ON "public"."push_tokens"("user_id" ASC, "is_active" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "push_tokens_user_id_platform_token_key" ON "public"."push_tokens"("user_id" ASC, "platform" ASC, "token" ASC);

-- CreateIndex
CREATE INDEX "pvp_matches_played_at_idx" ON "public"."pvp_matches"("played_at" DESC);

-- CreateIndex
CREATE INDEX "pvp_matches_player1_id_idx" ON "public"."pvp_matches"("player1_id" ASC);

-- CreateIndex
CREATE INDEX "pvp_matches_player1_id_played_at_idx" ON "public"."pvp_matches"("player1_id" ASC, "played_at" DESC);

-- CreateIndex
CREATE INDEX "pvp_matches_player2_id_idx" ON "public"."pvp_matches"("player2_id" ASC);

-- CreateIndex
CREATE INDEX "pvp_matches_player2_id_played_at_idx" ON "public"."pvp_matches"("player2_id" ASC, "played_at" DESC);

-- CreateIndex
CREATE INDEX "pvp_matches_winner_id_idx" ON "public"."pvp_matches"("winner_id" ASC);

-- CreateIndex
CREATE INDEX "revenge_queue_attacker_id_idx" ON "public"."revenge_queue"("attacker_id" ASC);

-- CreateIndex
CREATE INDEX "revenge_queue_expires_at_idx" ON "public"."revenge_queue"("expires_at" ASC);

-- CreateIndex
CREATE INDEX "revenge_queue_victim_id_is_used_expires_at_idx" ON "public"."revenge_queue"("victim_id" ASC, "is_used" ASC, "expires_at" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "seasons_number_key" ON "public"."seasons"("number" ASC);

-- CreateIndex
CREATE INDEX "seasons_start_at_end_at_idx" ON "public"."seasons"("start_at" ASC, "end_at" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "skills_skill_key_key" ON "public"."skills"("skill_key" ASC);

-- CreateIndex
CREATE INDEX "training_sessions_character_id_idx" ON "public"."training_sessions"("character_id" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "public"."users"("email" ASC);

-- AddForeignKey
ALTER TABLE "public"."achievements" ADD CONSTRAINT "achievements_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."battle_pass" ADD CONSTRAINT "battle_pass_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."battle_pass" ADD CONSTRAINT "battle_pass_season_id_fkey" FOREIGN KEY ("season_id") REFERENCES "public"."seasons"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."battle_pass_claims" ADD CONSTRAINT "battle_pass_claims_battle_pass_id_fkey" FOREIGN KEY ("battle_pass_id") REFERENCES "public"."battle_pass"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."battle_pass_claims" ADD CONSTRAINT "battle_pass_claims_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."battle_pass_claims" ADD CONSTRAINT "battle_pass_claims_reward_id_fkey" FOREIGN KEY ("reward_id") REFERENCES "public"."battle_pass_rewards"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."battle_pass_rewards" ADD CONSTRAINT "battle_pass_rewards_season_id_fkey" FOREIGN KEY ("season_id") REFERENCES "public"."seasons"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."boss_abilities" ADD CONSTRAINT "boss_abilities_boss_id_fkey" FOREIGN KEY ("boss_id") REFERENCES "public"."dungeon_bosses"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."character_passives" ADD CONSTRAINT "character_passives_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."character_passives" ADD CONSTRAINT "character_passives_node_id_fkey" FOREIGN KEY ("node_id") REFERENCES "public"."passive_nodes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."character_skills" ADD CONSTRAINT "character_skills_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."character_skills" ADD CONSTRAINT "character_skills_skill_id_fkey" FOREIGN KEY ("skill_id") REFERENCES "public"."skills"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."characters" ADD CONSTRAINT "characters_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."consumable_inventory" ADD CONSTRAINT "consumable_inventory_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."cosmetics" ADD CONSTRAINT "cosmetics_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."daily_login_rewards" ADD CONSTRAINT "daily_login_rewards_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."daily_quests" ADD CONSTRAINT "daily_quests_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."dungeon_bosses" ADD CONSTRAINT "dungeon_bosses_dungeon_id_fkey" FOREIGN KEY ("dungeon_id") REFERENCES "public"."dungeons"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."dungeon_drops" ADD CONSTRAINT "dungeon_drops_dungeon_id_fkey" FOREIGN KEY ("dungeon_id") REFERENCES "public"."dungeons"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."dungeon_drops" ADD CONSTRAINT "dungeon_drops_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "public"."items"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."dungeon_progress" ADD CONSTRAINT "dungeon_progress_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."dungeon_runs" ADD CONSTRAINT "dungeon_runs_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."dungeon_wave_enemies" ADD CONSTRAINT "dungeon_wave_enemies_wave_id_fkey" FOREIGN KEY ("wave_id") REFERENCES "public"."dungeon_waves"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."dungeon_waves" ADD CONSTRAINT "dungeon_waves_dungeon_id_fkey" FOREIGN KEY ("dungeon_id") REFERENCES "public"."dungeons"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."equipment_inventory" ADD CONSTRAINT "equipment_inventory_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."equipment_inventory" ADD CONSTRAINT "equipment_inventory_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "public"."items"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."gold_mine_sessions" ADD CONSTRAINT "gold_mine_sessions_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."iap_transactions" ADD CONSTRAINT "iap_transactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."legendary_shards" ADD CONSTRAINT "legendary_shards_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."minigame_sessions" ADD CONSTRAINT "minigame_sessions_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."passive_connections" ADD CONSTRAINT "passive_connections_from_id_fkey" FOREIGN KEY ("from_id") REFERENCES "public"."passive_nodes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."passive_connections" ADD CONSTRAINT "passive_connections_to_id_fkey" FOREIGN KEY ("to_id") REFERENCES "public"."passive_nodes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."push_tokens" ADD CONSTRAINT "push_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."pvp_matches" ADD CONSTRAINT "pvp_matches_loser_id_fkey" FOREIGN KEY ("loser_id") REFERENCES "public"."characters"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."pvp_matches" ADD CONSTRAINT "pvp_matches_player1_id_fkey" FOREIGN KEY ("player1_id") REFERENCES "public"."characters"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."pvp_matches" ADD CONSTRAINT "pvp_matches_player2_id_fkey" FOREIGN KEY ("player2_id") REFERENCES "public"."characters"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."pvp_matches" ADD CONSTRAINT "pvp_matches_winner_id_fkey" FOREIGN KEY ("winner_id") REFERENCES "public"."characters"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."revenge_queue" ADD CONSTRAINT "revenge_queue_attacker_id_fkey" FOREIGN KEY ("attacker_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."revenge_queue" ADD CONSTRAINT "revenge_queue_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."pvp_matches"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."revenge_queue" ADD CONSTRAINT "revenge_queue_victim_id_fkey" FOREIGN KEY ("victim_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."training_sessions" ADD CONSTRAINT "training_sessions_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

