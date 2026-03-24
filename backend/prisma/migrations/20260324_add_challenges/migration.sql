-- CreateEnum
CREATE TYPE "ChallengeStatus" AS ENUM ('pending', 'accepted', 'declined', 'expired', 'completed');

-- CreateTable
CREATE TABLE "challenges" (
    "id" TEXT NOT NULL,
    "challenger_id" TEXT NOT NULL,
    "defender_id" TEXT NOT NULL,
    "status" "ChallengeStatus" NOT NULL DEFAULT 'pending',
    "match_id" TEXT,
    "message" VARCHAR(100),
    "gold_wager" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "responded_at" TIMESTAMP(3),
    "completed_at" TIMESTAMP(3),

    CONSTRAINT "challenges_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "challenges_match_id_key" ON "challenges"("match_id");
CREATE INDEX "challenges_defender_id_status_idx" ON "challenges"("defender_id", "status");
CREATE INDEX "challenges_challenger_id_status_idx" ON "challenges"("challenger_id", "status");
CREATE INDEX "challenges_expires_at_idx" ON "challenges"("expires_at");

-- AddForeignKey
ALTER TABLE "challenges" ADD CONSTRAINT "challenges_challenger_id_fkey" FOREIGN KEY ("challenger_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "challenges" ADD CONSTRAINT "challenges_defender_id_fkey" FOREIGN KEY ("defender_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "challenges" ADD CONSTRAINT "challenges_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "pvp_matches"("id") ON DELETE SET NULL ON UPDATE CASCADE;
