-- CreateEnum
CREATE TYPE "CharacterGender" AS ENUM ('male', 'female');

-- AlterTable
ALTER TABLE "characters" ADD COLUMN "gender" "CharacterGender" NOT NULL DEFAULT 'male';
ALTER TABLE "characters" ADD COLUMN "avatar" TEXT NOT NULL DEFAULT 'warlord';
