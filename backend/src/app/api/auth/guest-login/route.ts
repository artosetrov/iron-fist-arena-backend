import { NextRequest, NextResponse } from 'next/server'
import { createAdminClient } from '@/lib/supabase/server'
import { prisma } from '@/lib/prisma'
import crypto from 'crypto'
import { rateLimit } from '@/lib/rate-limit'

async function tryRestoreGuestSession(
  deviceId: string,
  supabase: ReturnType<typeof createAdminClient>
) {
  const existingUser = await prisma.user.findUnique({
    where: { deviceId },
  })

  if (!existingUser || existingUser.authProvider !== 'anonymous' || !existingUser.email) {
    return null
  }

  const newPassword = crypto.randomUUID()
  const { error: updateError } = await supabase.auth.admin.updateUserById(
    existingUser.id,
    { password: newPassword }
  )

  if (updateError) {
    console.error('guest restore updateUserById error:', updateError)
    return null
  }

  const { data: signInData, error: signInError } =
    await supabase.auth.signInWithPassword({
      email: existingUser.email,
      password: newPassword,
    })

  if (signInError || !signInData.session) {
    console.error('guest restore signIn error:', signInError)
    return null
  }

  await prisma.user.update({
    where: { id: existingUser.id },
    data: { lastLogin: new Date() },
  }).catch(() => undefined)

  return NextResponse.json({
    access_token: signInData.session.access_token,
    refresh_token: signInData.session.refresh_token,
    expires_in: signInData.session.expires_in,
    restored: true,
    user: {
      id: existingUser.id,
      email: existingUser.email,
      is_anonymous: true,
      role: 'authenticated',
    },
  })
}

async function cleanupFreshGuest(userId: string, deleteLocalUser = false) {
  if (deleteLocalUser) {
    await prisma.user.delete({
      where: { id: userId },
    }).catch((deleteErr: unknown) => {
      console.error('guest cleanup prisma delete error:', deleteErr)
    })
  }
}

/**
 * POST /api/auth/guest-login
 *
 * Creates or restores a guest user via Supabase Admin API.
 * Returns access_token, refresh_token, and user data.
 *
 * Body: { device_id?: string }
 *
 * Flow:
 *  - If device_id is provided AND a guest user with that deviceId exists:
 *    -> rotate the Supabase password (admin.updateUserById), sign in, return new tokens.
 *    -> This restores the existing character, gold, progress, etc.
 *  - Otherwise:
 *    -> create a fresh Supabase user + Prisma User row, store deviceId if provided.
 *
 * This endpoint does NOT require authentication —
 * it IS the authentication endpoint for guests.
 */
export async function POST(req: NextRequest) {
  try {
    const ip = req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || 'unknown'
    if (!(await rateLimit('guest:' + ip, 5, 60_000))) {
      return NextResponse.json(
        { error: 'Too many requests. Please try again later.' },
        { status: 429 }
      )
    }

    // Parse optional device_id from body
    let deviceId: string | null = null
    try {
      const body = await req.json().catch(() => ({} as Record<string, unknown>))
      const raw = (body as Record<string, unknown>)?.device_id
      if (typeof raw === 'string' && raw.length >= 8 && raw.length <= 128) {
        deviceId = raw
      }
    } catch {
      // no body is fine — falls through to fresh guest creation
    }

    const supabase = createAdminClient()

    // --- Restore path: existing guest by deviceId ---
    if (deviceId) {
      const restored = await tryRestoreGuestSession(deviceId, supabase)
      if (restored) {
        return restored
      }
    }

    // --- Fresh creation path ---
    const guestId = crypto.randomUUID().replace(/-/g, '').substring(0, 12)
    const guestEmail = `guest_${guestId}@guest.ironfist.local`
    const guestPassword = crypto.randomUUID()

    const { data: signUpData, error: signUpError } = await supabase.auth.admin.createUser({
      email: guestEmail,
      password: guestPassword,
      email_confirm: true,
      user_metadata: { is_guest: true, device_id: deviceId ?? null },
    })

    if (signUpError || !signUpData.user) {
      console.error('guest signup error:', signUpError)
      return NextResponse.json(
        { error: signUpError?.message ?? 'Failed to create guest account' },
        { status: 500 }
      )
    }

    const randomDigits = Math.floor(1000 + Math.random() * 9000)
    const guestUsername = `Guest${randomDigits}`

    try {
      await prisma.user.create({
        data: {
          id: signUpData.user.id,
          username: guestUsername,
          email: guestEmail,
          authProvider: 'anonymous',
          deviceId: deviceId, // may be null — that's OK
        },
      })
    } catch (dbErr) {
      console.warn('guest db create warning:', dbErr)
      await supabase.auth.admin.deleteUser(signUpData.user.id).catch((deleteErr: unknown) => {
        console.error('guest cleanup deleteUser error:', deleteErr)
      })

      if (deviceId) {
        const restored = await tryRestoreGuestSession(deviceId, supabase)
        if (restored) {
          return restored
        }
      }

      return NextResponse.json(
        { error: 'Failed to create guest account' },
        { status: 500 }
      )
    }

    const { data: signInData, error: signInError } =
      await supabase.auth.signInWithPassword({
        email: guestEmail,
        password: guestPassword,
      })

    if (signInError || !signInData.session) {
      console.error('guest signin error:', signInError)
      await supabase.auth.admin.deleteUser(signUpData.user.id).catch((deleteErr: unknown) => {
        console.error('guest cleanup deleteUser error:', deleteErr)
      })
      await cleanupFreshGuest(signUpData.user.id, true)
      return NextResponse.json(
        { error: signInError?.message ?? 'Failed to sign in guest' },
        { status: 500 }
      )
    }

    return NextResponse.json({
      access_token: signInData.session.access_token,
      refresh_token: signInData.session.refresh_token,
      expires_in: signInData.session.expires_in,
      restored: false,
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
