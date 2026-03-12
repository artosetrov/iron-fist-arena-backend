import { NextRequest, NextResponse } from 'next/server'

// ── CORS allowed origins ──
// Set CORS_ORIGINS env var to a comma-separated list of allowed origins.
// Falls back to '*' for local development.
const ALLOWED_ORIGINS = process.env.CORS_ORIGINS
  ? process.env.CORS_ORIGINS.split(',').map(o => o.trim())
  : null

// ── Rate limiting store (in-memory, per-instance) ──
const rateLimitMap = new Map<string, { count: number; resetAt: number }>()
const RATE_LIMIT_WINDOW_MS = 60_000 // 1 minute
const RATE_LIMIT_MAX = 120 // requests per window

function applyCorsHeaders(res: NextResponse, origin: string | null): NextResponse {
  // If CORS_ORIGINS is configured, only allow listed origins.
  // Otherwise fall back to '*' (safe for mobile-only API in dev).
  if (ALLOWED_ORIGINS) {
    if (origin && ALLOWED_ORIGINS.includes(origin)) {
      res.headers.set('Access-Control-Allow-Origin', origin)
      res.headers.set('Vary', 'Origin')
    }
    // If origin doesn't match, don't set the header — browser will block
  } else {
    res.headers.set('Access-Control-Allow-Origin', '*')
  }
  res.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS')
  res.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization')
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
  const origin = request.headers.get('origin')

  // ── Preflight ──
  if (request.method === 'OPTIONS') {
    const res = new NextResponse(null, { status: 204 })
    return applyCorsHeaders(res, origin)
  }

  // ── Rate limiting ──
  cleanupRateLimits()
  const rateLimitKey = request.headers.get('x-forwarded-for') || 'anon'
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
    return applyCorsHeaders(res, origin)
  }

  // ── Pass through ──
  const response = NextResponse.next()
  response.headers.set('X-RateLimit-Limit', String(RATE_LIMIT_MAX))
  response.headers.set('X-RateLimit-Remaining', String(RATE_LIMIT_MAX - entry.count))
  response.headers.set('X-RateLimit-Reset', String(Math.ceil(entry.resetAt / 1000)))

  return applyCorsHeaders(response, origin)
}

export const config = {
  matcher: '/api/:path*',
}
