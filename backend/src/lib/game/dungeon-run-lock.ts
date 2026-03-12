import type { Prisma } from '@prisma/client'

interface DungeonRunLockTx {
  $queryRawUnsafe<T = unknown>(query: string, ...values: unknown[]): Promise<T>
}

export interface LockedDungeonRun {
  id: string
  characterId: string
  dungeonId: string
  difficulty: string
  currentFloor: number
  state: Prisma.JsonValue | null
}

export async function lockDungeonRunForUpdate(
  tx: DungeonRunLockTx,
  runId: string,
): Promise<LockedDungeonRun | null> {
  const [run] = await tx.$queryRawUnsafe<LockedDungeonRun[]>(
    `SELECT id,
            character_id AS "characterId",
            dungeon_id AS "dungeonId",
            difficulty::text AS "difficulty",
            current_floor AS "currentFloor",
            state
       FROM dungeon_runs
      WHERE id = $1
      FOR UPDATE`,
    runId,
  )

  return run ?? null
}
