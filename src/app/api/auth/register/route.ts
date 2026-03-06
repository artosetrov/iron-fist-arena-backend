import { NextRequest, NextResponse } from 'next/server'
import { createAdminClient } from '@/lib/supabase/server'
import { prisma } from '@/lib/prisma'

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

    // Create user via admin API — auto-confirms email
    const { data: signUpData, error: signUpError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { username: username ?? email.split('@')[0] },
    })

    if (signUpError || !signUpData.user) {
      console.error('register error:', signUpError)

      // Handle duplicate email
      if (signUpError?.message?.includes('already been registered')) {
        return NextResponse.json(
          { error: 'Email already registered. Please login instead.' },
          { status: 409 }
        )
      }

      return NextResponse.json(
        { error: signUpError?.message ?? 'Registration failed' },
        { status: 500 }
      )
    }

    // Sign in to get tokens
    const { data: signInData, error: signInError } =
      await supabase.auth.signInWithPassword({ email, password })

    if (signInError || !signInData.session) {
      console.error('register signin error:', signInError)
      return NextResponse.json(
        { error: signInError?.message ?? 'Failed to sign in after registration' },
        { status: 500 }
      )
    }

    // Create user record in our database
    const displayName = username ?? email.split('@')[0]
    try {
      await prisma.user.create({
        data: {
          id: signUpData.user.id,
          username: displayName,
          email,
          authProvider: 'email',
        },
      })
    } catch (dbErr) {
      console.warn('register db create warning:', dbErr)
    }

    return NextResponse.json({
      access_token: signInData.session.access_token,
      refresh_token: signInData.session.refresh_token,
      expires_in: signInData.session.expires_in,
      user: {
        id: signUpData.user.id,
        email,
        role: signUpData.user.role,
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
