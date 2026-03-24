import { NextRequest, NextResponse } from 'next/server'
import { createAdminClient } from '@/lib/supabase/server'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'

/**
 * POST /api/auth/login
 *
 * Logs in a user via Supabase Auth (email + password).
 * Auto-confirms unverified emails so users don't get stuck.
 * Returns access_token, refresh_token, and user data.
 *
 * Body: { email, password }
 */
export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const { email, password } = body

    const ip = req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || 'unknown'
    if (!(await rateLimit('login:' + ip, 10, 60_000))) {
      return NextResponse.json(
        { error: 'Too many requests. Please try again later.' },
        { status: 429 }
      )
    }

    if (!email || !password) {
      return NextResponse.json(
        { error: 'email and password are required' },
        { status: 400 }
      )
    }

    const supabase = createAdminClient()

    // First attempt to sign in
    let { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    // If email not confirmed, auto-confirm and retry
    if (error && error.message?.toLowerCase().includes('not confirmed')) {
      console.log('login: user email not confirmed — auto-confirming...')

      // Look up user in our DB to get their Supabase user ID
      const dbUser = await prisma.user.findFirst({ where: { email } })
      if (dbUser) {
        await supabase.auth.admin.updateUserById(dbUser.id, { email_confirm: true })
        // Retry sign in
        const retry = await supabase.auth.signInWithPassword({ email, password })
        data = retry.data
        error = retry.error
      }
      // If user is not in our DB, we can't auto-confirm — they'll get a generic error
    }

    if (error || !data?.session) {
      return NextResponse.json(
        { error: error?.message ?? 'Invalid credentials' },
        { status: 401 }
      )
    }

    // Ensure user record exists in our database
    try {
      await prisma.user.upsert({
        where: { id: data.user.id },
        update: { lastLogin: new Date() },
        create: {
          id: data.user.id,
          email: data.user.email ?? email,
          username: email.split('@')[0],
          authProvider: 'email',
        },
      })
    } catch (dbErr) {
      console.warn('login db upsert warning:', dbErr)
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
    console.error('login error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
