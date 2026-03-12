CREATE TABLE "pvp_battle_tickets" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "opponent_id" TEXT NOT NULL,
    "revenge_id" TEXT,
    "battle_seed" INTEGER NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "consumed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "pvp_battle_tickets_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "pvp_battle_tickets_character_id_battle_seed_key"
ON "pvp_battle_tickets"("character_id", "battle_seed");

CREATE INDEX "pvp_battle_tickets_character_id_consumed_at_expires_at_idx"
ON "pvp_battle_tickets"("character_id", "consumed_at", "expires_at");

CREATE INDEX "pvp_battle_tickets_opponent_id_idx"
ON "pvp_battle_tickets"("opponent_id");

ALTER TABLE "pvp_battle_tickets"
ADD CONSTRAINT "pvp_battle_tickets_character_id_fkey"
FOREIGN KEY ("character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "pvp_battle_tickets"
ADD CONSTRAINT "pvp_battle_tickets_opponent_id_fkey"
FOREIGN KEY ("opponent_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "pvp_battle_tickets"
ADD CONSTRAINT "pvp_battle_tickets_revenge_id_fkey"
FOREIGN KEY ("revenge_id") REFERENCES "revenge_queue"("id") ON DELETE SET NULL ON UPDATE CASCADE;
