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

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`rush-resolve:${user.id}`, 20, 60_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
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

    // Handle room resolution based on type
    let goldReward = 0
    let xpReward = 0
    let hpChange = 0
    let buffGranted: { id: string; name: string; stat: string; value: number; icon: string } | null = null
    let roomResult: Record<string, unknown> = {}

    switch (currentRoom.type) {
      case 'treasure': {
        goldReward = chaGoldBonus(treasureGoldReward(currentRoom.index), character.cha)

        // 50% chance of a random buff from seed
        if (currentRoom.seed % 2 === 0) {
          const buffIdx = (currentRoom.seed >> 4) % RUSH_BUFFS.length
          const buff = RUSH_BUFFS[buffIdx]
          // Only grant if not already have this buff
          if (!state.buffs.some(b => b.id === buff.id)) {
            buffGranted = { id: buff.id, name: buff.name, stat: buff.stat, value: buff.value, icon: buff.icon }
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
        const eventResult = resolveEvent(currentRoom.index, currentRoom.seed)
        goldReward = eventResult.goldReward
        xpReward = eventResult.xpReward
        hpChange = eventResult.hpChange

        // Only grant buff if not already have same id
        if (eventResult.buffGranted && !state.buffs.some(b => b.id === eventResult.buffGranted!.id)) {
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
        // If action === 'leave_shop', leave and advance
        if (action === 'leave_shop') {
          // Just mark resolved and advance (no rewards)
          roomResult = { type: 'shop', action: 'leave' }
          break
        }

        // Otherwise, return shop items without resolving the room
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

      default:
        return NextResponse.json(
          { error: `Unknown room type: ${currentRoom.type}` },
          { status: 400 },
        )
    }

    // Apply gold reward
    if (goldReward > 0) {
      await prisma.character.update({
        where: { id: character_id },
        data: {
          gold: { increment: goldReward },
          ...(xpReward > 0 ? { currentXp: { increment: xpReward } } : {}),
        },
      })
    } else if (xpReward > 0) {
      await prisma.character.update({
        where: { id: character_id },
        data: { currentXp: { increment: xpReward } },
      })
    }

    // Update state
    const updatedRooms = [...state.rooms]
    updatedRooms[state.currentRoomIndex] = { ...currentRoom, resolved: true }

    const newHpPercent = hpChange !== 0
      ? adjustHpPercent(state.currentHpPercent, hpChange)
      : state.currentHpPercent

    const newBuffs = buffGranted
      ? [...state.buffs, buffGranted]
      : state.buffs

    const nextRoomIndex = state.currentRoomIndex + 1
    const isRushComplete = nextRoomIndex >= TOTAL_RUSH_ROOMS

    if (isRushComplete) {
      // Rush complete — delete run
      await prisma.dungeonRun.delete({ where: { id: run.id } })

      return NextResponse.json({
        ...roomResult,
        rushComplete: true,
        currentHpPercent: newHpPercent,
        buffs: newBuffs,
        rewards: {
          gold: goldReward,
          xp: xpReward,
          totalGold: state.totalGoldEarned + goldReward,
          totalXp: state.totalXpEarned + xpReward,
          floorsCleared: state.floorsCleared,
        },
      })
    }

    const newState: RushState = {
      ...state,
      rooms: updatedRooms,
      currentRoomIndex: nextRoomIndex,
      currentHpPercent: newHpPercent,
      buffs: newBuffs,
      shopPurchased: currentRoom.type === 'shop' ? [] : state.shopPurchased, // Reset shop purchased for next shop
      totalGoldEarned: state.totalGoldEarned + goldReward,
      totalXpEarned: state.totalXpEarned + xpReward,
    }

    await prisma.dungeonRun.update({
      where: { id: run.id },
      data: {
        currentFloor: nextRoomIndex + 1,
        state: JSON.parse(JSON.stringify(newState)),
      },
    })

    // Build next room info
    const nextRoom = newState.rooms[nextRoomIndex]
    const nextEnemy = isCombatRoom(nextRoom.type)
      ? generateRushEnemy(nextRoom.index, nextRoom.type, nextRoom.seed)
      : undefined

    return NextResponse.json({
      ...roomResult,
      rushComplete: false,
      currentHpPercent: newHpPercent,
      buffs: newBuffs,
      rewards: {
        gold: goldReward,
        xp: xpReward,
        totalGold: newState.totalGoldEarned,
        totalXp: newState.totalXpEarned,
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
    })
  } catch (error) {
    console.error('dungeon rush resolve error:', error)
    return NextResponse.json(
      { error: 'Failed to resolve dungeon rush room' },
      { status: 500 },
    )
  }
}
