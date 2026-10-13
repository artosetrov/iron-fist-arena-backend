import { NextRequest, NextResponse } from 'next/server'
import type { CharacterClass } from '@prisma/client'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'
import { sendPushBroadcast, sendPushToUsers } from '@/lib/push/send'

type TargetFilter = {
  minLevel?: number
  maxLevel?: number
  class?: string
  userIds?: string[]
}

const CLASSES = new Set(['warrior', 'rogue', 'mage', 'tank'])

/**
 * POST /api/admin/push/send
 * Body: { campaign_id }
 *
 * Actually delivers a PushCampaign through APNs (lib/push/send.ts) and
 * records sentCount / failCount. The admin panel's "Send" used to mark a
 * campaign `sent` without sending anything (AUDIT-2026-10-13 C5).
 *
 * Status transitions: draft|scheduled|failed → sending → sent|failed.
 * The `sending` claim is a conditional update so two operators cannot send
 * the same campaign twice.
 */
export async function POST(req: NextRequest) {
  const admin = await getAuthAdmin(req)
  if (!admin) return forbiddenResponse()

  try {
    const { campaign_id } = (await req.json()) as { campaign_id?: string }
    if (!campaign_id) {
      return NextResponse.json({ error: 'campaign_id is required' }, { status: 400 })
    }

    const campaign = await prisma.pushCampaign.findUnique({ where: { id: campaign_id } })
    if (!campaign) return NextResponse.json({ error: 'Campaign not found' }, { status: 404 })
    if (campaign.status === 'sent') return NextResponse.json({ error: 'Already sent' }, { status: 409 })

    const claimed = await prisma.pushCampaign.updateMany({
      where: { id: campaign_id, status: { in: ['draft', 'scheduled', 'failed'] } },
      data: { status: 'sending' },
    })
    if (claimed.count !== 1) {
      return NextResponse.json({ error: 'Campaign is already being sent' }, { status: 409 })
    }

    const payload = {
      title: campaign.title,
      body: campaign.body,
      data: (campaign.data ?? undefined) as Record<string, unknown> | undefined,
    }
    const filter = (campaign.targetFilter ?? {}) as TargetFilter

    let result: { sent: number; failed: number; errors: string[] }
    if (campaign.targetType === 'user') {
      const userIds = Array.isArray(filter.userIds) ? filter.userIds.filter((u) => typeof u === 'string') : []
      result = userIds.length > 0
        ? await sendPushToUsers(userIds, payload, campaign.id)
        : { sent: 0, failed: 0, errors: ['No user ids on campaign'] }
    } else if (campaign.targetType === 'segment') {
      result = await sendPushBroadcast(payload, campaign.id, {
        minLevel: typeof filter.minLevel === 'number' ? filter.minLevel : undefined,
        maxLevel: typeof filter.maxLevel === 'number' ? filter.maxLevel : undefined,
        class: typeof filter.class === 'string' && CLASSES.has(filter.class) ? (filter.class as CharacterClass) : undefined,
      })
    } else {
      result = await sendPushBroadcast(payload, campaign.id)
    }

    const status = result.sent === 0 && result.failed > 0 ? 'failed' : 'sent'
    await prisma.pushCampaign.update({
      where: { id: campaign.id },
      data: { status, sentCount: result.sent, failCount: result.failed, sentAt: new Date() },
    })

    return NextResponse.json({
      status,
      sent: result.sent,
      failed: result.failed,
      // Keep the response small; full per-token detail is in push_logs.
      errors: result.errors.slice(0, 20),
    })
  } catch (error) {
    console.error('admin push send error:', error)
    return NextResponse.json({ error: 'Failed to send campaign' }, { status: 500 })
  }
}
