import { NextRequest, NextResponse } from 'next/server'
import { createAdminClient } from '@/lib/supabase/server'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'

/**
 * POST /api/auth/register
 *
 * Registers a new user via Supabase Admin API (auto-confirms email).
 * Returns access_token, refresh_token, and user data.
 *
 * Body: { email, password, username }
 */
export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const { email, password, username } = body

    const ip = req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || 'unknown'
    if (!(await rateLimit('register:' + ip, 5, 60_000))) {
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

    if (password.length < 6) {
      return NextResponse.json(
        { error: 'Password must be at least 6 characters' },
        { status: 400 }
      )
    }

    const supabase = createAdminClient()
    const displayName = username ?? email.split('@')[0]

    // Create user via admin API — auto-confirms email (no confirmation needed)
    const { data: createData, error: createError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // auto-confirm
      user_metadata: { username: displayName },
    })

    if (createError || !createData.user) {
      console.error('register error:', createError)

      if (createError?.message?.includes('already been registered') || createError?.message?.includes('already registered')) {
        return NextResponse.json(
          { error: 'Email already registered. Please login instead.' },
          { status: 409 }
        )
      }

      return NextResponse.json(
        { error: createError?.message ?? 'Registration failed' },
        { status: 500 }
      )
    }

    // Sign in the user to get session tokens
    const { data: signInData, error: signInError } =
      await supabase.auth.signInWithPassword({
        email,
        password,
      })

    if (signInError || !signInData.session) {
      console.error('register sign-in error:', signInError)
      return NextResponse.json(
        { error: signInError?.message ?? 'Account created but sign-in failed. Please login manually.' },
        { status: 500 }
      )
    }

    // Create user record in our database
    try {
      await prisma.user.create({
        data: {
          id: createData.user.id,
          username: displayName,
          email,
          authProvider: 'email',
        },
      })
    } catch (dbErr) {
      // May fail if user already exists — that's OK
      console.warn('register db create warning:', dbErr)
    }

    return NextResponse.json({
      needs_confirmation: false,
      access_token: signInData.session.access_token,
      refresh_token: signInData.session.refresh_token,
      expires_in: signInData.session.expires_in,
      user: {
        id: createData.user.id,
        email,
        role: createData.user.role,
      },
    })
  } catch (error) {
    console.error('register error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
