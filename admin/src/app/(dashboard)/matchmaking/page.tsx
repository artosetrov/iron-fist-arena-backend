import { requireAdmin } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

const BUCKETS = [
  { label: '< 800', min: 0, max: 799 },
  { label: '800–999', min: 800, max: 999 },
  { label: '1000–1199', min: 1000, max: 1199 },
  { label: '1200–1499', min: 1200, max: 1499 },
  { label: '1500–1999', min: 1500, max: 1999 },
  { label: '2000–2499', min: 2000, max: 2499 },
  { label: '2500+', min: 2500, max: 999_999 },
]

async function loadData() {
  const activeSince = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)

  const [
    activeCharacters7d,
    matchesPlayed7d,
    distribution,
    kCalibration,
    kDefault,
    calibrationGames,
  ] = await Promise.all([
    prisma.character.count({ where: { updatedAt: { gte: activeSince } } }),
    prisma.pvpMatch.count({ where: { playedAt: { gte: activeSince } } }),
    Promise.all(
      BUCKETS.map(async (b) => ({
        ...b,
        count: await prisma.character.count({
          where: {
            pvpRating: { gte: b.min, lte: b.max },
            updatedAt: { gte: activeSince },
          },
        }),
      })),
    ),
    prisma.gameConfig.findUnique({ where: { key: 'elo.k_calibration' } }),
    prisma.gameConfig.findUnique({ where: { key: 'elo.k_default' } }),
    prisma.gameConfig.findUnique({ where: { key: 'elo.calibration_games' } }),
  ])

  return {
    activeCharacters7d,
    matchesPlayed7d,
    distribution,
    config: {
      kCalibration: typeof kCalibration?.value === 'number' ? kCalibration.value : 48,
      kDefault: typeof kDefault?.value === 'number' ? kDefault.value : 32,
      calibrationGames: typeof calibrationGames?.value === 'number' ? calibrationGames.value : 10,
    },
  }
}

export default async function MatchmakingPage() {
  await requireAdmin()
  const data = await loadData()
  const maxCount = Math.max(...data.distribution.map((d) => d.count), 1)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Matchmaking</h1>
        <p className="text-muted-foreground">
          ELO config + active-population rating distribution (last 7 days).
          Tuning K-factor / calibration window is done at <code>/config</code>{' '}
          (keys <code>elo.k_calibration</code>, <code>elo.k_default</code>,{' '}
          <code>elo.calibration_games</code>).
        </p>
      </div>

      <div className="grid gap-3 grid-cols-2 md:grid-cols-4">
        <Card>
          <CardHeader className="pb-2"><CardTitle className="text-xs text-muted-foreground">Active (7d)</CardTitle></CardHeader>
          <CardContent className="text-2xl font-bold">{data.activeCharacters7d.toLocaleString()}</CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2"><CardTitle className="text-xs text-muted-foreground">Matches (7d)</CardTitle></CardHeader>
          <CardContent className="text-2xl font-bold">{data.matchesPlayed7d.toLocaleString()}</CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2"><CardTitle className="text-xs text-muted-foreground">K factor (calibration / default)</CardTitle></CardHeader>
          <CardContent className="text-2xl font-bold">{data.config.kCalibration} / {data.config.kDefault}</CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2"><CardTitle className="text-xs text-muted-foreground">Calibration games</CardTitle></CardHeader>
          <CardContent className="text-2xl font-bold">{data.config.calibrationGames}</CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Rating distribution — active characters</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {data.distribution.map((b) => {
              const pct = (b.count / maxCount) * 100
              const share = data.activeCharacters7d > 0
                ? ((b.count / data.activeCharacters7d) * 100).toFixed(1)
                : '0.0'
              return (
                <div key={b.label} className="flex items-center gap-3">
                  <div className="w-20 text-xs font-mono text-muted-foreground">{b.label}</div>
                  <div className="flex-1 h-6 bg-muted rounded relative overflow-hidden">
                    <div
                      className="h-full bg-blue-500/60"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                  <div className="w-24 text-xs text-right text-muted-foreground">
                    {b.count.toLocaleString()} ({share}%)
                  </div>
                </div>
              )
            })}
          </div>
        </CardContent>
      </Card>

      <p className="text-xs text-muted-foreground">
        Read-only Phase 1. Balance notes in{' '}
        <code>docs/06_game_systems/BALANCE_CONSTANTS.md</code> §ELO. Starting
        rating is <code>1000</code> (Character schema default).
      </p>
    </div>
  )
}
