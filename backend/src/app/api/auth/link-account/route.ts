import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

/**
 * Legacy compatibility surface.
 *
 * This route only syncs local profile fields after an already-authenticated
 * provider link flow. It is not the main guest->email/social upgrade path.
 */
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

    const existing = await prisma.user.findUnique({ where: { id: user.id } })
    if (!existing) {
      return NextResponse.json(
        { error: 'User not found. Create a guest account first.' },
        { status: 404 }
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

    const dbUser = await prisma.user.update({
      where: { id: user.id },
      data: {
        email,
        username,
        authProvider: user.app_metadata?.provider ?? 'email',
        lastLogin: new Date(),
      },
    })

    return NextResponse.json({ user: dbUser })
  } catch (error) {
    console.error('link-account error:', error)
    return NextResponse.json(
      { error: 'Failed to link account' },
      { status: 500 }
    )
  }
}
