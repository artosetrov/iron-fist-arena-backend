import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const name = req.nextUrl.searchParams.get('name')
  if (!name || name.length < 3 || name.length > 16) {
    return NextResponse.json({ available: false, reason: 'invalid' })
  }

  try {
    const existing = await prisma.character.findFirst({
      where: { characterName: { equals: name, mode: 'insensitive' } },
      select: { id: true },
    })

    return NextResponse.json({ available: !existing })
  } catch (error) {
    console.error('check-name error:', error)
    return NextResponse.json({ error: 'Failed to check name' }, { status: 500 })
  }
}
