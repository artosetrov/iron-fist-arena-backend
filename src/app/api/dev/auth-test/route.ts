import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'

export async function GET(req: NextRequest) {
  const authHeader = req.headers.get('authorization')

  if (!authHeader) {
    return NextResponse.json({
      authenticated: false,
      reason: 'No Authorization header',
      hint: 'Send: Authorization: Bearer <supabase_jwt>',
    })
  }

  const user = await getAuthUser(req)
  if (!user) {
    return NextResponse.json({
      authenticated: false,
      reason: 'Token invalid or expired',
      headerPresent: true,
      tokenPrefix: authHeader.substring(0, 20) + '...',
    })
  }

  return NextResponse.json({
    authenticated: true,
    userId: user.id,
    email: user.email ?? null,
    isAnonymous: user.is_anonymous ?? false,
    role: user.role,
  })
}
