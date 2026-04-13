-- Repair drift between prisma/schema.prisma and committed migrations.
-- Keep this migration idempotent because some production objects may have been
-- added manually after earlier drift incidents.

-- Missing timestamp columns on existing inventory/progress tables.
ALTER TABLE "public"."consumable_inventory"
  ADD COLUMN IF NOT EXISTS "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE "public"."dungeon_progress"
  ADD COLUMN IF NOT EXISTS "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE "public"."equipment_inventory"
  ADD COLUMN IF NOT EXISTS "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Admin/content tables present in Prisma schema but missing from migrations.
CREATE TABLE IF NOT EXISTS "public"."push_campaigns" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "data" JSONB,
    "target_type" TEXT NOT NULL DEFAULT 'broadcast',
    "target_filter" JSONB,
    "status" TEXT NOT NULL DEFAULT 'draft',
    "sent_count" INTEGER NOT NULL DEFAULT 0,
    "fail_count" INTEGER NOT NULL DEFAULT 0,
    "scheduled_at" TIMESTAMP(3),
    "sent_at" TIMESTAMP(3),
    "created_by" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "push_campaigns_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "public"."push_logs" (
    "id" TEXT NOT NULL,
    "campaign_id" TEXT,
    "user_id" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'sent',
    "error" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "push_logs_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "public"."config_snapshots" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "configs" JSONB NOT NULL,
    "created_by" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "config_snapshots_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "public"."achievement_definitions" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "target" INTEGER NOT NULL,
    "reward_type" TEXT NOT NULL,
    "reward_amount" INTEGER NOT NULL,
    "reward_id" TEXT,
    "icon" TEXT,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "achievement_definitions_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "public"."quest_definitions" (
    "id" TEXT NOT NULL,
    "quest_type" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "icon" TEXT NOT NULL DEFAULT '',
    "min_target" INTEGER NOT NULL,
    "max_target" INTEGER NOT NULL,
    "reward_gold" INTEGER NOT NULL DEFAULT 0,
    "reward_xp" INTEGER NOT NULL DEFAULT 0,
    "reward_gems" INTEGER NOT NULL DEFAULT 0,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "quest_definitions_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "public"."feature_flags" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "flag_type" TEXT NOT NULL DEFAULT 'boolean',
    "value" JSONB NOT NULL DEFAULT 'true',
    "targeting" JSONB,
    "is_active" BOOLEAN NOT NULL DEFAULT false,
    "environment" TEXT NOT NULL DEFAULT 'all',
    "tags" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    "created_by" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "feature_flags_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "public"."mail_messages" (
    "id" TEXT NOT NULL,
    "subject" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "sender_type" TEXT NOT NULL DEFAULT 'system',
    "sender_name" TEXT NOT NULL DEFAULT 'System',
    "attachments" JSONB,
    "target_type" TEXT NOT NULL DEFAULT 'broadcast',
    "target_filter" JSONB,
    "expires_at" TIMESTAMP(3),
    "created_by" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mail_messages_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "public"."mail_recipients" (
    "id" TEXT NOT NULL,
    "message_id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "is_read" BOOLEAN NOT NULL DEFAULT false,
    "is_claimed" BOOLEAN NOT NULL DEFAULT false,
    "is_deleted" BOOLEAN NOT NULL DEFAULT false,
    "read_at" TIMESTAMP(3),
    "claimed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mail_recipients_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "public"."shop_offers" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "offer_type" TEXT NOT NULL DEFAULT 'bundle',
    "contents" JSONB NOT NULL,
    "original_price" INTEGER NOT NULL,
    "sale_price" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'gold',
    "discount_pct" INTEGER NOT NULL DEFAULT 0,
    "max_purchases" INTEGER NOT NULL DEFAULT 1,
    "min_level" INTEGER NOT NULL DEFAULT 1,
    "max_level" INTEGER NOT NULL DEFAULT 999,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "image_key" TEXT,
    "tags" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    "is_active" BOOLEAN NOT NULL DEFAULT false,
    "starts_at" TIMESTAMP(3),
    "ends_at" TIMESTAMP(3),
    "created_by" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "shop_offers_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "public"."shop_offer_purchases" (
    "id" TEXT NOT NULL,
    "offer_id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "price" INTEGER NOT NULL,
    "currency" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "shop_offer_purchases_pkey" PRIMARY KEY ("id")
);

