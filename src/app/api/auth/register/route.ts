import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import { createAdminClient } from '@/lib/supabase/server'
import { prisma } from '@/lib/prisma'

/**
 * POST /api/auth/register
 *
 * Registers a new user via Supabase.
 * Sends email confirmation — user must verify before they can log in.
 * Returns { needs_confirmation: true } so the client shows a message.
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

    // Use anon key for signup — this triggers confirmation email
    const supabase = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      { auth: { autoRefreshToken: false, persistSession: false } }
    )

    const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { username: username ?? email.split('@')[0] },
      },
    })

    if (signUpError) {
      console.error('register error:', signUpError)

      if (signUpError.message?.includes('already registered')) {
        return NextResponse.json(
          { error: 'Email already registered. Please login instead.' },
          { status: 409 }
        )
      }

      return NextResponse.json(
        { error: signUpError.message ?? 'Registration failed' },
        { status: 500 }
      )
    }

    // Check if Supabase returned a session (autoconfirm is ON)
    // or needs email confirmation (autoconfirm is OFF — our case)
    if (signUpData.session) {
      // Email autoconfirm is ON — user is immediately authenticated
      // Create user record in our database
      const displayName = username ?? email.split('@')[0]
      try {
        await prisma.user.create({
          data: {
            id: signUpData.user!.id,
            username: displayName,
            email,
            authProvider: 'email',
          },
        })
      } catch (dbErr) {
        console.warn('register db create warning:', dbErr)
      }

      return NextResponse.json({
        needs_confirmation: false,
        access_token: signUpData.session.access_token,
        refresh_token: signUpData.session.refresh_token,
        expires_in: signUpData.session.expires_in,
        user: {
          id: signUpData.user!.id,
          email,
          role: signUpData.user!.role,
        },
      })
    }

    // Email confirmation required — store pending user info
    // User record will be created on first login after confirmation
    if (signUpData.user) {
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
        // May fail if user already exists (re-registration attempt)
        console.warn('register db create warning:', dbErr)
      }
    }

    return NextResponse.json({
      needs_confirmation: true,
      message: 'Please check your email to confirm your account.',
    })
  } catch (error) {
    console.error('register error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
