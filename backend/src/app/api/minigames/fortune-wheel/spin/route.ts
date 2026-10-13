import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { WHEEL_SECTORS } from '@/lib/game/fortune-wheel'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { updateWeeklyChallengeProgress } from '@/lib/game/weekly-challenges'
import { rateLimit } from '@/lib/rate-limit'

const MIN_BET = 50
const MAX_BET = 1000
const DAILY_SPIN_LIMIT = 10

// Sector table lives in lib/game/fortune-wheel.ts (shared with /status for odds).

function pickWinningSector(): number {
  const totalWeight = WHEEL_SECTORS.reduce((sum, s) => sum + s.weight, 0)
  let roll = Math.random() * totalWeight
  for (const sector of WHEEL_SECTORS) {
    roll -= sector.weight
    if (roll <= 0) return sector.index
  }
  return 0 // fallback to LOSE
}

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, bet_amount } = body

    if (!(await rateLimit('fortune-spin:' + user.id, 10, 60_000))) {
      return NextResponse.json(
        { error: 'Too many requests. Please try again later.' },
        { status: 429 }
      )
    }

    if (!character_id || bet_amount == null) {
      return NextResponse.json(
        { error: 'character_id and bet_amount are required' },
        { status: 400 }
      )
    }

    if (!Number.isInteger(bet_amount) || bet_amount < MIN_BET || bet_amount > MAX_BET) {
      return NextResponse.json(
        { error: `Bet must be between ${MIN_BET} and ${MAX_BET} gold` },
        { status: 400 }
      )
    }

    const today = new Date().toISOString().split('T')[0]

    // Pick winning sector server-side
    const winningSectorIndex = pickWinningSector()
    const winningSector = WHEEL_SECTORS[winningSectorIndex]
    const winAmount = Math.floor(bet_amount * winningSector.multiplier)
    const won = winningSector.multiplier > 0

    // Atomic transaction: deduct bet, create session, award winnings
    const result = await prisma.$transaction(async (tx) => {
      // Verify character ownership
      const character = await tx.character.findUnique({
        where: { id: character_id },
      })

      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Lock the wallet row first, then check the daily limit and the balance
      // inside the same transaction. Both used to be read outside it, so
      // concurrent spins could exceed the daily cap and drive gold negative.
      // shell-game/start already does it this way.
      const locked = await tx.$queryRaw<{ gold: number }[]>`
        SELECT gold FROM "users" WHERE id = ${user.id} FOR UPDATE
      `
      const currentGold = locked[0]?.gold ?? 0

      const todaySpins = await tx.minigameSession.count({
        where: {
          characterId: character_id,
          gameType: 'fortune_wheel',
          createdAt: { gte: new Date(today) },
        },
      })
      if (todaySpins >= DAILY_SPIN_LIMIT) {
        throw Object.assign(new Error('DAILY_LIMIT'), { spinsToday: todaySpins })
      }

      if (currentGold < bet_amount) throw new Error('NOT_ENOUGH_GOLD')

      // Deduct bet from user
      await tx.user.update({
        where: { id: user.id },
        data: { gold: { decrement: bet_amount } },
      })

      // Create completed session (single-step game, no guess phase)
      await tx.minigameSession.create({
        data: {
          characterId: character_id,
          gameType: 'fortune_wheel',
          betAmount: bet_amount,
          secretData: { winningSectorIndex, multiplier: winningSector.multiplier },
          status: 'completed',
          result: {
            won,
            sectorIndex: winningSectorIndex,
            multiplier: winningSector.multiplier,
            winAmount,
          },
        },
      })

      // Award winnings if won
      let finalGold = currentGold - bet_amount
      if (won) {
        const updated = await tx.user.update({
          where: { id: user.id },
          data: { gold: { increment: winAmount } },
        })
        finalGold = updated.gold
      }

      return { finalGold, characterId: character_id, spinsToday: todaySpins + 1 }
    })

    // Update daily + weekly quest progress (non-critical, outside transaction)
    await Promise.all([
      updateDailyQuestProgress(prisma, result.characterId, 'shell_game_play'),
      updateDailyQuestProgress(prisma, result.characterId, 'gold_spent', bet_amount),
      // W3.D5 — Weekly BP challenges: Lucky Hand + Spendthrift slots
      updateWeeklyChallengeProgress(prisma, result.characterId, 'shell_game_play'),
      updateWeeklyChallengeProgress(prisma, result.characterId, 'gold_spent', bet_amount),
    ])

    return NextResponse.json({
      won,
      sector_index: winningSectorIndex,
      multiplier: winningSector.multiplier,
      win_amount: winAmount,
      gold: result.finalGold,
      spins_today: result.spinsToday,
      spins_limit: DAILY_SPIN_LIMIT,
      spins_remaining: Math.max(0, DAILY_SPIN_LIMIT - result.spinsToday),
      // Send full sector layout so client can render the wheel
      sectors: WHEEL_SECTORS.map(s => ({
        index: s.index,
        multiplier: s.multiplier,
        label: s.label,
      })),
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'NOT_ENOUGH_GOLD') return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
      if (error.message === 'DAILY_LIMIT') {
        const spinsToday = (error as Error & { spinsToday?: number }).spinsToday
        return NextResponse.json(
          {
            error: 'Daily spin limit reached',
            spins_today: spinsToday ?? DAILY_SPIN_LIMIT,
            spins_limit: DAILY_SPIN_LIMIT,
          },
          { status: 429 }
        )
      }
    }
    console.error('fortune-wheel spin error:', error)
    return NextResponse.json(
      { error: 'Failed to spin the wheel' },
      { status: 500 }
    )
  }
}
