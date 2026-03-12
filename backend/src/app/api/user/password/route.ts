import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { createClient } from '@supabase/supabase-js'
import { rateLimit } from '@/lib/rate-limit'

/**
 * POST /api/user/password
 * Body: { new_password }
 * Changes the authenticated user's password via Supabase.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`user-password:${user.id}`, 5, 60_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { new_password } = body

    if (!new_password || typeof new_password !== 'string' || new_password.length < 6) {
      return NextResponse.json(
        { error: 'new_password must be at least 6 characters' },
        { status: 400 }
      )
    }

    const authHeader = req.headers.get('authorization')
    const token = authHeader?.replace('Bearer ', '') ?? ''

    const supabase = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        global: { headers: { Authorization: `Bearer ${token}` } },
        auth: { autoRefreshToken: false, persistSession: false },
      }
    )

    const { error } = await supabase.auth.updateUser({ password: new_password })

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 })
    }

    return NextResponse.json({ message: 'Password updated successfully' })
  } catch (error) {
    console.error('change password error:', error)
    return NextResponse.json({ error: 'Failed to update password' }, { status: 500 })
  }
}
