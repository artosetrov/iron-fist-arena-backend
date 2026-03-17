-- CreateTable
CREATE TABLE "daily_gem_cards" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "purchased_at" TIMESTAMP(3) NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "last_claimed_at" TIMESTAMP(3) NOT NULL,
    "days_remaining" INTEGER NOT NULL DEFAULT 30,

    CONSTRAINT "daily_gem_cards_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "daily_gem_cards_user_id_key" ON "daily_gem_cards"("user_id");

-- AddForeignKey
ALTER TABLE "daily_gem_cards" ADD CONSTRAINT "daily_gem_cards_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
