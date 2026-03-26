import { NextRequest, NextResponse } from 'next/server'
import { createAdminClient } from '@/lib/supabase/server'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'

/**
 * POST /api/auth/google
 *
 * Sign in with Google using the ID token from Google Sign-In SDK.
 * Supabase verifies the Google JWT and creates/finds the user.
 * Returns access_token, refresh_token, and user data.
 *
 * Body: { id_token: string, access_token?: string }
 */
export async function POST(req: NextRequest) {
  try {
    // Rate limit: 5 requests per minute per IP
    const ip = req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || 'unknown'
    const allowed = await rateLimit(`google-auth:${ip}`, 5, 60_000)
    if (!allowed) {
      return NextResponse.json(
        { error: 'Too many requests. Please try again later.' },
        { status: 429 }
      )
    }

    const body = await req.json()
    const { id_token, access_token: googleAccessToken } = body

    if (!id_token) {
      return NextResponse.json(
        { error: 'id_token is required' },
        { status: 400 }
      )
    }

    const supabase = createAdminClient()

    // Use signInWithIdToken for native Google Sign-In (iOS/Android)
    const { data, error } = await supabase.auth.signInWithIdToken({
      provider: 'google',
      token: id_token,
      ...(googleAccessToken ? { access_token: googleAccessToken } : {}),
    })

    if (error || !data?.session) {
      console.error('google auth error:', error)
      return NextResponse.json(
        { error: error?.message ?? 'Google Sign In failed' },
        { status: 401 }
      )
    }

    // Ensure user record exists in our database
    try {
      const email = data.user.email ?? ''
      const fullName = data.user.user_metadata?.full_name ?? ''
      await prisma.user.upsert({
        where: { id: data.user.id },
        update: { lastLogin: new Date() },
        create: {
          id: data.user.id,
          email,
          username: fullName || email.split('@')[0] || `google_${data.user.id.slice(0, 8)}`,
          authProvider: 'google',
        },
      })
    } catch (dbErr) {
      console.warn('google auth db upsert warning:', dbErr)
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
    console.error('google auth error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
