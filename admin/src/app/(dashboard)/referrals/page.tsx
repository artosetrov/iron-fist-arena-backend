import { requireAdmin } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

async function loadData() {
  const [claims, total, last7dCount] = await Promise.all([
    prisma.referralRewardClaim.findMany({
      include: {
        referrerCharacter: {
          select: {
            id: true, characterName: true,
            user: { select: { email: true } },
          },
        },
        inviteeCharacter: {
          select: {
            id: true, characterName: true,
            user: { select: { email: true } },
          },
        },
      },
      orderBy: { qualifiedAt: 'desc' },
      take: 200,
    }),
    prisma.referralRewardClaim.count(),
    prisma.referralRewardClaim.count({
      where: { qualifiedAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } },
    }),
  ])

  return { claims, total, last7dCount }
}

function formatDate(d: Date) {
  return d.toLocaleString('en-GB', {
    day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit',
  })
}

export default async function ReferralsPage() {
  await requireAdmin()
  const { claims, total, last7dCount } = await loadData()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Referral Claims</h1>
        <p className="text-muted-foreground">
          Audit log of referrer ↔ invitee qualifications. A claim row is
          written when the invitee hits the qualification threshold
          (see <code>awardReferralQualificationIfEligible</code> in{' '}
          <code>backend/src/lib/game/tutorial.ts</code>).
        </p>
      </div>

      <div className="grid gap-3 grid-cols-3">
        <Card>
          <CardHeader className="pb-2"><CardTitle className="text-xs text-muted-foreground">Total claims</CardTitle></CardHeader>
          <CardContent className="text-2xl font-bold">{total.toLocaleString()}</CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2"><CardTitle className="text-xs text-muted-foreground">Last 7 days</CardTitle></CardHeader>
          <CardContent className="text-2xl font-bold">{last7dCount.toLocaleString()}</CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2"><CardTitle className="text-xs text-muted-foreground">Shown</CardTitle></CardHeader>
          <CardContent className="text-2xl font-bold">{claims.length.toLocaleString()}</CardContent>
        </Card>
      </div>

      <div className="rounded-lg border border-border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-muted/50">
            <tr>
              <th className="text-left p-3 font-medium">Referrer</th>
              <th className="text-left p-3 font-medium">Invitee</th>
              <th className="text-left p-3 font-medium">Qualified at</th>
            </tr>
          </thead>
          <tbody>
            {claims.map((c) => (
              <tr key={c.id} className="border-t border-border">
                <td className="p-3">
                  <div className="font-medium">{c.referrerCharacter.characterName}</div>
                  <div className="text-xs text-muted-foreground">
                    {c.referrerCharacter.user?.email ?? c.referrerCharacterId}
                  </div>
                </td>
                <td className="p-3">
                  <div className="font-medium">{c.inviteeCharacter.characterName}</div>
                  <div className="text-xs text-muted-foreground">
                    {c.inviteeCharacter.user?.email ?? c.inviteeCharacterId}
                  </div>
                </td>
                <td className="p-3 text-xs">{formatDate(c.qualifiedAt)}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {claims.length === 0 && (
          <div className="p-8 text-center text-muted-foreground text-sm">
            No referral claims yet.
          </div>
        )}
      </div>

      <p className="text-xs text-muted-foreground">
        Read-only Phase 1. Dispute-resolution / manual-credit actions land in
        Phase 2 behind <code>AdminLog</code> auditing.
      </p>
    </div>
  )
}
