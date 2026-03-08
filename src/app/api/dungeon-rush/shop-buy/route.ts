import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import {
  generateShopItems,
  adjustHpPercent,
  RUSH_SHOP_HEAL,
  type RushState,
} from '@/lib/game/dungeon-rush'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, run_id, slot } = body

    if (!character_id || !run_id || slot === undefined || slot === null) {
      return NextResponse.json(
        { error: 'character_id, run_id, and slot are required' },
        { status: 400 },
      )
    }

    if (typeof slot !== 'number' || slot < 0 || slot > 2) {
      return NextResponse.json(
        { error: 'slot must be 0, 1, or 2' },
        { status: 400 },
      )
    }

    // Verify character belongs to user
    const character = await prisma.character.findFirst({
      where: { id: character_id, userId: user.id },
    })
    if (!character) {
      return NextResponse.json(
        { error: 'Character not found' },
        { status: 404 },
      )
    }

    // Load the active rush run
    const run = await prisma.dungeonRun.findFirst({
      where: {
        id: run_id,
        characterId: character_id,
        difficulty: 'rush',
      },
    })
    if (!run) {
      return NextResponse.json(
        { error: 'No active dungeon rush found' },
        { status: 404 },
      )
    }

    const state = run.state as unknown as RushState

    // Legacy run without new room system
    if (!state.rooms || !Array.isArray(state.rooms)) {
      await prisma.dungeonRun.delete({ where: { id: run.id } })
      return NextResponse.json(
        { error: 'Legacy rush run cleaned up. Please start a new rush.' },
        { status: 400 },
      )
    }

    const currentRoom = state.rooms[state.currentRoomIndex]

    if (!currentRoom || currentRoom.type !== 'shop') {
      return NextResponse.json(
        { error: 'Current room is not a shop' },
        { status: 400 },
      )
    }

    if (state.shopPurchased.includes(slot)) {
      return NextResponse.json(
        { error: 'Item already purchased' },
        { status: 400 },
      )
    }

    // Get shop items
    const shopItems = generateShopItems(currentRoom.seed)
    const item = shopItems.find(i => i.slot === slot)
    if (!item) {
      return NextResponse.json(
        { error: 'Invalid shop slot' },
        { status: 400 },
      )
    }

    // Check gold
    if (character.gold < item.price) {
      return NextResponse.json(
        { error: `Not enough gold. Need ${item.price}, have ${character.gold}` },
        { status: 400 },
      )
    }

    // Deduct gold
    await prisma.character.update({
      where: { id: character_id },
      data: { gold: { decrement: item.price } },
    })

    // Apply purchase effect
    let newHpPercent = state.currentHpPercent
    let newBuffs = [...state.buffs]

    if (item.type === 'heal') {
      newHpPercent = adjustHpPercent(state.currentHpPercent, RUSH_SHOP_HEAL.hpPercent)
    } else if (item.type === 'buff' && item.buffId && item.stat && item.value) {
      // Only add if not already have same buff
      if (!newBuffs.some(b => b.id === item.buffId)) {
        newBuffs.push({
          id: item.buffId!,
          name: item.name,
          stat: item.stat!,
          value: item.value!,
          icon: item.icon,
        })
      }
    }

    // Update state
    const newState: RushState = {
      ...state,
      currentHpPercent: newHpPercent,
      buffs: newBuffs,
      shopPurchased: [...state.shopPurchased, slot],
    }

    await prisma.dungeonRun.update({
      where: { id: run.id },
      data: {
        state: JSON.parse(JSON.stringify(newState)),
      },
    })

    return NextResponse.json({
      purchased: true,
      slot,
      item: {
        name: item.name,
        type: item.type,
        icon: item.icon,
      },
      currentHpPercent: newHpPercent,
      buffs: newBuffs,
      playerGold: character.gold - item.price,
      shopPurchased: newState.shopPurchased,
    })
  } catch (error) {
    console.error('dungeon rush shop-buy error:', error)
    return NextResponse.json(
      { error: 'Failed to process shop purchase' },
      { status: 500 },
    )
  }
}
