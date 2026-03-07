import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

/**
 * Read a live game config value from the database.
 * Falls back to the provided default if the key doesn't exist.
 *
 * Usage:
 *   const maxStamina = await getGameConfig('stamina.max', 120)
 *   const dropChance = await getGameConfig('drop_chances.pvp', 0.15)
 */
export async function getGameConfig<T>(key: string, fallback: T): Promise<T> {
  try {
    const row = await prisma.gameConfig.findUnique({ where: { key } })
    if (!row) return fallback
    return row.value as T
  } catch {
    return fallback
  }
}

/**
 * Read multiple config values at once (batch read).
 * Returns a map of key → value, using defaults for missing keys.
 */
export async function getGameConfigs(
  keys: Record<string, unknown>
): Promise<Record<string, unknown>> {
  try {
    const rows = await prisma.gameConfig.findMany({
      where: { key: { in: Object.keys(keys) } },
    })
    const result: Record<string, unknown> = { ...keys }
    for (const row of rows) {
      result[row.key] = row.value
    }
    return result
  } catch {
    return keys
  }
}
