-- CreateTable
CREATE TABLE "referral_reward_claims" (
    "id" TEXT NOT NULL,
    "referrer_character_id" TEXT NOT NULL,
    "invitee_character_id" TEXT NOT NULL,
    "qualified_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "referral_reward_claims_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "referral_reward_claims_referrer_character_id_invitee_character__key" ON "referral_reward_claims"("referrer_character_id", "invitee_character_id");

-- CreateIndex
CREATE INDEX "referral_reward_claims_referrer_character_id_idx" ON "referral_reward_claims"("referrer_character_id");

-- CreateIndex
CREATE INDEX "referral_reward_claims_invitee_character_id_idx" ON "referral_reward_claims"("invitee_character_id");

-- AddForeignKey
ALTER TABLE "referral_reward_claims" ADD CONSTRAINT "referral_reward_claims_referrer_character_id_fkey" FOREIGN KEY ("referrer_character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "referral_reward_claims" ADD CONSTRAINT "referral_reward_claims_invitee_character_id_fkey" FOREIGN KEY ("invitee_character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;
