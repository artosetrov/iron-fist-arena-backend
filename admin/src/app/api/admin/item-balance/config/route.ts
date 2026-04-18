import { NextRequest, NextResponse } from 'next/server'
import { getAdminUser, canModifyConfig } from '@/lib/auth'
import { proxyBackendAdminRoute } from '@/lib/backend-api'

export async function GET(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  return proxyBackendAdminRoute(req, '/api/admin/item-balance/config')
}

export async function POST(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  if (!canModifyConfig(admin.role)) {
    return NextResponse.json({ error: 'Insufficient permissions — admin or developer role required' }, { status: 403 })
  }

  const body = await req.json()
  return proxyBackendAdminRoute(req, '/api/admin/item-balance/config', {
    body,
  })
}
