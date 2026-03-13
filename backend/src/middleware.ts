import { NextRequest, NextResponse } from 'next/server'
import { checkRateLimit } from '@/lib/rate-limit'

// ── CORS allowed origins ──
// Set CORS_ORIGINS env var to a comma-separated list of allowed origins.
// Falls back to '*' for local development.
const ALLOWED_ORIGINS = process.env.CORS_ORIGINS
  ? process.env.CORS_ORIGINS.split(',').map(o => o.trim())
  : null

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

function getClientIp(request: NextRequest): string {
  const forwardedFor = request.headers.get('x-forwarded-for')
  if (!forwardedFor) return 'anon'
  return forwardedFor.split(',')[0]?.trim() || 'anon'
}

export async function middleware(request: NextRequest) {
  const origin = request.headers.get('origin')

  // ── Preflight ──
  if (request.method === 'OPTIONS') {
    const res = new NextResponse(null, { status: 204 })
    return applyCorsHeaders(res, origin)
  }

  // ── Rate limiting ──
  const rateLimitKey = `middleware:${getClientIp(request)}`
  const result = await checkRateLimit(rateLimitKey, RATE_LIMIT_MAX, RATE_LIMIT_WINDOW_MS)

  if (!result.allowed) {
    const retryAfter = Math.max(1, Math.ceil((result.resetAt - Date.now()) / 1000))
    const res = NextResponse.json({ error: 'Too many requests' }, { status: 429 })
    res.headers.set('Retry-After', String(retryAfter))
    res.headers.set('X-RateLimit-Limit', String(result.limit))
    res.headers.set('X-RateLimit-Remaining', '0')
    res.headers.set('X-RateLimit-Reset', String(Math.ceil(result.resetAt / 1000)))
    return applyCorsHeaders(res, origin)
  }

  // ── Pass through ──
  const response = NextResponse.next()
  response.headers.set('X-RateLimit-Limit', String(result.limit))
  response.headers.set('X-RateLimit-Remaining', String(result.remaining))
  response.headers.set('X-RateLimit-Reset', String(Math.ceil(result.resetAt / 1000)))

  return applyCorsHeaders(response, origin)
}

export const config = {
  matcher: '/api/:path*',
}
