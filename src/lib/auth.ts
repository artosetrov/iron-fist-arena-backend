import { createClient } from '@supabase/supabase-js'
import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function getAuthUser(req: NextRequest) {
  const authHeader = req.headers.get('authorization')
  if (!authHeader?.startsWith('Bearer ')) return null
  const token = authHeader.replace('Bearer ', '')

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

  // Ban check (runs in Node.js runtime, not Edge)
  const dbUser = await prisma.user.findUnique({
    where: { id: user.id },
    select: { isBanned: true },
  })
  if (dbUser?.isBanned) return null

  return user
}
