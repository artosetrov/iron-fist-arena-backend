-- CreateTable
CREATE TABLE "contraband_claims" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "contents" JSONB NOT NULL,
    "price" INTEGER NOT NULL DEFAULT 0,
    "currency" TEXT NOT NULL DEFAULT 'gold',
    "claim_number" INTEGER NOT NULL,
    "claimed_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "contraband_claims_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "contraband_claims_character_id_claimed_at_idx" ON "contraband_claims"("character_id", "claimed_at");

-- AddForeignKey
ALTER TABLE "contraband_claims" ADD CONSTRAINT "contraband_claims_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;
