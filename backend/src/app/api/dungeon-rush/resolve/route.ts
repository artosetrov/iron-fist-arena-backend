import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { chaGoldBonus } from '@/lib/game/balance'
import {
  resolveEvent,
  treasureGoldReward,
  generateShopItems,
  generateRushEnemy,
  adjustHpPercent,
  isCombatRoom,
  TOTAL_RUSH_ROOMS,
  RUSH_BUFFS,
  type RushState,
} from '@/lib/game/dungeon-rush'
import { lockDungeonRunForUpdate } from '@/lib/game/dungeon-run-lock'
import { getBattlePassConfig } from '@/lib/game/live-config'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`rush-resolve:${user.id}`, 20, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  let activeRunId: string | null = null
  let activeRoomType: string | null = null

  try {
    const BATTLE_PASS = await getBattlePassConfig()
    const body = await req.json()
    const { character_id, run_id, action } = body

    if (!character_id || !run_id) {
      return NextResponse.json(
        { error: 'character_id and run_id are required' },
        { status: 400 },
      )
    }

    // Parallel: verify character (select only needed fields) + load run
    const [character, run] = await Promise.all([
      prisma.character.findFirst({
        where: { id: character_id, userId: user.id },
        select: { id: true, cha: true, gold: true },
      }),
      prisma.dungeonRun.findFirst({
        where: {
          id: run_id,
          characterId: character_id,
          difficulty: 'rush',
        },
      }),
    ])

    if (!character) {
      return NextResponse.json(
        { error: 'Character not found' },
        { status: 404 },
      )
    }

    if (!run) {
      return NextResponse.json(
        { error: 'No active dungeon rush found' },
        { status: 404 },
      )
    }
    activeRunId = run.id

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
    activeRoomType = currentRoom?.type ?? null

    if (!currentRoom) {
      return NextResponse.json(
        { error: 'No more rooms in dungeon rush' },
        { status: 400 },
      )
    }

    if (isCombatRoom(currentRoom.type)) {
      return NextResponse.json(
        { error: `Current room is ${currentRoom.type}. Use /fight endpoint.` },
        { status: 400 },
      )
    }

    if (currentRoom.resolved) {
      return NextResponse.json(
        { error: 'This room is already resolved' },
        { status: 400 },
      )
    }

    if (currentRoom.type === 'shop' && action !== 'leave_shop') {
      const shopItems = generateShopItems(currentRoom.seed)
      return NextResponse.json({
        type: 'shop',
        items: shopItems.map(item => ({
          ...item,
          purchased: state.shopPurchased.includes(item.slot),
        })),
        playerGold: character.gold,
        currentHpPercent: state.currentHpPercent,
        buffs: state.buffs,
      })
    }

    const resolvedRoom = await prisma.$transaction(async (tx) => {
      const lockedRun = await lockDungeonRunForUpdate(tx, run.id)

      if (!lockedRun) throw new Error('RUSH_RUN_NOT_ACTIVE')
      if (lockedRun.characterId !== character_id || lockedRun.difficulty !== 'rush') {
        throw new Error('RUSH_RUN_MISMATCH')
      }

      const lockedState = lockedRun.state as RushState | null
      if (!lockedState || !Array.isArray(lockedState.rooms)) {
        throw new Error('RUSH_RUN_LEGACY')
      }
      if (lockedState.currentRoomIndex !== state.currentRoomIndex) {
        throw new Error('RUSH_ROOM_STALE')
      }

      const lockedRoom = lockedState.rooms[lockedState.currentRoomIndex]
      if (!lockedRoom) throw new Error('RUSH_ROOM_MISSING')
      if (
        lockedRoom.index !== currentRoom.index ||
        lockedRoom.seed !== currentRoom.seed ||
        lockedRoom.type !== currentRoom.type
      ) {
        throw new Error('RUSH_ROOM_STALE')
      }
      if (lockedRoom.resolved) throw new Error('RUSH_ROOM_RESOLVED')
      if (isCombatRoom(lockedRoom.type)) throw new Error('RUSH_ROOM_COMBAT')

      let goldReward = 0
      let xpReward = 0
      let hpChange = 0
      let buffGranted: { id: string; name: string; stat: string; value: number; icon: string } | null = null
      let roomResult: Record<string, unknown>

      switch (lockedRoom.type) {
        case 'treasure': {
          goldReward = chaGoldBonus(treasureGoldReward(lockedRoom.index), character.cha)

          if (lockedRoom.seed % 2 === 0) {
            const buffIdx = (lockedRoom.seed >> 4) % RUSH_BUFFS.length
            const buff = RUSH_BUFFS[buffIdx]
            if (!lockedState.buffs.some(existingBuff => existingBuff.id === buff.id)) {
              buffGranted = {
                id: buff.id,
                name: buff.name,
                stat: buff.stat,
                value: buff.value,
                icon: buff.icon,
              }
            }
          }

          roomResult = {
            type: 'treasure',
            gold: goldReward,
            buffGranted,
          }
          break
        }

        case 'event': {
          const eventResult = resolveEvent(lockedRoom.index, lockedRoom.seed)
          goldReward = eventResult.goldReward
          xpReward = eventResult.xpReward
          hpChange = eventResult.hpChange

          if (
            eventResult.buffGranted &&
            !lockedState.buffs.some(existingBuff => existingBuff.id === eventResult.buffGranted!.id)
          ) {
            buffGranted = eventResult.buffGranted
          }

          roomResult = {
            type: 'event',
            eventId: eventResult.eventId,
            eventName: eventResult.eventName,
            eventIcon: eventResult.eventIcon,
            description: eventResult.description,
            gold: goldReward,
            xp: xpReward,
            hpChange,
            buffGranted,
          }
          break
        }

        case 'shop': {
          if (action !== 'leave_shop') {
            throw new Error('RUSH_SHOP_ACTION_REQUIRED')
          }

          roomResult = { type: 'shop', action: 'leave' }
          break
        }

        default:
          throw new Error('RUSH_ROOM_TYPE_INVALID')
      }

      if (goldReward > 0 || xpReward > 0) {
        await tx.character.update({
          where: { id: character_id },
          data: {
            ...(goldReward > 0 ? { gold: { increment: goldReward } } : {}),
            ...(xpReward > 0 ? { currentXp: { increment: xpReward } } : {}),
          },
        })
      }

      const updatedRooms = [...lockedState.rooms]
      updatedRooms[lockedState.currentRoomIndex] = { ...lockedRoom, resolved: true }

      const newHpPercent = hpChange !== 0
        ? adjustHpPercent(lockedState.currentHpPercent, hpChange)
        : lockedState.currentHpPercent

      const newBuffs = buffGranted
        ? [...lockedState.buffs, buffGranted]
        : lockedState.buffs

      const nextRoomIndex = lockedState.currentRoomIndex + 1
      const isRushComplete = nextRoomIndex >= TOTAL_RUSH_ROOMS
      const totalGold = lockedState.totalGoldEarned + goldReward
      const totalXp = lockedState.totalXpEarned + xpReward

      if (isRushComplete) {
        await tx.dungeonRun.delete({ where: { id: run.id } })

        return {
          roomResult,
          rushComplete: true,
          currentHpPercent: newHpPercent,
          buffs: newBuffs,
          rewards: {
            gold: goldReward,
            xp: xpReward,
            totalGold,
            totalXp,
            floorsCleared: lockedState.floorsCleared,
          },
          nextRoom: null,
          nextEnemy: undefined,
        }
      }

      const newState: RushState = {
        ...lockedState,
        rooms: updatedRooms,
        currentRoomIndex: nextRoomIndex,
        currentHpPercent: newHpPercent,
        buffs: newBuffs,
        shopPurchased: lockedRoom.type === 'shop' ? [] : lockedState.shopPurchased,
        totalGoldEarned: totalGold,
        totalXpEarned: totalXp,
      }

      await tx.dungeonRun.update({
        where: { id: run.id },
        data: {
          currentFloor: nextRoomIndex + 1,
          state: JSON.parse(JSON.stringify(newState)),
        },
      })

      const nextRoom = newState.rooms[nextRoomIndex]
      const nextEnemy = isCombatRoom(nextRoom.type)
        ? generateRushEnemy(nextRoom.index, nextRoom.type, nextRoom.seed)
        : undefined

      return {
        roomResult,
        rushComplete: false,
        currentHpPercent: newHpPercent,
        buffs: newBuffs,
        rewards: {
          gold: goldReward,
          xp: xpReward,
          totalGold,
          totalXp,
          floorsCleared: newState.floorsCleared,
        },
        nextRoom: {
          index: nextRoom.index,
          type: nextRoom.type,
          seed: nextRoom.seed,
        },
        nextEnemy: nextEnemy
          ? { name: nextEnemy.name, level: nextEnemy.level }
          : undefined,
      }
    })

    return NextResponse.json({
      ...resolvedRoom.roomResult,
      rushComplete: resolvedRoom.rushComplete,
      currentHpPercent: resolvedRoom.currentHpPercent,
      buffs: resolvedRoom.buffs,
      rewards: resolvedRoom.rewards,
      ...(resolvedRoom.nextRoom ? { nextRoom: resolvedRoom.nextRoom } : {}),
      ...(resolvedRoom.nextEnemy ? { nextEnemy: resolvedRoom.nextEnemy } : {}),
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'RUSH_RUN_NOT_ACTIVE') {
        return NextResponse.json(
          { error: 'Dungeon rush is no longer active. Refresh and try again.' },
          { status: 409 },
        )
      }
      if (error.message === 'RUSH_ROOM_STALE' || error.message === 'RUSH_ROOM_RESOLVED') {
        return NextResponse.json(
          { error: 'This dungeon rush room was already resolved. Refresh and continue.' },
          { status: 409 },
        )
      }
      if (error.message === 'RUSH_RUN_MISMATCH') {
        return NextResponse.json(
          { error: 'Dungeon rush does not match this request.' },
          { status: 400 },
        )
      }
      if (error.message === 'RUSH_ROOM_COMBAT') {
        return NextResponse.json(
          { error: `Current room is ${activeRoomType ?? 'combat'}. Use /fight endpoint.` },
          { status: 400 },
        )
      }
      if (error.message === 'RUSH_ROOM_MISSING') {
        return NextResponse.json(
          { error: 'No more rooms in dungeon rush' },
          { status: 400 },
        )
      }
      if (error.message === 'RUSH_SHOP_ACTION_REQUIRED') {
        return NextResponse.json(
          { error: 'Shop room must be resolved by leaving the shop or buying through the shop endpoint.' },
          { status: 400 },
        )
      }
      if (error.message === 'RUSH_RUN_LEGACY') {
        if (activeRunId) {
          await prisma.dungeonRun.delete({ where: { id: activeRunId } }).catch(() => null)
        }
        return NextResponse.json(
          { error: 'Legacy rush run cleaned up. Please start a new rush.' },
          { status: 400 },
        )
      }
      if (error.message === 'RUSH_ROOM_TYPE_INVALID') {
        return NextResponse.json(
          { error: `Unknown room type: ${activeRoomType ?? 'unknown'}` },
          { status: 400 },
        )
      }
    }
    console.error('dungeon rush resolve error:', error)
    return NextResponse.json(
      { error: 'Failed to resolve dungeon rush room' },
      { status: 500 },
    )
  }
}
