import { NextRequest, NextResponse } from 'next/server'
import { getSupabaseAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const user = await getSupabaseAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const existing = await prisma.user.findUnique({ where: { id: user.id } })
    if (existing) {
      if (existing.isBanned) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
      }

      return NextResponse.json({ user: existing })
    }

    const randomDigits = Math.floor(1000 + Math.random() * 9000)
    const guestUsername = `Guest${randomDigits}`

    let dbUser
    try {
      dbUser = await prisma.user.create({
        data: {
          id: user.id,
          email: user.email ?? undefined,
          username: guestUsername,
          authProvider:
            typeof user.app_metadata?.provider === 'string'
              ? user.app_metadata.provider
              : 'anonymous',
          lastLogin: new Date(),
        },
      })
    } catch (createError) {
      console.warn('guest auth create race warning:', createError)

      const racedUser = await prisma.user.findUnique({ where: { id: user.id } })
      if (racedUser) {
        if (racedUser.isBanned) {
          return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
        }

        return NextResponse.json({ user: racedUser })
      }

      throw createError
    }

    return NextResponse.json({ user: dbUser })
  } catch (error) {
    console.error('guest auth error:', error)
    return NextResponse.json(
      { error: 'Failed to create guest user' },
      { status: 500 }
    )
  }
}
