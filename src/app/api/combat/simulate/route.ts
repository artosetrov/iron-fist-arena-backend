import { NextRequest, NextResponse } from 'next/server'

export async function POST(_req: NextRequest) {
  return NextResponse.json(
    {
      error: 'This endpoint is deprecated. Use POST /api/pvp/fight instead.',
      deprecated: true,
      redirect: '/api/pvp/fight',
    },
    { status: 410 }
  )
}
