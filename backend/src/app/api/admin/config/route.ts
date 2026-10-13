import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'
import { invalidateGameConfigCache } from '@/lib/game/config'
import { asTierFloor } from '@/lib/game/tier'
import {
  describeLadderRowsProblem,
  isPvpRankKey,
  tierKeyFromConfigKey,
  PVP_RANK_KEY_PREFIX,
} from '@/lib/game/ladder-config'

type ConfigUpdateInput = {
  key: string
  value: unknown
  category?: string | null
  description?: string | null
}

function isConfigUpdateInput(value: unknown): value is ConfigUpdateInput {
  if (!value || typeof value !== 'object') return false

  const maybe = value as Partial<ConfigUpdateInput>
  return typeof maybe.key === 'string' && maybe.key.length > 0 && 'value' in maybe
}

function buildConfigUpsertData(update: ConfigUpdateInput) {
  const category = update.category ?? 'general'
  const description = update.description ?? null

  return {
    where: { key: update.key },
    update: {
      value: update.value as never,
      ...(update.category !== undefined ? { category } : {}),
      ...(update.description !== undefined ? { description } : {}),
    },
    create: {
      key: update.key,
      value: update.value as never,
      category,
      description,
    },
  }
}

/**
 * Refuse a `pvp_ranks.*` save that would not form a ladder — see
 * `lib/game/ladder-config.ts` for why this has to fail loudly.
 *
 * Validation is against the MERGED ladder — stored floors plus this request's
 * edits — because the panel edits one field at a time and only the whole set is
 * valid or not. Edits are also normalized to numbers in place: the config value
 * is a JSON column, and a floor stored as the string "1400" reads back as 1400
 * here but is skipped by the ladder, which is the silent divergence this guard
 * exists to prevent.
 *
 * Returns a human-readable reason, or null when the save is fine.
 */
async function describeLadderSaveProblem(updates: ConfigUpdateInput[]): Promise<string | null> {
  const touched = updates.filter((update) => isPvpRankKey(update.key))
  if (touched.length === 0) return null

  for (const update of touched) {
    if (!tierKeyFromConfigKey(update.key)) {
      return `${update.key} is not a tier on the ladder`
    }
    const floor = asTierFloor(update.value)
    if (floor === null) {
      return `${update.key} must be a number`
    }
    update.value = floor
  }

  const stored = await prisma.gameConfig.findMany({
    where: { key: { startsWith: PVP_RANK_KEY_PREFIX } },
    select: { key: true, value: true },
  })

  const editedKeys = new Set(touched.map((update) => update.key))
  return describeLadderRowsProblem([
    ...stored.filter((row) => !editedKeys.has(row.key)),
    ...touched,
  ])
}

/**
 * Deleting one floor reverts that tier to its frozen value while the others
 * keep their overrides, which can leave the remaining ladder out of order —
 * e.g. stored Silver 3000, delete Gold, and Gold snaps back to 1500, below
 * Silver. Same reason the save path is guarded.
 */
async function describeLadderDeleteProblem(key: string): Promise<string | null> {
  if (!isPvpRankKey(key)) return null

  const stored = await prisma.gameConfig.findMany({
    where: { key: { startsWith: PVP_RANK_KEY_PREFIX } },
    select: { key: true, value: true },
  })

  return describeLadderRowsProblem(stored.filter((row) => row.key !== key))
}

export async function GET(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  const prefix = req.nextUrl.searchParams.get('prefix')
  const key = req.nextUrl.searchParams.get('key')

  const where = key
    ? { key }
    : prefix
      ? { key: { startsWith: prefix } }
      : undefined

  try {
    const configs = await prisma.gameConfig.findMany({
      ...(where ? { where } : {}),
      orderBy: [{ category: 'asc' }, { key: 'asc' }],
    })

    return NextResponse.json({ configs })
  } catch (error) {
    console.error('admin get config error:', error)
    return NextResponse.json({ error: 'Failed to fetch config' }, { status: 500 })
  }
}

