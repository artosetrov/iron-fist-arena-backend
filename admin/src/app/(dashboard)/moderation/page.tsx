import { requireAdmin } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { ModerationClient, type ReportRow } from './moderation-client'

export const dynamic = 'force-dynamic'

async function loadReports(): Promise<{ open: ReportRow[]; recent: ReportRow[]; openCount: number }> {
  const [open, recent, openCount] = await Promise.all([
    prisma.userReport.findMany({ where: { status: 'open' }, orderBy: { createdAt: 'asc' }, take: 200 }),
    prisma.userReport.findMany({ where: { status: { not: 'open' } }, orderBy: { resolvedAt: 'desc' }, take: 50 }),
    prisma.userReport.count({ where: { status: 'open' } }),
  ])

  const userIds = Array.from(new Set([...open, ...recent].flatMap((r) => [r.reporterUserId, r.targetUserId])))
  const charIds = Array.from(new Set([...open, ...recent].flatMap((r) => [r.reporterCharacterId, r.targetCharacterId]).filter((x): x is string => !!x)))
  const [users, chars, priorCounts] = await Promise.all([
    prisma.user.findMany({ where: { id: { in: userIds } }, select: { id: true, username: true, isBanned: true } }),
    prisma.character.findMany({ where: { id: { in: charIds } }, select: { id: true, characterName: true, level: true } }),
    prisma.userReport.groupBy({ by: ['targetUserId'], _count: true, where: { targetUserId: { in: userIds } } }),
  ])
  const userMap = new Map(users.map((u) => [u.id, u]))
  const charMap = new Map(chars.map((c) => [c.id, c]))
  const priorMap = new Map(priorCounts.map((p) => [p.targetUserId, p._count]))

  const toRow = (r: (typeof open)[number]): ReportRow => ({
    id: r.id,
    category: r.category,
    reason: r.reason,
    contextType: r.contextType,
    snapshot: r.snapshot,
    status: r.status,
    resolution: r.resolution,
    createdAt: r.createdAt.toISOString(),
    resolvedAt: r.resolvedAt?.toISOString() ?? null,
    reporter: {
      userId: r.reporterUserId,
      username: userMap.get(r.reporterUserId)?.username ?? null,
      characterName: r.reporterCharacterId ? charMap.get(r.reporterCharacterId)?.characterName ?? null : null,
    },
    target: {
      userId: r.targetUserId,
      username: userMap.get(r.targetUserId)?.username ?? null,
      characterName: r.targetCharacterId ? charMap.get(r.targetCharacterId)?.characterName ?? null : null,
      level: r.targetCharacterId ? charMap.get(r.targetCharacterId)?.level ?? null : null,
      isBanned: userMap.get(r.targetUserId)?.isBanned ?? false,
      totalReports: priorMap.get(r.targetUserId) ?? 0,
    },
  })

  return { open: open.map(toRow), recent: recent.map(toRow), openCount }
}

export default async function ModerationPage() {
  await requireAdmin()
  const data = await loadReports()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Moderation</h1>
        <p className="text-muted-foreground">
          Player reports from the app (names, messages, behaviour). {data.openCount} open. Dismiss, warn, or ban;
          a ban sets <code>users.is_banned</code> and closes the user&apos;s other open reports.
        </p>
      </div>
      <ModerationClient open={data.open} recent={data.recent} />
    </div>
  )
}
