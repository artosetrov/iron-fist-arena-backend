import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { REPORT_CATEGORIES, REPORT_CONTEXTS, type ReportCategory, type ReportContext } from '@/lib/moderation'

/**
 * POST /api/social/report
 * Body: { character_id, target_id, category, reason?, context_type?, context_id? }
 *
 * Files a UGC report against another player (by character id). One open
 * report per reporter→target per 24 h; 10 reports per reporter per hour.
 * Snapshot of the target's current name (and the message text when
 * context_type=message) is stored so moderators see what was reported even
 * if it changes later.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`report:${user.id}`, 10, 60 * 60_000))) {
    return NextResponse.json({ error: 'Too many reports. Try again later.' }, { status: 429 })
  }

  try {
    const body = (await req.json()) as {
      character_id?: string
      target_id?: string
      category?: string
      reason?: string
      context_type?: string
      context_id?: string
    }
    const { character_id, target_id } = body
    if (!character_id || !target_id) {
      return NextResponse.json({ error: 'character_id and target_id are required' }, { status: 400 })
    }
    if (!body.category || !(REPORT_CATEGORIES as readonly string[]).includes(body.category)) {
      return NextResponse.json({ error: `category must be one of ${REPORT_CATEGORIES.join(', ')}` }, { status: 400 })
    }
    const category = body.category as ReportCategory
    const contextType: ReportContext =
      body.context_type && (REPORT_CONTEXTS as readonly string[]).includes(body.context_type)
        ? (body.context_type as ReportContext)
        : 'profile'
    const reason = typeof body.reason === 'string' ? body.reason.trim().slice(0, 500) : null

    const [reporter, target] = await Promise.all([
      prisma.character.findUnique({ where: { id: character_id }, select: { id: true, userId: true } }),
      prisma.character.findUnique({ where: { id: target_id }, select: { id: true, userId: true, characterName: true } }),
    ])
    if (!reporter) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (reporter.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    if (!target) return NextResponse.json({ error: 'Target not found' }, { status: 404 })
    if (target.userId === user.id) return NextResponse.json({ error: 'Cannot report yourself' }, { status: 400 })

    // Snapshot: message text when reporting a message the reporter received.
    let snapshot: string | null = target.characterName
    if (contextType === 'message' && body.context_id) {
      const msg = await prisma.directMessage.findFirst({
        where: { id: body.context_id, senderId: target_id, receiverId: character_id },
        select: { content: true },
      })
      if (msg) snapshot = msg.content.slice(0, 500)
    }

    const dayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000)
    const duplicate = await prisma.userReport.findFirst({
      where: { reporterUserId: user.id, targetUserId: target.userId, status: 'open', createdAt: { gte: dayAgo } },
      select: { id: true },
    })
    if (duplicate) {
      return NextResponse.json({ reported: true, reportId: duplicate.id, duplicate: true })
    }

    const report = await prisma.userReport.create({
      data: {
        reporterUserId: user.id,
        reporterCharacterId: character_id,
        targetUserId: target.userId,
        targetCharacterId: target_id,
        category,
        reason,
        contextType,
        contextId: body.context_id ?? null,
        snapshot,
      },
      select: { id: true },
    })

    return NextResponse.json({ reported: true, reportId: report.id, duplicate: false })
  } catch (error) {
    console.error('social report error:', error)
    return NextResponse.json({ error: 'Failed to submit report' }, { status: 500 })
  }
}
