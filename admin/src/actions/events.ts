'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'
import { auditLog } from '@/lib/audit-log'
import type { EventType } from '@prisma/client'

export async function getEvents() {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return prisma.event.findMany({
    orderBy: { startAt: 'desc' },
  })
}

export async function createEvent(data: {
  eventKey: string
  title: string
  description: string
  eventType: EventType
  config: unknown
  startAt: Date | string
  endAt: Date | string
}) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const event = await prisma.event.create({
    data: {
      eventKey: data.eventKey,
      title: data.title,
      description: data.description,
      eventType: data.eventType,
      config: data.config as never,
      startAt: new Date(data.startAt),
      endAt: new Date(data.endAt),
    },
  })
  auditLog(admin, 'create_event', `event/${event.id}`, {
    eventKey: data.eventKey,
    title: data.title,
    eventType: data.eventType,
  })
  return event
}

export async function updateEvent(
  id: string,
  data: {
    eventKey?: string
    title?: string
    description?: string
    eventType?: EventType
    config?: unknown
    startAt?: Date | string
    endAt?: Date | string
    isActive?: boolean
  }
) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const updateData: Record<string, unknown> = {}
  if (data.eventKey !== undefined) updateData.eventKey = data.eventKey
  if (data.title !== undefined) updateData.title = data.title
  if (data.description !== undefined) updateData.description = data.description
  if (data.eventType !== undefined) updateData.eventType = data.eventType
  if (data.config !== undefined) updateData.config = data.config
  if (data.startAt !== undefined) updateData.startAt = new Date(data.startAt)
  if (data.endAt !== undefined) updateData.endAt = new Date(data.endAt)
  if (data.isActive !== undefined) updateData.isActive = data.isActive

  const updated = await prisma.event.update({
    where: { id },
    data: updateData,
  })
  auditLog(admin, 'update_event', `event/${id}`, {
    updatedFields: Object.keys(updateData),
  })
  return updated
}

export async function deleteEvent(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  // Fetch the event title before deleting so we can include it in the audit log.
  const event = await prisma.event.findUnique({ where: { id }, select: { title: true, eventKey: true } })
  await prisma.event.delete({ where: { id } })
  auditLog(admin, 'delete_event', `event/${id}`, {
    eventKey: event?.eventKey,
    title: event?.title,
  })
  return { success: true }
}

export async function toggleEventActive(id: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const event = await prisma.event.findUnique({ where: { id } })
  if (!event) throw new Error('Event not found')

  const updated = await prisma.event.update({
    where: { id },
    data: { isActive: !event.isActive },
  })
  auditLog(admin, 'toggle_event_active', `event/${id}`, {
    eventKey: event.eventKey,
    isActive: updated.isActive,
  })
  return updated
}
