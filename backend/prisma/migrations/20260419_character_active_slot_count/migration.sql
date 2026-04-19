-- Backfill the `active_slot_count` column on characters. The column is
-- already referenced by passives/active-slots/* route handlers (base 3,
-- max from PASSIVES.MAX_ACTIVE_SLOTS), and the prod DB has the column
-- applied via an earlier ad-hoc migration. This file exists to keep the
-- Prisma migration history aligned with schema.prisma so the drift-check
-- guard stops flagging it as missing.
--
-- IF NOT EXISTS keeps re-runs idempotent on any environment that already
-- has the column applied.

ALTER TABLE "characters"
  ADD COLUMN IF NOT EXISTS "active_slot_count" INTEGER NOT NULL DEFAULT 3;
