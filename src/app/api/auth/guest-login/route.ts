import { NextResponse } from 'next/server'
import { createAdminClient } from '@/lib/supabase/server'
import { prisma } from '@/lib/prisma'
import crypto from 'crypto'

/**
 * POST /api/auth/guest-login
 *
 * Creates a guest user via Supabase Admin API (no email confirmation needed).
 * Returns access_token, refresh_token, and user data.
 *
 * This endpoint does NOT require authentication —
 * it IS the authentication endpoint for guests.
 */
export async function POST() {
  try {
    const supabase = createAdminClient()

    // Generate a unique guest email that won't conflict
    const guestId = crypto.randomUUID().replace(/-/g, '').substring(0, 12)
    const guestEmail = `guest_${guestId}@guest.ironfist.local`
    const guestPassword = crypto.randomUUID() // random secure password

    // Create user via admin API — auto-confirms email
    const { data: signUpData, error: signUpError } = await supabase.auth.admin.createUser({
      email: guestEmail,
      password: guestPassword,
      email_confirm: true, // auto-confirm
      user_metadata: { is_guest: true },
    })

    if (signUpError || !signUpData.user) {
      console.error('guest signup error:', signUpError)
      return NextResponse.json(
        { error: signUpError?.message ?? 'Failed to create guest account' },
        { status: 500 }
      )
    }

    // Sign in the user to get tokens
    const { data: signInData, error: signInError } =
      await supabase.auth.signInWithPassword({
        email: guestEmail,
        password: guestPassword,
      })

    if (signInError || !signInData.session) {
      console.error('guest signin error:', signInError)
      return NextResponse.json(
        { error: signInError?.message ?? 'Failed to sign in guest' },
        { status: 500 }
      )
    }

    // Create user record in our database
    const randomDigits = Math.floor(1000 + Math.random() * 9000)
    const guestUsername = `Guest${randomDigits}`

    try {
      await prisma.user.create({
        data: {
          id: signUpData.user.id,
          username: guestUsername,
          email: guestEmail,
          authProvider: 'anonymous',
        },
      })
    } catch (dbErr) {
      // If user already exists somehow, that's OK
      console.warn('guest db create warning:', dbErr)
    }

    return NextResponse.json({
      access_token: signInData.session.access_token,
      refresh_token: signInData.session.refresh_token,
      expires_in: signInData.session.expires_in,
      user: {
        id: signUpData.user.id,
        email: guestEmail,
        is_anonymous: true,
        role: signUpData.user.role,
      },
    })
  } catch (error) {
    console.error('guest-login error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
