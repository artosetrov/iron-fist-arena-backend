-- Add gear_score column to characters table for matchmaking
ALTER TABLE "characters" ADD COLUMN "gear_score" INTEGER NOT NULL DEFAULT 0;

-- Index for level + gear_score matchmaking queries
CREATE INDEX "characters_level_gear_score_idx" ON "characters"("level", "gear_score");
