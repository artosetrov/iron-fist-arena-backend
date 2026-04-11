-- W3.D4 — Daily activity caps for retention/anti-farm
--
-- Adds two per-character counters with lazy-reset dates:
--   * dungeon_clears_today / dungeon_clears_date
--     Training / dungeon XP diminishing returns. Prevents unlimited XP farming
--     from grinding the same floor. See TRAINING_XP_DR in balance.ts.
--   * stamina_refills_today / stamina_refills_date
--     Stamina gem-refill diminishing returns + hard daily cap. Prevents a single
--     user from buying 20 refills/day at a flat price. See STAMINA_REFILL_DR in
--     balance.ts.
--
-- Both counters use lazy reset: application code checks the *_date column
-- against today's UTC date on read/write, and resets the counter to 0 when the
-- date changes. No scheduled job required.
--
-- All columns are NULL-able / default-0 so existing rows continue to work.

-- AlterTable
ALTER TABLE "characters"
  ADD COLUMN "dungeon_clears_today" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN "dungeon_clears_date" TIMESTAMP(3),
  ADD COLUMN "stamina_refills_today" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN "stamina_refills_date" TIMESTAMP(3);
