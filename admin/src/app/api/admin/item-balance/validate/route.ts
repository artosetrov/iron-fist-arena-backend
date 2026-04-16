import { NextRequest, NextResponse } from 'next/server'
import { getAdminUser } from '@/lib/auth'
import { proxyBackendAdminRoute } from '@/lib/backend-api'

export async function POST(request: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  return proxyBackendAdminRoute(request, '/api/admin/item-balance/validate')
}
