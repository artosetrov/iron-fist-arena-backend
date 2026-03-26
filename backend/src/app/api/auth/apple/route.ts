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

    // Ensure user record exists in our database
    try {
      const email = data.user.email ?? ''
      await prisma.user.upsert({
        where: { id: data.user.id },
        update: { lastLogin: new Date() },
        create: {
          id: data.user.id,
          email,
          username: email.split('@')[0] || `apple_${data.user.id.slice(0, 8)}`,
          authProvider: 'apple',
        },
      })
    } catch (dbErr) {
      console.warn('apple auth db upsert warning:', dbErr)
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
