import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const { email, username } = await req.json()

    if (!email || !username) {
      return NextResponse.json(
        { error: 'email and username are required' },
        { status: 400 }
      )
    }

    const emailOwner = await prisma.user.findUnique({
      where: { email },
      select: { id: true },
    })

    if (emailOwner && emailOwner.id !== user.id) {
      return NextResponse.json(
        { error: 'Email already registered with another account.' },
        { status: 409 }
      )
    }

    const dbUser = await prisma.user.upsert({
      where: { id: user.id },
      update: {
        email,
        username,
        lastLogin: new Date(),
      },
      create: {
        id: user.id,
        email,
        username,
        authProvider: user.app_metadata?.provider ?? 'email',
      },
    })

    return NextResponse.json({ user: dbUser })
  } catch (error) {
    console.error('sync-user error:', error)
    return NextResponse.json(
      { error: 'Failed to sync user' },
      { status: 500 }
    )
  }
}
