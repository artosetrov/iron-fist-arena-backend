import { NextRequest, NextResponse } from 'next/server'
import { createAdminClient } from '@/lib/supabase/server'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'

/**
 * POST /api/auth/apple
 *
 * Sign in with Apple using the identity token from ASAuthorization.
 * Supabase verifies the Apple JWT and creates/finds the user.
 * Returns access_token, refresh_token, and user data.
 *
 * Body: { id_token: string }
 */
export async function POST(req: NextRequest) {
  try {
    // Rate limit: 5 requests per minute per IP
    const ip = req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || 'unknown'
    const allowed = await rateLimit(`apple-auth:${ip}`, 5, 60_000)
    if (!allowed) {
      return NextResponse.json(
        { error: 'Too many requests. Please try again later.' },
        { status: 429 }
      )
    }

    const body = await req.json()
    const { id_token } = body

    if (!id_token) {
      return NextResponse.json(
        { error: 'id_token is required' },
        { status: 400 }
      )
    }

    const supabase = createAdminClient()

    const { data, error } = await supabase.auth.signInWithIdToken({
      provider: 'apple',
      token: id_token,
    })

    if (error || !data?.session) {
      console.error('apple auth error:', error)
      return NextResponse.json(
        { error: error?.message ?? 'Apple Sign In failed' },
        { status: 401 }
      )
    }

    const email = data.user.email ?? ''
    const existingUser = await prisma.user.findUnique({
      where: { id: data.user.id },
      select: { id: true },
    })

    if (existingUser) {
      try {
        await prisma.user.update({
          where: { id: data.user.id },
          data: { lastLogin: new Date() },
        })
      } catch (dbErr) {
        console.warn('apple auth db update warning:', dbErr)
      }
    } else {
      const conflictingUser = email
        ? await prisma.user.findUnique({
            where: { email },
            select: { id: true },
          })
        : null

      if (conflictingUser && conflictingUser.id !== data.user.id) {
        await supabase.auth.admin.deleteUser(data.user.id).catch((deleteErr: unknown) => {
          console.warn('apple auth cleanup warning after duplicate-email collision:', deleteErr)
        })
        return NextResponse.json(
          { error: 'Email already registered with another account. Please log in and link Apple from settings.' },
          { status: 409 }
        )
      }

      try {
        await prisma.user.create({
          data: {
            id: data.user.id,
            email,
            username: email.split('@')[0] || `apple_${data.user.id.slice(0, 8)}`,
            authProvider: 'apple',
          },
        })
      } catch (dbErr) {
        console.error('apple auth db create error:', dbErr)
        await supabase.auth.admin.deleteUser(data.user.id).catch((deleteErr: unknown) => {
          console.warn('apple auth cleanup warning after failed local initialization:', deleteErr)
        })
        return NextResponse.json(
          { error: 'Failed to initialize account' },
          { status: 500 }
        )
      }
    }

    return NextResponse.json({
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      expires_in: data.session.expires_in,
      user: {
        id: data.user.id,
        email: data.user.email,
        role: data.user.role,
      },
    })
  } catch (error) {
    console.error('apple auth error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
