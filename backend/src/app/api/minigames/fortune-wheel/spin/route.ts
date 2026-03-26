import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { updateDailyQuestProgress } from '@/lib/game/daily-quests'
import { rateLimit } from '@/lib/rate-limit'

const MIN_BET = 50
const MAX_BET = 1000

// Fortune Wheel sectors — server-authoritative
// Each sector: { multiplier, weight }
// Weighted random selection (not uniform — allows fine-tuning RTP)
const WHEEL_SECTORS = [
  { index: 0, multiplier: 0,   label: 'LOSE',  weight: 40 },  // 💀
  { index: 1, multiplier: 1.5, label: 'x1.5',  weight: 25 },  // 🪙
  { index: 2, multiplier: 0,   label: 'LOSE',  weight: 40 },  // 💀
  { index: 3, multiplier: 2,   label: 'x2',    weight: 20 },  // 💰
  { index: 4, multiplier: 0,   label: 'LOSE',  weight: 40 },  // 💀
  { index: 5, multiplier: 1.5, label: 'x1.5',  weight: 25 },  // 🪙
  { index: 6, multiplier: 0,   label: 'LOSE',  weight: 40 },  // 💀
  { index: 7, multiplier: 3,   label: 'x3',    weight: 10 },  // 💎
  { index: 8, multiplier: 0,   label: 'LOSE',  weight: 40 },  // 💀
  { index: 9, multiplier: 1.5, label: 'x1.5',  weight: 25 },  // 🪙
  { index: 10, multiplier: 0,  label: 'LOSE',  weight: 40 },  // 💀
  { index: 11, multiplier: 5,  label: 'x5',    weight: 5  },  // 👑 JACKPOT
]
// RTP calculation:
// Total weight = 40*6 + 25*3 + 20 + 10 + 5 = 240 + 75 + 20 + 10 + 5 = 350
// EV = (75/350)*1.5 + (20/350)*2 + (10/350)*3 + (5/350)*5
//    = 0.321 + 0.114 + 0.086 + 0.071 = 0.593 → 59.3% RTP
// House edge ~40% — aggressive but typical for mobile game gold sink

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

    // Pick winning sector server-side
    const winningSectorIndex = pickWinningSector()
    const winningSector = WHEEL_SECTORS[winningSectorIndex]
    const winAmount = Math.floor(bet_amount * winningSector.multiplier)
    const won = winningSector.multiplier > 0

    // Atomic transaction: deduct bet, create session, award winnings
    const result = await prisma.$transaction(async (tx) => {
      const character = await tx.character.findUnique({
        where: { id: character_id },
      })

      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')
      if (character.gold < bet_amount) throw new Error('NOT_ENOUGH_GOLD')

      // Deduct bet
      await tx.character.update({
        where: { id: character_id },
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
      let finalGold = character.gold - bet_amount
      if (won) {
        const updated = await tx.character.update({
          where: { id: character_id },
          data: { gold: { increment: winAmount } },
        })
        finalGold = updated.gold
      }

      return { finalGold, characterId: character_id }
    })

    // Update daily quest progress (non-critical, outside transaction)
    await updateDailyQuestProgress(prisma, result.characterId, 'shell_game_play')
    await updateDailyQuestProgress(prisma, result.characterId, 'gold_spent', bet_amount)

    return NextResponse.json({
      won,
      sector_index: winningSectorIndex,
      multiplier: winningSector.multiplier,
      win_amount: winAmount,
      gold: result.finalGold,
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
    }
    console.error('fortune-wheel spin error:', error)
    return NextResponse.json(
      { error: 'Failed to spin the wheel' },
      { status: 500 }
    )
  }
}
