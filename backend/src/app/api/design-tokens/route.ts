import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    const designToken = await prisma.designToken.findUnique({
      where: { id: 'global' },
    })

    if (!designToken) {
      return NextResponse.json({ tokens: {} })
    }

    return NextResponse.json({ tokens: designToken.tokens })
  } catch (error) {
    console.error('design-tokens error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch design tokens' },
      { status: 500 }
    )
  }
}
