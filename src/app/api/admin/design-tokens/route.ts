import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

export async function POST(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const body = await req.json()
    const { tokens } = body

    if (!tokens || typeof tokens !== 'object') {
      return NextResponse.json(
        { error: 'tokens object is required' },
        { status: 400 }
      )
    }

    const designToken = await prisma.designToken.upsert({
      where: { id: 'global' },
      update: {
        tokens,
        updatedBy: user.id,
      },
      create: {
        id: 'global',
        tokens,
        updatedBy: user.id,
      },
    })

    return NextResponse.json({ tokens: designToken.tokens })
  } catch (error) {
    console.error('admin design-tokens error:', error)
    return NextResponse.json(
      { error: 'Failed to update design tokens' },
      { status: 500 }
    )
  }
}
