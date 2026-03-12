import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import {
  STAMINA,
  GOLD_REWARDS,
  XP_REWARDS,
  FIRST_WIN_BONUS,
  UPGRADE_CHANCES,
  DAILY_LOGIN_REWARDS,
  IAP_PRODUCTS,
  BATTLE_PASS,
  ELO,
  COMBAT,
  PRESTIGE,
  DROP_CHANCES,
  RARITY_DISTRIBUTION,
  xpForLevel,
  bpXpForLevel,
} from '@/lib/game/balance'

/**
 * GET /api/dev/balance
 * Returns all current balance constants for review/testing.
 *
 * POST /api/dev/balance
 * Body: { key, value } — Update a GameConfig entry (dev only).
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const dbUser = await prisma.user.findUnique({ where: { id: user.id } })
  if (!dbUser || !['admin', 'dev'].includes(dbUser.role)) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  // Build XP table for levels 1–50
  const xpTable = Array.from({ length: 50 }, (_, i) => ({
    level: i + 1,
    xp_required: xpForLevel(i + 1),
  }))

  // Build BP XP table for levels 1–30
  const bpXpTable = Array.from({ length: 30 }, (_, i) => ({
    level: i + 1,
    xp_required: bpXpForLevel(i + 1),
  }))

  return NextResponse.json({
    stamina: STAMINA,
    gold_rewards: GOLD_REWARDS,
    xp_rewards: XP_REWARDS,
    first_win_bonus: FIRST_WIN_BONUS,
    upgrade_chances: UPGRADE_CHANCES,
    daily_login_rewards: DAILY_LOGIN_REWARDS,
    iap_products: IAP_PRODUCTS,
    battle_pass: BATTLE_PASS,
    elo: ELO,
    combat: COMBAT,
    prestige: PRESTIGE,
    drop_chances: DROP_CHANCES,
    rarity_distribution: RARITY_DISTRIBUTION,
    xp_table: xpTable,
    bp_xp_table: bpXpTable,
  })
}

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const dbUser = await prisma.user.findUnique({ where: { id: user.id } })
  if (!dbUser || !['admin', 'dev'].includes(dbUser.role)) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  try {
    const body = await req.json()
    const { key, value, description } = body

    if (!key) {
      return NextResponse.json({ error: 'key is required' }, { status: 400 })
    }

    const config = await prisma.gameConfig.upsert({
      where: { key },
      create: {
        key,
        value,
        category: 'balance',
        description: description ?? null,
        updatedBy: user.id,
      },
      update: {
        value,
        description: description ?? undefined,
        updatedBy: user.id,
      },
    })

    return NextResponse.json({ config })
  } catch (error) {
    console.error('dev balance POST error:', error)
    return NextResponse.json({ error: 'Failed to update balance config' }, { status: 500 })
  }
}
