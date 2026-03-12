import { cookies } from 'next/headers'
import { createClient } from '@supabase/supabase-js'
import { prisma } from './prisma'
import { redirect } from 'next/navigation'

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
  return true // all admin roles can manage players
}

export function canManageUsers(role: AdminRole) {
  return role === 'admin'
}
