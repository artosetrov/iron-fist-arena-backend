import { NextRequest, NextResponse } from 'next/server'

// ── Rate limiting store (in-memory, per-instance) ──
const rateLimitMap = new Map<string, { count: number; resetAt: number }>()
const RATE_LIMIT_WINDOW_MS = 60_000 // 1 minute
const RATE_LIMIT_MAX = 120 // requests per window

function applyCorsHeaders(res: NextResponse): NextResponse {
  res.headers.set('Access-Control-Allow-Origin', '*')
  res.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS')
  res.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-user-id')
  res.headers.set('Access-Control-Max-Age', '86400')
  return res
}

// Periodic cleanup of expired rate-limit entries (every 5 min)
let lastCleanup = Date.now()
function cleanupRateLimits() {
  const now = Date.now()
  if (now - lastCleanup < 300_000) return
  lastCleanup = now
  for (const [key, val] of rateLimitMap) {
    if (now > val.resetAt) rateLimitMap.delete(key)
  }
}

export function middleware(request: NextRequest) {
  // ── Preflight ──
  if (request.method === 'OPTIONS') {
    const res = new NextResponse(null, { status: 204 })
    return applyCorsHeaders(res)
  }

  // ── Rate limiting ──
  cleanupRateLimits()
  const userId = request.headers.get('x-user-id')
  const rateLimitKey = userId || request.headers.get('x-forwarded-for') || 'anon'
  const now = Date.now()
  let entry = rateLimitMap.get(rateLimitKey)

  if (!entry || now > entry.resetAt) {
    entry = { count: 0, resetAt: now + RATE_LIMIT_WINDOW_MS }
    rateLimitMap.set(rateLimitKey, entry)
  }

  entry.count++

  if (entry.count > RATE_LIMIT_MAX) {
    const retryAfter = Math.ceil((entry.resetAt - now) / 1000)
    const res = NextResponse.json({ error: 'Too many requests' }, { status: 429 })
    res.headers.set('Retry-After', String(retryAfter))
    res.headers.set('X-RateLimit-Limit', String(RATE_LIMIT_MAX))
    res.headers.set('X-RateLimit-Remaining', '0')
    res.headers.set('X-RateLimit-Reset', String(Math.ceil(entry.resetAt / 1000)))
    return applyCorsHeaders(res)
  }

  // ── Pass through ──
  const response = NextResponse.next()
  response.headers.set('X-RateLimit-Limit', String(RATE_LIMIT_MAX))
  response.headers.set('X-RateLimit-Remaining', String(RATE_LIMIT_MAX - entry.count))
  response.headers.set('X-RateLimit-Reset', String(Math.ceil(entry.resetAt / 1000)))

  return applyCorsHeaders(response)
}

export const config = {
  matcher: '/api/:path*',
}
