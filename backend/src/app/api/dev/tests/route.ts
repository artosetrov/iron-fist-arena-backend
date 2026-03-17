import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { runCombat } from '@/lib/game/combat'
import { calculateElo, getKFactor } from '@/lib/game/elo'
import { calculateCurrentStamina } from '@/lib/game/stamina'
import { xpForLevel, bpXpForLevel } from '@/lib/game/balance'

/**
 * GET /api/dev/tests
 * Runs a suite of lightweight in-process sanity checks.
 * Returns pass/fail results for each test.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const dbUser = await prisma.user.findUnique({ where: { id: user.id } })
  if (!dbUser || !['admin', 'dev'].includes(dbUser.role)) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  const results: Array<{ name: string; passed: boolean; detail?: string }> = []

  // 1. ELO calculation
  try {
    const elo = calculateElo(1000, 1000, 32)
    const passed = elo.newWinner > 1000 && elo.newLoser < 1000
    results.push({ name: 'ELO calculation', passed, detail: JSON.stringify(elo) })
  } catch (e) {
    results.push({ name: 'ELO calculation', passed: false, detail: String(e) })
  }

  // 2. K-factor for calibration
  try {
    const kCalib = await getKFactor(5)  // still in calibration
    const kNormal = await getKFactor(15) // past calibration
    results.push({
      name: 'K-factor calibration',
      passed: kCalib > kNormal,
      detail: `calibration=${kCalib} normal=${kNormal}`,
    })
  } catch (e) {
    results.push({ name: 'K-factor calibration', passed: false, detail: String(e) })
  }

  // 3. Stamina regen
  try {
    const past = new Date(Date.now() - 16 * 60 * 1000) // 16 minutes ago
    const result = await calculateCurrentStamina(100, 120, past)
    results.push({
      name: 'Stamina regen',
      passed: result.stamina >= 102,
      detail: `stamina=${result.stamina}`,
    })
  } catch (e) {
    results.push({ name: 'Stamina regen', passed: false, detail: String(e) })
  }

  // 4. XP formula
  try {
    const xp10 = xpForLevel(10)
    const xp1 = xpForLevel(1)
    results.push({
      name: 'XP formula',
      passed: xp10 > xp1 && xp1 > 0,
      detail: `level1=${xp1} level10=${xp10}`,
    })
  } catch (e) {
    results.push({ name: 'XP formula', passed: false, detail: String(e) })
  }

  // 5. BP XP formula
  try {
    const bp1 = bpXpForLevel(1)
    const bp30 = bpXpForLevel(30)
    results.push({
      name: 'BP XP formula',
      passed: bp30 > bp1,
      detail: `level1=${bp1} level30=${bp30}`,
    })
  } catch (e) {
    results.push({ name: 'BP XP formula', passed: false, detail: String(e) })
  }

  // 6. Combat engine
  try {
    const fighter = {
      id: 'a', name: 'A', class: 'warrior' as const,
      level: 1, str: 15, agi: 10, vit: 10, end: 10,
      int: 5, wis: 5, luk: 5, cha: 5,
      maxHp: 100, armor: 5, magicResist: 0,
    }
    const result = await runCombat(fighter, { ...fighter, id: 'b', name: 'B' })
    results.push({
      name: 'Combat engine',
      passed: !!result.winnerId && result.totalTurns >= 1,
      detail: `winner=${result.winnerId} turns=${result.totalTurns}`,
    })
  } catch (e) {
    results.push({ name: 'Combat engine', passed: false, detail: String(e) })
  }

  // 7. DB connectivity
  try {
    await prisma.$queryRaw`SELECT 1`
    results.push({ name: 'DB connectivity', passed: true })
  } catch (e) {
    results.push({ name: 'DB connectivity', passed: false, detail: String(e) })
  }

  const allPassed = results.every((r) => r.passed)

  return NextResponse.json({
    all_passed: allPassed,
    results,
    total: results.length,
    passed: results.filter((r) => r.passed).length,
    failed: results.filter((r) => !r.passed).length,
  })
}
