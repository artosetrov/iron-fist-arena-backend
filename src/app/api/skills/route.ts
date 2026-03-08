import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { cacheGet, cacheSet } from '@/lib/cache'

const CACHE_TTL = 10 * 60 * 1000 // 10 minutes

// GET — List all active skills (catalog). Filter by ?class=warrior
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const classFilter = req.nextUrl.searchParams.get('class')

  // Try cache for full catalog
  const cacheKey = 'skills:catalog'
  let skills = cacheGet<unknown[]>(cacheKey)

  if (!skills) {
    skills = await prisma.skill.findMany({
      where: { isActive: true },
      orderBy: [{ classRestriction: 'asc' }, { sortOrder: 'asc' }, { name: 'asc' }],
    })
    cacheSet(cacheKey, skills, CACHE_TTL)
  }

  // Apply client-side class filter
  if (classFilter) {
    skills = (skills as Array<Record<string, unknown>>).filter(
      (s) => s.classRestriction === classFilter || s.classRestriction === null
    )
  }

  return NextResponse.json({ skills })
}
