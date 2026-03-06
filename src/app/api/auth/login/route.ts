import { NextRequest, NextResponse } from 'next/server'
import { createAdminClient } from '@/lib/supabase/server'

/**
 * POST /api/auth/login
 *
 * Logs in a user via Supabase Auth (email + password).
 * Returns access_token, refresh_token, and user data.
 *
 * Body: { email, password }
 */
export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const { email, password } = body

    if (!email || !password) {
      return NextResponse.json(
        { error: 'email and password are required' },
        { status: 400 }
      )
    }

    const supabase = createAdminClient()

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error || !data.session) {
      return NextResponse.json(
        { error: error?.message ?? 'Invalid credentials' },
        { status: 401 }
      )
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
