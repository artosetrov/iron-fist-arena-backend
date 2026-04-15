-- Bring migration history in sync with schema.prisma/EventType and runtime
-- event handling. These values are additive and safe to apply repeatedly.
ALTER TYPE "EventType" ADD VALUE IF NOT EXISTS 'double_xp';
ALTER TYPE "EventType" ADD VALUE IF NOT EXISTS 'drop_rate_boost';
ALTER TYPE "EventType" ADD VALUE IF NOT EXISTS 'weekend_warrior';
