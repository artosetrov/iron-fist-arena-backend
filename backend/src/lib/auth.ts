import { createClient } from '@supabase/supabase-js'
import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { cacheGet, cacheSet, cacheDelete } from '@/lib/cache'

const BAN_CACHE_TTL = 5 * 60 * 1000 // 5 minutes

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

  // Ban check with caching (avoids DB hit on every request)
  const banCacheKey = `ban:${user.id}`
  const cachedBan = cacheGet<boolean>(banCacheKey)

  if (cachedBan === true) return null
  if (cachedBan === false) return user

  // Cache miss — query DB
  const dbUser = await prisma.user.findUnique({
    where: { id: user.id },
    select: { isBanned: true },
  })
  if (!dbUser) return null

  cacheSet(banCacheKey, dbUser.isBanned, BAN_CACHE_TTL)
  if (dbUser.isBanned) return null

  return user
}

/** Invalidate ban cache when admin bans/unbans a user */
export function invalidateBanCache(userId: string) {
  cacheDelete(`ban:${userId}`)
}
