import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'

const ROLE_VALUES = ['admin', 'moderator', 'developer', 'player'] as const

const roleUpdateSchema = z.object({
  userId: z.string().min(1, 'Missing userId'),
  role: z.enum(ROLE_VALUES, { errorMap: () => ({ message: 'Invalid role' }) }),
})

export async function PUT(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  if (admin.role !== 'admin') {
    return NextResponse.json({ error: 'Only admins can change roles' }, { status: 403 })
  }

  try {
    const parsedBody = roleUpdateSchema.safeParse(await req.json())
    if (!parsedBody.success) {
      const message = parsedBody.error.issues[0]?.message ?? 'Invalid request body'
      return NextResponse.json({ error: message }, { status: 400 })
    }

    const { userId, role } = parsedBody.data

    const result = await prisma.$transaction(async (tx) => {
      const targetUser = await tx.user.findUnique({
        where: { id: userId },
        select: { id: true, role: true, email: true, username: true },
      })

      if (!targetUser) {
        return { status: 404, body: { error: 'User not found' } }
      }

      if (targetUser.role === role) {
        return {
          status: 200,
          body: { success: true, changed: false, role: targetUser.role },
        }
      }

      if (targetUser.id === admin.id && role !== 'admin') {
        return {
          status: 409,
          body: { error: 'You cannot remove your own admin role' },
        }
      }

      if (targetUser.role === 'admin' && role !== 'admin') {
        const adminRows = await tx.$queryRaw<Array<{ id: string }>>`
          SELECT id
          FROM users
          WHERE role = 'admin'
          FOR UPDATE
        `

        if (adminRows.length <= 1) {
          return {
            status: 409,
            body: { error: 'Cannot remove the last remaining admin' },
          }
        }
      }

      const updatedUser = await tx.user.update({
        where: { id: userId },
        data: { role },
        select: { id: true, role: true, email: true, username: true },
      })

      await tx.adminLog.create({
        data: {
          adminId: admin.id,
          action: 'user.role.update',
          target: updatedUser.id,
          details: {
            from: targetUser.role,
            to: updatedUser.role,
            email: updatedUser.email,
            username: updatedUser.username,
          },
        },
      })

      return {
        status: 200,
        body: { success: true, changed: true, role: updatedUser.role },
      }
    })

    return NextResponse.json(result.body, { status: result.status })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to update role'
    return NextResponse.json({ error: message }, { status: 400 })
  }
}
