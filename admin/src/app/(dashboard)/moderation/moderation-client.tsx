'use client'

import { useState, useTransition } from 'react'
import { resolveReport, type ReportAction } from '@/actions/moderation'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Textarea } from '@/components/ui/textarea'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'

export type ReportRow = {
  id: string
  category: string
  reason: string | null
  contextType: string
  snapshot: string | null
  status: string
  resolution: string | null
  createdAt: string
  resolvedAt: string | null
  reporter: { userId: string; username: string | null; characterName: string | null }
  target: { userId: string; username: string | null; characterName: string | null; level: number | null; isBanned: boolean; totalReports: number }
}

const CATEGORY_LABEL: Record<string, string> = {
  harassment: 'Harassment',
  hate: 'Hate speech',
  spam: 'Spam',
  cheating: 'Cheating',
  inappropriate_name: 'Inappropriate name',
  other: 'Other',
}

function ReportCard({ r }: { r: ReportRow }) {
  const [note, setNote] = useState('')
  const [pending, start] = useTransition()
  const [error, setError] = useState<string | null>(null)
  const [done, setDone] = useState<string | null>(null)

  const act = (action: ReportAction) => {
    if (action === 'ban' && !window.confirm(`Ban ${r.target.characterName ?? r.target.userId}? This blocks their account.`)) return
    setError(null)
    start(async () => {
      try {
        await resolveReport(r.id, action, note)
        setDone(action)
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Failed')
      }
    })
  }

  return (
    <Card className={done ? 'opacity-60' : undefined}>
      <CardHeader className="pb-2">
        <CardTitle className="flex flex-wrap items-center gap-2 text-base">
          <Badge variant={r.category === 'hate' || r.category === 'harassment' ? 'destructive' : 'secondary'}>
            {CATEGORY_LABEL[r.category] ?? r.category}
          </Badge>
          <span>
            <strong>{r.target.characterName ?? '—'}</strong>
            {r.target.level !== null && <span className="text-muted-foreground"> · L{r.target.level}</span>}
            {r.target.isBanned && <Badge variant="destructive" className="ml-2">banned</Badge>}
          </span>
          <span className="text-muted-foreground text-xs">
            {r.target.totalReports} report{r.target.totalReports === 1 ? '' : 's'} total · via {r.contextType} · {new Date(r.createdAt).toLocaleString()}
          </span>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3 text-sm">
        {r.snapshot && (
          <div className="rounded border bg-muted/40 p-2">
            <div className="text-muted-foreground text-xs mb-1">{r.contextType === 'message' ? 'Reported message' : 'Name at report time'}</div>
            <div className="break-words">{r.snapshot}</div>
          </div>
        )}
        {r.reason && <div><span className="text-muted-foreground">Reporter says:</span> {r.reason}</div>}
        <div className="text-muted-foreground text-xs">
          Reported by {r.reporter.characterName ?? r.reporter.username ?? r.reporter.userId}
        </div>
        {done ? (
          <div className="text-xs text-muted-foreground">Resolved: {done}</div>
        ) : (
          <>
            <Textarea placeholder="Resolution note (shown in the audit log; ban reason when banning)" value={note} onChange={(e) => setNote(e.target.value)} rows={2} />
            <div className="flex flex-wrap gap-2">
              <Button size="sm" variant="outline" disabled={pending} onClick={() => act('dismiss')}>Dismiss</Button>
              <Button size="sm" variant="secondary" disabled={pending} onClick={() => act('warn')}>Mark actioned (warned)</Button>
              <Button size="sm" variant="destructive" disabled={pending || r.target.isBanned} onClick={() => act('ban')}>Ban user</Button>
            </div>
            {error && <div className="text-destructive text-xs">{error}</div>}
          </>
        )}
      </CardContent>
    </Card>
  )
}

export function ModerationClient({ open, recent }: { open: ReportRow[]; recent: ReportRow[] }) {
  return (
    <div className="space-y-8">
      <section className="space-y-3">
        <h2 className="text-lg font-semibold">Open ({open.length})</h2>
        {open.length === 0 && <p className="text-muted-foreground text-sm">Queue is empty.</p>}
        {open.map((r) => <ReportCard key={r.id} r={r} />)}
      </section>

      <section className="space-y-3">
        <h2 className="text-lg font-semibold">Recently resolved</h2>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>When</TableHead>
              <TableHead>Target</TableHead>
              <TableHead>Category</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Resolution</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {recent.length === 0 && <TableRow><TableCell colSpan={5} className="text-muted-foreground">Nothing resolved yet</TableCell></TableRow>}
            {recent.map((r) => (
              <TableRow key={r.id}>
                <TableCell className="whitespace-nowrap">{r.resolvedAt ? new Date(r.resolvedAt).toLocaleString() : '—'}</TableCell>
                <TableCell>{r.target.characterName ?? r.target.userId}</TableCell>
                <TableCell>{CATEGORY_LABEL[r.category] ?? r.category}</TableCell>
                <TableCell><Badge variant={r.status === 'actioned' ? 'destructive' : 'outline'}>{r.status}</Badge></TableCell>
                <TableCell className="max-w-md truncate">{r.resolution ?? ''}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </section>
    </div>
  )
}
