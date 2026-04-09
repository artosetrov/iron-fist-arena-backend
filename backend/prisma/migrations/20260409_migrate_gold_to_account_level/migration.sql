-- AlterTable: Add gold column to users table (account-level currency)
ALTER TABLE "users" ADD COLUMN "gold" INTEGER NOT NULL DEFAULT 0;

-- DataMigration: Sum all character gold into user account balance
UPDATE "users" SET "gold" = COALESCE(
  (SELECT SUM("gold") FROM "characters" WHERE "characters"."user_id" = "users"."id"),
  0
);

-- AlterTable: Remove gold column from characters table
ALTER TABLE "characters" DROP COLUMN "gold";
