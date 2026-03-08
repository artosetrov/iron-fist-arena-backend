import { getAuthUser } from './auth'
import { prisma } from './prisma'
import { cacheGet, cacheSet } from './cache'
import { NextRequest, NextResponse } from 'next/server'

const ROLE_CACHE_TTL = 5 * 60 * 1000 // 5 minutes

/**
 * Authenticate and verify admin role.
 * Reuses getAuthUser() result + caches role check to avoid duplicate DB queries.
 * Returns the Supabase user or null if not authenticated/not admin.
 */
export async function getAuthAdmin(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return null

  const cacheKey = `role:${user.id}`
  const cachedRole = cacheGet<string>(cacheKey)

  if (cachedRole !== null) {
    return cachedRole === 'admin' ? user : null
  }

  const dbUser = await prisma.user.findUnique({
    where: { id: user.id },
    select: { role: true },
  })

  if (!dbUser) return null

  cacheSet(cacheKey, dbUser.role, ROLE_CACHE_TTL)
  return dbUser.role === 'admin' ? user : null
}

/**
 * Helper to return a 403 Forbidden response.
 */
export function forbiddenResponse() {
  return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
}
