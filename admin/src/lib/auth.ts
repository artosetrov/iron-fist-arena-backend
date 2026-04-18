import { cookies } from 'next/headers'
import { createClient } from '@supabase/supabase-js'
import { prisma } from './prisma'
import { redirect } from 'next/navigation'
import { NextResponse } from 'next/server'

export type AdminRole = 'admin' | 'moderator' | 'developer'

const ALLOWED_ROLES: AdminRole[] = ['admin', 'moderator', 'developer']

export async function getAdminUser() {
  const cookieStore = await cookies()
  const token = cookieStore.get('admin-token')?.value
  if (!token) return null

  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { autoRefreshToken: false, persistSession: false },
    }
  )

  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) return null

  const dbUser = await prisma.user.findUnique({
    where: { id: user.id },
    select: { id: true, email: true, username: true, role: true },
  })

  if (!dbUser || !ALLOWED_ROLES.includes(dbUser.role as AdminRole)) return null

  return { ...dbUser, role: dbUser.role as AdminRole }
}

export async function requireAdmin(requiredRole?: AdminRole) {
  const admin = await getAdminUser()
  if (!admin) redirect('/login')

  if (requiredRole === 'admin' && admin.role !== 'admin') {
    redirect('/?error=insufficient_permissions')
  }

  return admin
}

export function canModifyConfig(role: AdminRole) {
  return role === 'admin' || role === 'developer'
}

export function canManagePlayers(role: AdminRole) {
  return ALLOWED_ROLES.includes(role)
}

export function canManageUsers(role: AdminRole) {
  return role === 'admin'
}

/**
 * API route guard: returns null when caller may modify game config
 * (admin or developer role), otherwise returns a NextResponse to send.
 * Moderators get 403 — they can view but not mutate balance/content.
 *
 * Usage: `const denial = await requireConfigModifier(); if (denial) return denial;`
 */
export async function requireConfigModifier() {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  if (!canModifyConfig(admin.role)) {
    return NextResponse.json({ error: 'Insufficient permissions — admin or developer role required' }, { status: 403 })
  }
  return null
}

/**
 * API route guard: returns null when caller is strictly `admin` role,
 * otherwise returns a NextResponse to send. Use for IAP management, role
 * mutation, and other operations with no legitimate non-admin use case.
 *
 * Usage: `const denial = await requireStrictAdmin(); if (denial) return denial;`
 */
export async function requireStrictAdmin() {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  if (admin.role !== 'admin') {
    return NextResponse.json({ error: 'Admin role required' }, { status: 403 })
  }
  return null
}
