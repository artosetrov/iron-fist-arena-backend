import { createClient, type User as SupabaseAuthUser } from '@supabase/supabase-js'
import { NextRequest } from 'next/server'
import { prisma } from '@/lib/prisma'
import { cacheGet, cacheSet, cacheDelete } from '@/lib/cache'

const BAN_CACHE_TTL = 5 * 60 * 1000 // 5 minutes

// ---------------------------------------------------------------------------
// Verified-token memo (latency pass 2026-10-15)
//
// `supabase.auth.getUser()` is an HTTP round trip to Supabase Auth on EVERY
// API call — the single largest fixed cost of a tap. A warm instance now
// remembers a token it has already verified for up to TOKEN_MEMO_TTL_MS
// (never past the JWT's own `exp`), keyed by a SHA-256 of the token.
//
// Trade-off: a session revoked in Supabase (sign-out elsewhere, password
// reset) stays usable on a warm instance for at most TOKEN_MEMO_TTL_MS.
// Bans are unaffected — the ban check below still runs on every request.
// ---------------------------------------------------------------------------
const TOKEN_MEMO_TTL_MS = 60 * 1000
const TOKEN_MEMO_MAX_ENTRIES = 5_000
const tokenMemo = new Map<string, { user: SupabaseAuthUser; expiresAt: number }>()

async function tokenDigest(token: string): Promise<string> {
  const bytes = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(token))
  return Array.from(new Uint8Array(bytes), (b) => b.toString(16).padStart(2, '0')).join('')
}

/** `exp` (ms) from an already-verified JWT, or null if unreadable. */
function jwtExpiryMs(token: string): number | null {
  try {
    const payload = token.split('.')[1]
    if (!payload) return null
    const json = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as { exp?: number }
    return typeof json.exp === 'number' ? json.exp * 1000 : null
  } catch {
    return null
  }
}

async function verifyWithSupabase(token: string): Promise<SupabaseAuthUser | null> {
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
  return user
}

async function fetchSupabaseAuthUser(req: NextRequest) {
  const authHeader = req.headers.get('authorization')
  if (!authHeader?.startsWith('Bearer ')) return null
  const token = authHeader.replace('Bearer ', '')

  const now = Date.now()
  const key = await tokenDigest(token)
  const memoized = tokenMemo.get(key)
  if (memoized && memoized.expiresAt > now) return memoized.user
  if (memoized) tokenMemo.delete(key)

  const user = await verifyWithSupabase(token)
  if (!user) return null

  const exp = jwtExpiryMs(token)
  const expiresAt = Math.min(now + TOKEN_MEMO_TTL_MS, exp ?? now + TOKEN_MEMO_TTL_MS)
  if (expiresAt > now) {
    if (tokenMemo.size >= TOKEN_MEMO_MAX_ENTRIES) {
      const oldest = tokenMemo.keys().next().value
      if (oldest !== undefined) tokenMemo.delete(oldest)
    }
    tokenMemo.set(key, { user, expiresAt })
  }
  return user
}

export async function getSupabaseAuthUser(req: NextRequest) {
  return fetchSupabaseAuthUser(req)
}

export async function getAuthUser(req: NextRequest) {
  const user = await fetchSupabaseAuthUser(req)
  if (!user) return null

  // Ban check with caching (avoids DB hit on every request)
  const banCacheKey = `ban:${user.id}`
  const cachedBan = await cacheGet<boolean>(banCacheKey)

  if (cachedBan === true) return null
  if (cachedBan === false) return user

  // Cache miss — query DB
  const dbUser = await prisma.user.findUnique({
    where: { id: user.id },
    select: { isBanned: true },
  })
  if (!dbUser) return null

  await cacheSet(banCacheKey, dbUser.isBanned, BAN_CACHE_TTL)
  if (dbUser.isBanned) return null

  return user
}

/** Invalidate ban cache when admin bans/unbans a user */
export async function invalidateBanCache(userId: string) {
  await cacheDelete(`ban:${userId}`)
}
