import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import { rateLimit } from '@/lib/rate-limit'

const supabaseAdmin = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

/**
 * POST /api/auth/forgot-password
 * Triggers a Supabase password reset email.
 * Body: { email }
 */
export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const { email } = body

    const ip = req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || 'unknown'
    if (!rateLimit('forgot:' + ip, 3, 60_000)) {
      return NextResponse.json(
        { error: 'Too many requests. Please try again later.' },
        { status: 429 }
      )
    }

    if (!email || typeof email !== 'string') {
      return NextResponse.json({ error: 'email is required' }, { status: 400 })
    }

    const { error } = await supabaseAdmin.auth.resetPasswordForEmail(email, {
      redirectTo: `${process.env.NEXT_PUBLIC_APP_URL ?? 'https://ironfistarena.com'}/reset-password`,
    })

    if (error) {
      console.error('forgot password error:', error.message)
      // Return success regardless to prevent email enumeration
    }

    return NextResponse.json({ success: true, message: 'If that email exists, a reset link has been sent.' })
  } catch (error) {
    console.error('forgot-password route error:', error)
    return NextResponse.json({ error: 'Failed to process request' }, { status: 500 })
  }
}
