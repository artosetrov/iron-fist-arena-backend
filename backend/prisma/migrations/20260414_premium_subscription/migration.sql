-- Premium Pass Phase 2: auto-renewable subscription tracking
-- See docs/06_game_systems/PREMIUM_PASS_MIGRATION.md
-- Applied to prod via Supabase MCP on 2026-04-14. This file exists for
-- prisma/drift-checker parity.

CREATE TABLE IF NOT EXISTS "premium_subscriptions" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "product_id" TEXT NOT NULL,
    "original_transaction_id" TEXT NOT NULL,
    "latest_transaction_id" TEXT NOT NULL,
    "started_at" TIMESTAMP(3) NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "auto_renew" BOOLEAN NOT NULL DEFAULT true,
    "status" TEXT NOT NULL DEFAULT 'active',
    "latest_receipt" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "premium_subscriptions_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "premium_subscriptions_user_id_key" ON "premium_subscriptions"("user_id");
CREATE INDEX IF NOT EXISTS "premium_subscriptions_original_transaction_id_idx" ON "premium_subscriptions"("original_transaction_id");
CREATE INDEX IF NOT EXISTS "premium_subscriptions_expires_at_idx" ON "premium_subscriptions"("expires_at");

ALTER TABLE "premium_subscriptions"
  ADD CONSTRAINT "premium_subscriptions_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
