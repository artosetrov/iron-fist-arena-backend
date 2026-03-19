import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { resolveAllFlags, invalidateFlagCache } from '@/lib/game/feature-flags'

/**
 * GET /api/flags
 * Returns resolved feature flags for the requesting user/character.
 * Query params: character_id (optional, for targeting)
 *
 * Response: { flags: { [key]: resolved_value } }
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`flags:${user.id}`, 60, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const { searchParams } = new URL(req.url)
    const characterId = searchParams.get('character_id')

    // Optionally load character for targeting
    let character: { id: string; level: number; class: string } | null = null
    if (characterId) {
      character = await prisma.character.findUnique({
        where: { id: characterId },
        select: { id: true, level: true, class: true },
      })
    }

    const flags = await resolveAllFlags(user.id, character)

    return NextResponse.json({ flags })
  } catch (error) {
    console.error('flags error:', error)
    return NextResponse.json({ error: 'Failed to fetch flags' }, { status: 500 })
  }
}

/**
 * POST /api/flags/invalidate
 * Admin-only: invalidate the flag cache (called after admin changes)
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  // Simple admin check
  const dbUser = await prisma.user.findUnique({
    where: { id: user.id },
    select: { role: true },
  })
  if (!dbUser || !['admin', 'developer'].includes(dbUser.role)) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  invalidateFlagCache()
  return NextResponse.json({ success: true, message: 'Flag cache invalidated' })
}