-- Unique constraints/indexes for the new tables.
CREATE UNIQUE INDEX IF NOT EXISTS "achievement_definitions_key_key" ON "public"."achievement_definitions"("key" ASC);
CREATE UNIQUE INDEX IF NOT EXISTS "quest_definitions_quest_type_key" ON "public"."quest_definitions"("quest_type" ASC);
CREATE UNIQUE INDEX IF NOT EXISTS "feature_flags_key_key" ON "public"."feature_flags"("key" ASC);
CREATE UNIQUE INDEX IF NOT EXISTS "mail_recipients_message_id_character_id_key" ON "public"."mail_recipients"("message_id" ASC, "character_id" ASC);
CREATE UNIQUE INDEX IF NOT EXISTS "shop_offers_key_key" ON "public"."shop_offers"("key" ASC);

-- Missing and newly-required secondary indexes.
CREATE INDEX IF NOT EXISTS "admin_logs_admin_id_idx" ON "public"."admin_logs"("admin_id" ASC);
CREATE INDEX IF NOT EXISTS "admin_logs_action_idx" ON "public"."admin_logs"("action" ASC);
CREATE INDEX IF NOT EXISTS "daily_quests_character_id_day_idx" ON "public"."daily_quests"("character_id" ASC, "day" ASC);
CREATE INDEX IF NOT EXISTS "dungeon_progress_character_id_idx" ON "public"."dungeon_progress"("character_id" ASC);
CREATE INDEX IF NOT EXISTS "dungeon_runs_character_id_created_at_idx" ON "public"."dungeon_runs"("character_id" ASC, "created_at" DESC);
CREATE INDEX IF NOT EXISTS "items_item_type_idx" ON "public"."items"("item_type" ASC);
CREATE INDEX IF NOT EXISTS "users_gold_idx" ON "public"."users"("gold" ASC);

CREATE INDEX IF NOT EXISTS "push_campaigns_status_idx" ON "public"."push_campaigns"("status" ASC);
CREATE INDEX IF NOT EXISTS "push_logs_campaign_id_idx" ON "public"."push_logs"("campaign_id" ASC);
CREATE INDEX IF NOT EXISTS "push_logs_user_id_created_at_idx" ON "public"."push_logs"("user_id" ASC, "created_at" DESC);
CREATE INDEX IF NOT EXISTS "feature_flags_is_active_idx" ON "public"."feature_flags"("is_active" ASC);
CREATE INDEX IF NOT EXISTS "feature_flags_key_is_active_idx" ON "public"."feature_flags"("key" ASC, "is_active" ASC);
CREATE INDEX IF NOT EXISTS "mail_messages_target_type_idx" ON "public"."mail_messages"("target_type" ASC);
CREATE INDEX IF NOT EXISTS "mail_messages_created_at_idx" ON "public"."mail_messages"("created_at" DESC);
CREATE INDEX IF NOT EXISTS "mail_recipients_character_id_is_deleted_created_at_idx" ON "public"."mail_recipients"("character_id" ASC, "is_deleted" ASC, "created_at" DESC);
CREATE INDEX IF NOT EXISTS "mail_recipients_character_id_is_read_idx" ON "public"."mail_recipients"("character_id" ASC, "is_read" ASC);
CREATE INDEX IF NOT EXISTS "shop_offers_is_active_starts_at_ends_at_idx" ON "public"."shop_offers"("is_active" ASC, "starts_at" ASC, "ends_at" ASC);
CREATE INDEX IF NOT EXISTS "shop_offer_purchases_offer_id_character_id_idx" ON "public"."shop_offer_purchases"("offer_id" ASC, "character_id" ASC);

-- Foreign keys for relational tables; guarded because ADD CONSTRAINT has no IF NOT EXISTS.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'mail_recipients_message_id_fkey') THEN
    ALTER TABLE "public"."mail_recipients"
      ADD CONSTRAINT "mail_recipients_message_id_fkey"
      FOREIGN KEY ("message_id") REFERENCES "public"."mail_messages"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'mail_recipients_character_id_fkey') THEN
    ALTER TABLE "public"."mail_recipients"
      ADD CONSTRAINT "mail_recipients_character_id_fkey"
      FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'shop_offer_purchases_offer_id_fkey') THEN
    ALTER TABLE "public"."shop_offer_purchases"
      ADD CONSTRAINT "shop_offer_purchases_offer_id_fkey"
      FOREIGN KEY ("offer_id") REFERENCES "public"."shop_offers"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'shop_offer_purchases_character_id_fkey') THEN
    ALTER TABLE "public"."shop_offer_purchases"
      ADD CONSTRAINT "shop_offer_purchases_character_id_fkey"
      FOREIGN KEY ("character_id") REFERENCES "public"."characters"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;
