-- 2026-10-13: UGC reports for App Store Guideline 1.2 (AUDIT-2026-10-13 Sprint 4).
CREATE TABLE IF NOT EXISTS "user_reports" (
  "id"                    TEXT PRIMARY KEY,
  "reporter_user_id"      TEXT NOT NULL,
  "reporter_character_id" TEXT,
  "target_user_id"        TEXT NOT NULL,
  "target_character_id"   TEXT,
  "category"              TEXT NOT NULL,
  "reason"                VARCHAR(500),
  "context_type"          TEXT NOT NULL DEFAULT 'profile',
  "context_id"            TEXT,
  "snapshot"              VARCHAR(500),
  "status"                TEXT NOT NULL DEFAULT 'open',
  "resolution"            VARCHAR(500),
  "resolved_by"           TEXT,
  "resolved_at"           TIMESTAMP(3),
  "created_at"            TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS "user_reports_status_created_at_idx" ON "user_reports" ("status", "created_at");
CREATE INDEX IF NOT EXISTS "user_reports_target_user_id_idx" ON "user_reports" ("target_user_id");
CREATE INDEX IF NOT EXISTS "user_reports_reporter_user_id_created_at_idx" ON "user_reports" ("reporter_user_id", "created_at");