export async function PUT(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  try {
    const body = await req.json()
    if (!isConfigUpdateInput(body)) {
      return NextResponse.json({ error: 'key and value are required' }, { status: 400 })
    }

    const ladderProblem = await describeLadderSaveProblem([body])
    if (ladderProblem) {
      return NextResponse.json({ error: `Invalid PvP ladder: ${ladderProblem}` }, { status: 400 })
    }

    const config = await prisma.gameConfig.upsert(buildConfigUpsertData(body))

    await invalidateGameConfigCache([body.key])

    await prisma.adminLog.create({
      data: {
        adminId: admin.id,
        action: 'update_config',
        target: body.key,
        details: {
          value: body.value,
          ...(body.category !== undefined ? { category: body.category } : {}),
          ...(body.description !== undefined ? { description: body.description } : {}),
        } as never,
      },
    })

    return NextResponse.json({ config })
  } catch (error) {
    console.error('admin update config error:', error)
    return NextResponse.json({ error: 'Failed to update config' }, { status: 500 })
  }
}

export async function POST(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  try {
    const body = await req.json()
    const updates = Array.isArray(body?.updates) ? body.updates : null
    const skipExisting = body?.skipExisting === true

    if (!updates || updates.length === 0 || !updates.every(isConfigUpdateInput)) {
      return NextResponse.json({ error: 'updates[] with key and value is required' }, { status: 400 })
    }

    const parsedUpdates = updates as ConfigUpdateInput[]

    const ladderProblem = await describeLadderSaveProblem(parsedUpdates)
    if (ladderProblem) {
      return NextResponse.json({ error: `Invalid PvP ladder: ${ladderProblem}` }, { status: 400 })
    }

    const keys = [...new Set(parsedUpdates.map((update) => update.key))]

    const result = await prisma.$transaction(async (tx) => {
      if (skipExisting) {
        const existingRows = await tx.gameConfig.findMany({
          where: { key: { in: keys } },
          select: { key: true },
        })
        const existingKeys = new Set(existingRows.map((row) => row.key))

        const created = []
        let skipped = 0

        for (const update of parsedUpdates) {
          if (existingKeys.has(update.key)) {
            skipped += 1
            continue
          }

          created.push(
            await tx.gameConfig.create({
              data: buildConfigUpsertData(update).create,
            }),
          )
        }

        return { configs: created, created: created.length, skipped }
      }

      const configs = []
      for (const update of parsedUpdates) {
        configs.push(await tx.gameConfig.upsert(buildConfigUpsertData(update)))
      }

      return { configs, created: configs.length, skipped: 0 }
    })

    await invalidateGameConfigCache(keys)

    await prisma.adminLog.create({
      data: {
        adminId: admin.id,
        action: skipExisting ? 'seed_config_defaults' : 'update_config_batch',
        target: skipExisting ? 'game_config_defaults' : 'game_config_batch',
        details: {
          keys,
          total: parsedUpdates.length,
          created: result.created,
          skipped: result.skipped,
        } as never,
      },
    })

    return NextResponse.json({
      configs: result.configs,
      created: result.created,
      skipped: result.skipped,
      total: parsedUpdates.length,
    })
  } catch (error) {
    console.error('admin batch config error:', error)
    return NextResponse.json({ error: 'Failed to update config batch' }, { status: 500 })
  }
}

export async function DELETE(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  const key = req.nextUrl.searchParams.get('key')
  if (!key) {
    return NextResponse.json({ error: 'key query param required' }, { status: 400 })
  }

  try {
    const ladderProblem = await describeLadderDeleteProblem(key)
    if (ladderProblem) {
      return NextResponse.json(
        { error: `Removing this override would break the PvP ladder: ${ladderProblem}` },
        { status: 400 },
      )
    }

    await prisma.gameConfig.delete({ where: { key } })
    await invalidateGameConfigCache([key])

    await prisma.adminLog.create({
      data: {
        adminId: admin.id,
        action: 'delete_config',
        target: key,
      },
    })

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('admin delete config error:', error)
    return NextResponse.json({ error: 'Failed to delete config' }, { status: 500 })
  }
}
