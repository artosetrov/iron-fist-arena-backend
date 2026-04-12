-- CreateTable
CREATE TABLE "stash_items" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "item_id" TEXT NOT NULL,
    "upgrade_level" INTEGER NOT NULL DEFAULT 0,
    "durability" INTEGER NOT NULL DEFAULT 100,
    "max_durability" INTEGER NOT NULL DEFAULT 100,
    "rolled_stats" JSONB,
    "stored_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "stash_items_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "stash_items_user_id_idx" ON "stash_items"("user_id");

-- CreateIndex
CREATE INDEX "stash_items_item_id_idx" ON "stash_items"("item_id");

-- AddForeignKey
ALTER TABLE "stash_items" ADD CONSTRAINT "stash_items_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stash_items" ADD CONSTRAINT "stash_items_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "items"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
