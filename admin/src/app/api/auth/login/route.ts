import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import { prisma } from '@/lib/prisma'
import type { AdminRole } from '@/lib/auth'

const ALLOWED_ROLES: AdminRole[] = ['admin', 'moderator', 'developer']

export async function POST(request: NextRequest) {
  try {
    const { email, password } = await request.json()

    if (!email || !password) {
      return NextResponse.json(
        { error: 'Email and password are required' },
        { status: 400 }
      )
    }

    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
    const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

    if (!supabaseUrl || !supabaseKey) {
      return NextResponse.json(
        { error: 'Server configuration error: missing Supabase credentials' },
        { status: 500 }
      )
    }

    const supabase = createClient(supabaseUrl, supabaseKey)
    const { data, error: authError } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (authError || !data.session) {
      return NextResponse.json(
        { error: authError?.message || 'Authentication failed' },
        { status: 401 }
      )
    }

    const dbUser = await prisma.user.findUnique({
      where: { id: data.user.id },
      select: { role: true },
    })

    if (!dbUser) {
      return NextResponse.json(
        { error: `User not found in database (id: ${data.user.id})` },
        { status: 403 }
      )
    }

    if (!ALLOWED_ROLES.includes(dbUser.role as AdminRole)) {
      return NextResponse.json(
        { error: `Access denied. Your role "${dbUser.role}" is not authorized.` },
        { status: 403 }
      )
    }

    const response = NextResponse.json({
      ok: true,
      role: dbUser.role,
    })

    response.cookies.set('admin-token', data.session.access_token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/',
      maxAge: 60 * 60 * 24 * 7,
    })

    return response
  } catch (err) {
    return NextResponse.json(
      { error: `Internal server error: ${err instanceof Error ? err.message : 'unknown'}` },
      { status: 500 }
    )
  }
}
