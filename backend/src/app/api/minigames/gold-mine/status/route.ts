import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import {
  BOOST_MULTIPLIER,
  buildSlotsArray,
  getBOOST_COST_GEMS,
  getSLOT_COST_GEMS,
  GEM_DROP_CHANCE,
  GEM_DROP_MAX,
  GEM_DROP_MIN,
  MAX_GOLD_MINE_SLOTS,
  MINE_DURATION_HOURS,
  MINE_REWARD_MAX,
  MINE_REWARD_MIN,
} from '@/lib/game/gold-mine'
import {
  activeShaftJson,
  currentShaft,
  EXPEDITION_CHEST_GEMS,
  EXPEDITION_CHEST_GOLD,
} from '@/lib/game/gold-mine-expedition'
import {
  MINIGAME_DURATION_SEC,
  MINIGAME_GEM_CAP,
  MINIGAME_GEM_CATCH_THRESHOLD,
  slotMinigameCapFraction,
} from '@/lib/game/shaft-catalog'

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json(
        { error: 'character_id is required' },
        { status: 400 }
      )
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const slots = await buildSlotsArray(prisma, characterId, character.goldMineSlots, true)

    // There is always an expedition to show: with none running, the one the
    // next collect will start (progress 0). Collecting never needs a pick.
    const shaft = currentShaft(character)
    const [boostCost, slotCost] = await Promise.all([getBOOST_COST_GEMS(), getSLOT_COST_GEMS()])

    return NextResponse.json({
      slots,
      max_slots: character.goldMineSlots,
      active_shaft: activeShaftJson(shaft.key, shaft.progress, shaft.total),
      needs_shaft_pick: false,
      // Everything the mine screen prints comes from here — the client keeps
      // no copy of these numbers (2026-10-16).
      economy: {
        slot_limit: MAX_GOLD_MINE_SLOTS,
        slot_cost_gems: slotCost,
        boost_cost_gems: boostCost,
        boost_multiplier: BOOST_MULTIPLIER,
        run_hours: MINE_DURATION_HOURS,
        reward_min: MINE_REWARD_MIN,
        reward_max: MINE_REWARD_MAX,
        gem_chance: GEM_DROP_CHANCE,
        gem_min: GEM_DROP_MIN,
        gem_max: GEM_DROP_MAX,
        chest_gold: EXPEDITION_CHEST_GOLD,
        chest_gems: EXPEDITION_CHEST_GEMS,
        // Optional bonus round: up to this % of the cart on top, plus a gem
        // when the player catches at least `bonus_gem_catch_percent` of coins.
        bonus_seconds: MINIGAME_DURATION_SEC,
        bonus_cap_percent: Math.floor(slotMinigameCapFraction(character.goldMineSlots) * 100),
        bonus_gem_cap: MINIGAME_GEM_CAP,
        bonus_gem_catch_percent: Math.round(MINIGAME_GEM_CATCH_THRESHOLD * 100),
      },
    })
  } catch (error) {
    console.error('gold-mine status error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch gold mine status' },
      { status: 500 }
    )
  }
}
