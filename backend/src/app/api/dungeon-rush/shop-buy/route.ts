import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import {
  generateShopItems,
  adjustHpPercent,
  RUSH_SHOP_HEAL,
  type RushState,
} from '@/lib/game/dungeon-rush'
import { lockDungeonRunForUpdate } from '@/lib/game/dungeon-run-lock'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`rush-shop:${user.id}`, 15, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

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

    const txResult = await prisma.$transaction(async (tx) => {
      // Verify character exists
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      const lockedRun = await lockDungeonRunForUpdate(tx, run_id)
      if (!lockedRun) throw new Error('RUN_NOT_FOUND')
      if (lockedRun.characterId !== character_id || lockedRun.difficulty !== 'rush') {
        throw new Error('RUN_NOT_FOUND')
      }

      const state = lockedRun.state as RushState | null
      if (!state?.rooms || !Array.isArray(state.rooms)) {
        await tx.dungeonRun.delete({ where: { id: run_id } })
        throw new Error('LEGACY_RUN')
      }

      const currentRoom = state.rooms[state.currentRoomIndex]
      if (!currentRoom || currentRoom.type !== 'shop') {
        throw new Error('ROOM_NOT_SHOP')
      }
      if (state.shopPurchased.includes(slot)) {
        throw new Error('ALREADY_PURCHASED')
      }

      const shopItems = generateShopItems(currentRoom.seed)
      const item = shopItems.find((candidate) => candidate.slot === slot)
      if (!item) throw new Error('INVALID_SLOT')

      // Lock user row for gold check
      const [userRow] = await tx.$queryRawUnsafe<Array<{id: string; gold: number}>>(
        `SELECT id, gold FROM users WHERE id = $1 FOR UPDATE`,
        user.id
      )
      if (!userRow) throw new Error('USER_NOT_FOUND')

      if (userRow.gold < item.price) {
        throw new Error(`GOLD:Not enough gold. Need ${item.price}, have ${userRow.gold}`)
      }

      // Deduct gold from user
      await tx.user.update({
        where: { id: user.id },
        data: { gold: { decrement: item.price } },
      })

      let newHpPercent = state.currentHpPercent
      const newBuffs = [...state.buffs]

      if (item.type === 'heal') {
        newHpPercent = adjustHpPercent(state.currentHpPercent, RUSH_SHOP_HEAL.hpPercent)
      } else if (item.type === 'buff' && item.buffId && item.stat && item.value) {
        if (!newBuffs.some((buff) => buff.id === item.buffId)) {
          newBuffs.push({
            id: item.buffId,
            name: item.name,
            stat: item.stat,
            value: item.value,
            icon: item.icon,
          })
        }
      }

      const newState: RushState = {
        ...state,
        currentHpPercent: newHpPercent,
        buffs: newBuffs,
        shopPurchased: [...state.shopPurchased, slot],
      }

      await tx.dungeonRun.update({
        where: { id: run_id },
        data: {
          state: JSON.parse(JSON.stringify(newState)),
        },
      })

      return {
        remainingGold: userRow.gold - item.price,
        item: {
          name: item.name,
          type: item.type,
          icon: item.icon,
        },
        newHpPercent,
        newBuffs,
        shopPurchased: newState.shopPurchased,
      }
    })

    return NextResponse.json({
      purchased: true,
      slot,
      item: txResult.item,
      currentHpPercent: txResult.newHpPercent,
      buffs: txResult.newBuffs,
      playerGold: txResult.remainingGold,
      shopPurchased: txResult.shopPurchased,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND' || error.message === 'FORBIDDEN') {
        return NextResponse.json(
          { error: 'Character not found' },
          { status: 404 },
        )
      }
      if (error.message === 'RUN_NOT_FOUND') {
        return NextResponse.json(
          { error: 'No active dungeon rush found' },
          { status: 404 },
        )
      }
      if (error.message === 'LEGACY_RUN') {
        return NextResponse.json(
          { error: 'Legacy rush run cleaned up. Please start a new rush.' },
          { status: 400 },
        )
      }
      if (error.message === 'ROOM_NOT_SHOP') {
        return NextResponse.json(
          { error: 'Current room is not a shop' },
          { status: 400 },
        )
      }
      if (error.message === 'ALREADY_PURCHASED') {
        return NextResponse.json(
          { error: 'Item already purchased' },
          { status: 400 },
        )
      }
      if (error.message === 'INVALID_SLOT') {
        return NextResponse.json(
          { error: 'Invalid shop slot' },
          { status: 400 },
        )
      }
      if (error.message.startsWith('GOLD:')) {
        return NextResponse.json(
          { error: error.message.slice(5) },
          { status: 400 },
        )
      }
    }
    console.error('dungeon rush shop-buy error:', error)
    return NextResponse.json(
      { error: 'Failed to process shop purchase' },
      { status: 500 },
    )
  }
}
