import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'
import { getEloConfig } from '@/lib/game/live-config'

/**
 * GET /api/admin/matchmaking
 *
 * Returns the current ELO config + active-population rating distribution so
 * GMs can see whether the curve is skewed (e.g. 90% of active characters
 * clustered at 950–1050).
 *
 * Read-only for Phase 1 — tuning the K-factor or calibration window goes
 * through live-config (`elo.k_calibration`, `elo.k_default`,
 * `elo.calibration_games`) which already has its own admin surface at
 * `/config`. This page exists so matchmaking health is visible without
 * cross-referencing three other pages.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const activeSince = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)

    const buckets = [
      { label: '< 800', min: 0, max: 799 },
      { label: '800–999', min: 800, max: 999 },
      { label: '1000–1199', min: 1000, max: 1199 },
      { label: '1200–1499', min: 1200, max: 1499 },
      { label: '1500–1999', min: 1500, max: 1999 },
      { label: '2000–2499', min: 2000, max: 2499 },
      { label: '2500+', min: 2500, max: 999_999 },
    ]

    const [totalActive, recentMatches, distribution, eloConfig] = await Promise.all([
      prisma.character.count({ where: { updatedAt: { gte: activeSince } } }),
      prisma.pvpMatch.count({ where: { playedAt: { gte: activeSince } } }),
      Promise.all(
        buckets.map(async (b) => ({
          ...b,
          count: await prisma.character.count({
            where: {
              pvpRating: { gte: b.min, lte: b.max },
              updatedAt: { gte: activeSince },
            },
          }),
        })),
      ),
      getEloConfig(),
    ])

    return NextResponse.json({
      config: {
        startRating: 1000,
        calibrationGames: eloConfig.CALIBRATION_GAMES,
        kFactorCalibration: eloConfig.K_CALIBRATION,
        kFactorDefault: eloConfig.K_DEFAULT,
      },
      activeCharacters7d: totalActive,
      matchesPlayed7d: recentMatches,
      distribution,
    })
  } catch (error) {
    console.error('admin matchmaking stats error:', error)
    return NextResponse.json({ error: 'Failed to fetch matchmaking stats' }, { status: 500 })
  }
}
