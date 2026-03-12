import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { createClient } from '@supabase/supabase-js'
import { rateLimit } from '@/lib/rate-limit'

/**
 * POST /api/user/email
 * Body: { new_email }
 * Initiates email change via Supabase (sends confirmation to new address).
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!rateLimit(`user-email:${user.id}`, 3, 60_000)) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { new_email } = body

    if (!new_email || typeof new_email !== 'string' || !new_email.includes('@')) {
      return NextResponse.json({ error: 'Valid new_email is required' }, { status: 400 })
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

    const { error } = await supabase.auth.updateUser({ email: new_email })

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 })
    }

    return NextResponse.json({
      message: 'Confirmation email sent. Please check your new email address to confirm the change.',
    })
  } catch (error) {
    console.error('change email error:', error)
    return NextResponse.json({ error: 'Failed to update email' }, { status: 500 })
  }
}
