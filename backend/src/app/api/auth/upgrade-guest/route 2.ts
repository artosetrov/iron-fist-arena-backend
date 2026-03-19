import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { createAdminClient } from '@/lib/supabase/server'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'

/**
 * POST /api/auth/upgrade-guest
 *
 * Converts a guest account into a full registered account.
 * Keeps the same Supabase user ID — all characters, inventory,
 * progress, and foreign keys remain intact.
 *
 * Body: { email, password, username }
 *
 * Flow:
 * 1. Verify caller is an authenticated guest (authProvider = 'anonymous')
 * 2. Update Supabase auth user: set real email + password
 * 3. Sign in with new credentials to get fresh tokens
 * 4. Update local User record: email, username, authProvider
 * 5. Return new tokens to the client
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const ip = req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || 'unknown'
  if (!(await rateLimit('upgrade-guest:' + ip, 5, 60_000))) {
    return NextResponse.json(
      { error: 'Too many requests. Please try again later.' },
      { status: 429 }
    )
  }

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

    // Verify this user IS a guest
    const dbUser = await prisma.user.findUnique({
      where: { id: user.id },
      select: { authProvider: true, email: true },
    })

    if (!dbUser) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    if (dbUser.authProvider !== 'anonymous') {
      return NextResponse.json(
        { error: 'Account is already registered' },
        { status: 400 }
      )
    }

    // Check if target email is already taken by another user
    const emailExists = await prisma.user.findUnique({
      where: { email },
      select: { id: true },
    })

    if (emailExists && emailExists.id !== user.id) {
      return NextResponse.json(
        { error: 'Email already registered. Please use a different email or login to your existing account.' },
        { status: 409 }
      )
    }

    const supabase = createAdminClient()
    const displayName = username ?? email.split('@')[0]

    // Update Supabase auth user — change email and set password
    const { error: updateError } = await supabase.auth.admin.updateUserById(user.id, {
      email,
      password,
      email_confirm: true,
      user_metadata: { is_guest: false, username: displayName },
    })

    if (updateError) {
      console.error('upgrade-guest supabase error:', updateError)

      if (updateError.message?.includes('already been registered') ||
          updateError.message?.includes('already registered')) {
        return NextResponse.json(
          { error: 'Email already registered with another account.' },
          { status: 409 }
        )
      }

      return NextResponse.json(
        { error: updateError.message ?? 'Failed to upgrade account' },
        { status: 500 }
      )
    }

    // Sign in with new credentials to get fresh tokens
    const { data: signInData, error: signInError } =
      await supabase.auth.signInWithPassword({ email, password })

    if (signInError || !signInData.session) {
      console.error('upgrade-guest sign-in error:', signInError)
      return NextResponse.json(
        { error: 'Account upgraded but sign-in failed. Please login manually.' },
        { status: 500 }
      )
    }

    // Update local DB user record
    await prisma.user.update({
      where: { id: user.id },
      data: {
        email,
        username: displayName,
        authProvider: 'email',
        lastLogin: new Date(),
      },
    })

    return NextResponse.json({
      access_token: signInData.session.access_token,
      refresh_token: signInData.session.refresh_token,
      expires_in: signInData.session.expires_in,
      user: {
        id: user.id,
        email,
        is_anonymous: false,
        role: user.role,
      },
    })
  } catch (error) {
    console.error('upgrade-guest error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
