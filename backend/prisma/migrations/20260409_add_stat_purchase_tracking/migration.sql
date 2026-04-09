-- Add stat purchase tracking columns
ALTER TABLE "characters" ADD COLUMN "stat_purchases_today" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "characters" ADD COLUMN "stat_purchases_date" TIMESTAMP(3);
ALTER TABLE "characters" ADD COLUMN "stat_purchases_total" INTEGER NOT NULL DEFAULT 0;
