import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { STAMINA } from '@/lib/game/balance'

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

    // Calculate current stamina with regen
    const staminaResult = calculateCurrentStamina(
      character.currentStamina,
      character.maxStamina,
      character.lastStaminaUpdate ?? new Date()
    )

    // If stamina was regenerated, persist the updated value
    if (staminaResult.updated) {
      await prisma.character.update({
        where: { id: characterId },
        data: {
          currentStamina: staminaResult.stamina,
          lastStaminaUpdate: new Date(),
        },
      })
    }

    // Calculate free PvP remaining today
    const today = new Date()
    today.setUTCHours(0, 0, 0, 0)
    let freePvpRemaining: number = STAMINA.FREE_PVP_PER_DAY

    if (character.freePvpDate) {
      const freePvpDay = new Date(character.freePvpDate)
      freePvpDay.setUTCHours(0, 0, 0, 0)
      if (freePvpDay.getTime() === today.getTime()) {
        freePvpRemaining = Math.max(0, STAMINA.FREE_PVP_PER_DAY - character.freePvpToday)
      }
    }

    // Calculate time until next stamina regen
    const lastUpdate = character.lastStaminaUpdate ?? new Date()
    const msSinceUpdate = Date.now() - lastUpdate.getTime()
    const msPerRegen = STAMINA.REGEN_INTERVAL_MINUTES * 60 * 1000
    const msUntilNextRegen =
      staminaResult.stamina >= character.maxStamina
        ? 0
        : msPerRegen - (msSinceUpdate % msPerRegen)

    return NextResponse.json({
      stamina: {
        current: staminaResult.stamina,
        max: character.maxStamina,
        pvpCost: STAMINA.PVP_COST,
        regenRateMinutes: STAMINA.REGEN_INTERVAL_MINUTES,
        nextRegenInMs: Math.round(msUntilNextRegen),
      },
      pvp: {
        rating: character.pvpRating,
        wins: character.pvpWins,
        losses: character.pvpLosses,
        winStreak: character.pvpWinStreak,
        lossStreak: character.pvpLossStreak,
        highestRank: character.highestPvpRank,
        calibrationGames: character.pvpCalibrationGames,
      },
      freePvpRemaining,
      firstWinToday: character.firstWinToday,
    })
  } catch (error) {
    console.error('combat status error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch combat status' },
      { status: 500 }
    )
  }
}
