'use server'

import { revalidatePath } from 'next/cache'
import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'
import { auditLog } from '@/lib/audit-log'

export type ReportStatus = 'open' | 'reviewed' | 'actioned' | 'dismissed'
export type ReportAction = 'dismiss' | 'warn' | 'ban'

/**
 * Resolve a UGC report. Moderators may do this (it IS their job); a ban also
 * writes users.is_banned + AdminLog so it shows in the player's history.
 */
export async function resolveReport(id: string, action: ReportAction, resolution?: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')

  const report = await prisma.userReport.findUnique({ where: { id } })
  if (!report) throw new Error('Report not found')
  if (report.status !== 'open' && report.status !== 'reviewed') throw new Error('Report already resolved')

  const note = (resolution ?? '').trim().slice(0, 500) || null
  const status: ReportStatus = action === 'dismiss' ? 'dismissed' : 'actioned'

  await prisma.$transaction(async (tx) => {
    await tx.userReport.update({
      where: { id },
      data: { status, resolution: note ?? (action === 'ban' ? 'banned' : action), resolvedBy: admin.id, resolvedAt: new Date() },
    })
    if (action === 'ban') {
      await tx.user.update({
        where: { id: report.targetUserId },
        data: { isBanned: true, banReason: note ?? `Report ${report.category} (${report.id})` },
      })
      // Close every other open report on the same user — the ban covers them.
      await tx.userReport.updateMany({
        where: { targetUserId: report.targetUserId, status: 'open', id: { not: id } },
        data: { status: 'actioned', resolution: `banned via report ${id}`, resolvedBy: admin.id, resolvedAt: new Date() },
      })
    }
    await tx.adminLog.create({
      data: {
        adminId: admin.id,
        action: `report_${action}`,
        target: `user/${report.targetUserId}`,
        details: { reportId: id, category: report.category, note },
      },
    })
  })

  auditLog(admin, `report_${action}`, `report/${id}`, { target: report.targetUserId })
  revalidatePath('/moderation')
  return { success: true }
}
