import { requireAdmin } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'

export const dynamic = 'force-dynamic'

type CountRow = { name: string; count: bigint }
type DayRow = { day: Date; users: bigint }
type RetentionRow = { cohort_users: bigint; d1: bigint; d7: bigint }

const FUNNEL: { name: string; label: string }[] = [
  { name: 'signup', label: 'Signed up' },
  { name: 'tutorial_complete', label: 'Finished tutorial' },
  { name: 'first_pvp', label: 'First PvP' },
  { name: 'daily_login', label: 'Claimed a daily login' },
  { name: 'level_up', label: 'Levelled up' },
  { name: 'iap_started', label: 'Opened a purchase' },
  { name: 'iap_purchase', label: 'Paid' },
]

async function loadData() {
  const since7 = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
  const since30 = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)

  const [counts7, counts30, dau, funnelRows, retention, total] = await Promise.all([
    prisma.$queryRaw<CountRow[]>`
      SELECT name, COUNT(*)::bigint AS count FROM analytics_events
      WHERE created_at >= ${since7} GROUP BY name ORDER BY count DESC`,
    prisma.$queryRaw<CountRow[]>`
      SELECT name, COUNT(*)::bigint AS count FROM analytics_events
      WHERE created_at >= ${since30} GROUP BY name ORDER BY count DESC`,
    prisma.$queryRaw<DayRow[]>`
      SELECT date_trunc('day', created_at) AS day, COUNT(DISTINCT user_id)::bigint AS users
      FROM analytics_events
      WHERE created_at >= ${new Date(Date.now() - 14 * 24 * 60 * 60 * 1000)} AND user_id IS NOT NULL
      GROUP BY 1 ORDER BY 1 DESC`,
    // Funnel over the last-30-day signup cohort: how many of those users
    // ever emitted each downstream event.
    prisma.$queryRaw<CountRow[]>`
      WITH cohort AS (
        SELECT DISTINCT user_id FROM analytics_events
        WHERE name = 'signup' AND created_at >= ${since30} AND user_id IS NOT NULL
      )
      SELECT e.name, COUNT(DISTINCT e.user_id)::bigint AS count
      FROM analytics_events e JOIN cohort c ON c.user_id = e.user_id
      WHERE e.name IN ('signup','tutorial_complete','first_pvp','daily_login','level_up','iap_started','iap_purchase')
      GROUP BY e.name`,
    // D1 / D7: users who signed up 8–30 days ago and had ANY event on day +1 / +7.
    prisma.$queryRaw<RetentionRow[]>`
      WITH cohort AS (
        SELECT user_id, MIN(date_trunc('day', created_at)) AS d0
        FROM analytics_events
        WHERE name = 'signup' AND user_id IS NOT NULL
          AND created_at >= ${since30} AND created_at < ${new Date(Date.now() - 8 * 24 * 60 * 60 * 1000)}
        GROUP BY user_id
      )
      SELECT
        COUNT(*)::bigint AS cohort_users,
        COUNT(*) FILTER (WHERE EXISTS (
          SELECT 1 FROM analytics_events e WHERE e.user_id = c.user_id
            AND date_trunc('day', e.created_at) = c.d0 + INTERVAL '1 day'))::bigint AS d1,
        COUNT(*) FILTER (WHERE EXISTS (
          SELECT 1 FROM analytics_events e WHERE e.user_id = c.user_id
            AND date_trunc('day', e.created_at) = c.d0 + INTERVAL '7 day'))::bigint AS d7
      FROM cohort c`,
    prisma.analyticsEvent.count(),
  ])

  const to = (rows: CountRow[]) => Object.fromEntries(rows.map((r) => [r.name, Number(r.count)]))
  return {
    total,
    counts7: to(counts7),
    counts30: to(counts30),
    dau: dau.map((d) => ({ day: d.day.toISOString().slice(0, 10), users: Number(d.users) })),
    funnel: to(funnelRows),
    retention: retention[0]
      ? { cohort: Number(retention[0].cohort_users), d1: Number(retention[0].d1), d7: Number(retention[0].d7) }
      : { cohort: 0, d1: 0, d7: 0 },
  }
}

function pct(n: number, d: number) {
  return d > 0 ? `${((100 * n) / d).toFixed(1)}%` : '—'
}

export default async function AnalyticsPage() {
  await requireAdmin()
  const data = await loadData()
  const names = Array.from(new Set([...Object.keys(data.counts30), ...Object.keys(data.counts7)])).sort()
  const signups = data.funnel.signup ?? 0

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Analytics</h1>
        <p className="text-muted-foreground">
          Product events from <code>analytics_events</code> — server-side funnel events plus iOS client
          events. {data.total.toLocaleString()} events stored.
          {data.total === 0 && ' Nothing yet: the table fills once the backend with persistence is deployed.'}
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader>
            <CardTitle>Retention</CardTitle>
            <CardDescription>Signup cohort 8–30 days old ({data.retention.cohort} users)</CardDescription>
          </CardHeader>
          <CardContent className="space-y-1 text-sm">
            <div>D1: <strong>{pct(data.retention.d1, data.retention.cohort)}</strong></div>
            <div>D7: <strong>{pct(data.retention.d7, data.retention.cohort)}</strong></div>
          </CardContent>
        </Card>

        <Card className="md:col-span-2">
          <CardHeader>
            <CardTitle>Daily active users</CardTitle>
            <CardDescription>Distinct users with any event, last 14 days</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-2 text-sm">
              {data.dau.length === 0 && <span className="text-muted-foreground">No data</span>}
              {data.dau.map((d) => (
                <div key={d.day} className="rounded border px-2 py-1">
                  <div className="text-muted-foreground text-xs">{d.day}</div>
                  <div className="font-semibold">{d.users}</div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Funnel — last 30 days signup cohort</CardTitle>
          <CardDescription>Users from the cohort who ever reached each step</CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Step</TableHead>
                <TableHead className="text-right">Users</TableHead>
                <TableHead className="text-right">% of signups</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {FUNNEL.map((f) => (
                <TableRow key={f.name}>
                  <TableCell>{f.label} <code className="text-muted-foreground text-xs">{f.name}</code></TableCell>
                  <TableCell className="text-right">{data.funnel[f.name] ?? 0}</TableCell>
                  <TableCell className="text-right">{pct(data.funnel[f.name] ?? 0, signups)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Event volume</CardTitle>
          <CardDescription>All event names, 7 vs 30 days</CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Event</TableHead>
                <TableHead className="text-right">7d</TableHead>
                <TableHead className="text-right">30d</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {names.length === 0 && (
                <TableRow><TableCell colSpan={3} className="text-muted-foreground">No events yet</TableCell></TableRow>
              )}
              {names.map((n) => (
                <TableRow key={n}>
                  <TableCell><code>{n}</code></TableCell>
                  <TableCell className="text-right">{data.counts7[n] ?? 0}</TableCell>
                  <TableCell className="text-right">{data.counts30[n] ?? 0}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
