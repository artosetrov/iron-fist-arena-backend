-- 2026-10-13: persist product-analytics events (AUDIT-2026-10-13 C6).
CREATE TABLE IF NOT EXISTS "analytics_events" (
  "id"           TEXT PRIMARY KEY,
  "name"         TEXT NOT NULL,
  "user_id"      TEXT,
  "character_id" TEXT,
  "source"       TEXT NOT NULL DEFAULT 'server',
  "props"        JSONB,
  "created_at"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS "analytics_events_name_created_at_idx" ON "analytics_events" ("name", "created_at");
CREATE INDEX IF NOT EXISTS "analytics_events_user_id_created_at_idx" ON "analytics_events" ("user_id", "created_at");
CREATE INDEX IF NOT EXISTS "analytics_events_created_at_idx" ON "analytics_events" ("created_at");
