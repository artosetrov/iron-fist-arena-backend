import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  const diagnostics: Record<string, unknown> = {
    status: 'ok',
    timestamp: Date.now(),
  }

  try {
    await prisma.$queryRaw`SELECT 1`
    diagnostics.database = 'connected'
  } catch {
    diagnostics.database = 'disconnected'
  }

  return NextResponse.json(diagnostics)
}
