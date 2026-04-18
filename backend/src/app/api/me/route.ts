import { NextRequest, NextResponse } from 'next/server'
import { getSupabaseAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { getPremiumExpiresAt, PREMIUM_ENTITLEMENT_USER_SELECT } from '@/lib/game/premium'

const ME_USER_SELECT = {
  id: true,
  email: true,
  username: true,
  gems: true,
  role: true,
  createdAt: true,
  lastLogin: true,
  isBanned: true,
  ...PREMIUM_ENTITLEMENT_USER_SELECT,
} as const

type MeDbUser = {
  id: string
  email: string | null
  username: string | null
  gems: number
  role: string
  createdAt: Date
  lastLogin: Date | null
  premiumUntil: Date | null
  premiumSubscription: {
    expiresAt: Date
    status: string
  } | null
  isBanned: boolean
}

function serializeMeUser(dbUser: MeDbUser) {
  return {
    id: dbUser.id,
    email: dbUser.email,
    username: dbUser.username,
    gems: dbUser.gems,
    role: dbUser.role,
    createdAt: dbUser.createdAt,
    lastLogin: dbUser.lastLogin,
    premiumUntil: getPremiumExpiresAt(dbUser),
  }
}

export async function GET(req: NextRequest) {
  const user = await getSupabaseAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    let dbUser: MeDbUser | null = await prisma.user.findUnique({
      where: { id: user.id },
      select: ME_USER_SELECT,
    })

    if (dbUser?.isBanned) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    if (!dbUser) {
      if (user.email) {
        const conflictingUser = await prisma.user.findFirst({
          where: {
            email: user.email,
            NOT: { id: user.id },
          },
          select: { id: true },
        })

        if (conflictingUser) {
          return NextResponse.json(
            { error: 'Email already registered with another account.' },
            { status: 409 },
          )
        }
      }

      const usernameFromMetadata =
        typeof user.user_metadata?.username === 'string'
          ? user.user_metadata.username.trim()
          : ''
      const usernameFromEmail = user.email?.split('@')[0]?.trim() ?? ''
      const fallbackUsername =
        usernameFromMetadata || usernameFromEmail || `Guest${Math.floor(1000 + Math.random() * 9000)}`

      try {
        await prisma.user.create({
          data: {
            id: user.id,
            email: user.email ?? undefined,
            username: fallbackUsername,
            authProvider:
              typeof user.app_metadata?.provider === 'string'
                ? user.app_metadata.provider
                : user.email
                  ? 'email'
                  : 'anonymous',
            lastLogin: new Date(),
          },
        })
      } catch (createError) {
        console.warn('me bootstrap create warning:', createError)

        dbUser = await prisma.user.findUnique({
          where: { id: user.id },
          select: ME_USER_SELECT,
        })

        if (!dbUser) {
          return NextResponse.json(
            { error: 'Failed to initialize account' },
            { status: 500 },
          )
        }

        if (dbUser.isBanned) {
          return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
        }
      }

      dbUser ??= await prisma.user.findUnique({
        where: { id: user.id },
        select: ME_USER_SELECT,
      })
    }

    if (!dbUser) {
      return NextResponse.json(
        { error: 'Failed to initialize account' },
        { status: 500 },
      )
    }

    return NextResponse.json({
      user: serializeMeUser(dbUser),
    })
  } catch (error) {
    console.error('me error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch user' },
      { status: 500 }
    )
  }
}
