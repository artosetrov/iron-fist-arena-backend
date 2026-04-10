-- Bug: PLAY AS GUEST returned 500 "Internal server error".
--
-- Root cause: commit 6a5778d (Bug #19: persistent device ID for guest
-- restore) added `deviceId` to the Prisma User model and shipped the
-- guest-login restore path, but no migration was created. The actual
-- Postgres `users` table had no `device_id` column, so every call to
-- `prisma.user.findUnique({ where: { deviceId } })` and
-- `prisma.user.create({ data: { deviceId } })` in guest-login/route.ts
-- threw a PrismaClientKnownRequestError, which bubbled out of the outer
-- try/catch as "Internal server error".
--
-- Fix: add the missing column + unique constraint + lookup index so the
-- schema matches Prisma.

-- AlterTable
ALTER TABLE "users" ADD COLUMN "device_id" TEXT;

-- CreateIndex: unique device_id (guest restore by stable per-device token)
CREATE UNIQUE INDEX "users_device_id_key" ON "users"("device_id");

-- CreateIndex: explicit @@index([deviceId]) from schema.prisma
CREATE INDEX "users_device_id_idx" ON "users"("device_id");
