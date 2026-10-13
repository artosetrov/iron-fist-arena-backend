import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/cron/push-scheduled — Vercel Cron (see backend/vercel.json).
 *
 * Sends every PushCampaign whose `scheduledAt` has passed, by calling the
 * same admin send route the panel uses. Auth: `Authorization: Bearer
 * <CRON_SECRET>` (Vercel injects it for cron invocations).
 */
export async function GET(req: NextRequest) {
  const secret = process.env.CRON_SECRET
  const auth = req.headers.get('authorization')
  if (!secret || auth !== `Bearer ${secret}`) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const due = await prisma.pushCampaign.findMany({
      where: { status: { in: ['draft', 'scheduled'] }, scheduledAt: { lte: new Date() } },
      select: { id: true },
      take: 20,
    })

    const results: Array<{ id: string; status: string; sent?: number; failed?: number }> = []
    for (const c of due) {
      // Claim atomically so an overlapping cron tick cannot double-send.
      const claimed = await prisma.pushCampaign.updateMany({
        where: { id: c.id, status: { in: ['draft', 'scheduled'] } },
        data: { status: 'sending' },
      })
      if (claimed.count !== 1) continue

      const campaign = await prisma.pushCampaign.findUnique({ where: { id: c.id } })
      if (!campaign) continue

      const { sendPushBroadcast, sendPushToUsers } = await import('@/lib/push/send')
      const payload = {
        title: campaign.title,
        body: campaign.body,
        data: (campaign.data ?? undefined) as Record<string, unknown> | undefined,
      }
      const filter = (campaign.targetFilter ?? {}) as { minLevel?: number; maxLevel?: number; class?: string; userIds?: string[] }

      let r: { sent: number; failed: number }
      if (campaign.targetType === 'user' && Array.isArray(filter.userIds) && filter.userIds.length > 0) {
        r = await sendPushToUsers(filter.userIds, payload, campaign.id)
      } else if (campaign.targetType === 'segment') {
        r = await sendPushBroadcast(payload, campaign.id, {
          minLevel: filter.minLevel,
          maxLevel: filter.maxLevel,
          class: filter.class as never,
        })
      } else {
        r = await sendPushBroadcast(payload, campaign.id)
      }

      const status = r.sent === 0 && r.failed > 0 ? 'failed' : 'sent'
      await prisma.pushCampaign.update({
        where: { id: campaign.id },
        data: { status, sentCount: r.sent, failCount: r.failed, sentAt: new Date() },
      })
      results.push({ id: campaign.id, status, sent: r.sent, failed: r.failed })
    }

    return NextResponse.json({ processed: results.length, results })
  } catch (error) {
    console.error('cron push-scheduled error:', error)
    return NextResponse.json({ error: 'Internal error' }, { status: 500 })
  }
}
