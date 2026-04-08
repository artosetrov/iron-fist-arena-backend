-- AlterTable: Add tutorial fields to characters
ALTER TABLE "characters" ADD COLUMN "tutorial_step" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "characters" ADD COLUMN "tutorial_skipped" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "characters" ADD COLUMN "referral_code" TEXT;
ALTER TABLE "characters" ADD COLUMN "referred_by" TEXT;

-- CreateIndex: unique referral code
CREATE UNIQUE INDEX "characters_referral_code_key" ON "characters"("referral_code");

-- CreateTable: tutorial_quests
CREATE TABLE "tutorial_quests" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "quest_id" TEXT NOT NULL,
    "progress" INTEGER NOT NULL DEFAULT 0,
    "target" INTEGER NOT NULL,
    "is_completed" BOOLEAN NOT NULL DEFAULT false,
    "completed_at" TIMESTAMP(3),
    "reward_claimed" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tutorial_quests_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "tutorial_quests_character_id_quest_id_key" ON "tutorial_quests"("character_id", "quest_id");
CREATE INDEX "tutorial_quests_character_id_idx" ON "tutorial_quests"("character_id");

-- AddForeignKey
ALTER TABLE "tutorial_quests" ADD CONSTRAINT "tutorial_quests_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Backfill: set existing characters as tutorial completed
UPDATE "characters" SET "tutorial_step" = 3 WHERE "tutorial_step" = 0;
