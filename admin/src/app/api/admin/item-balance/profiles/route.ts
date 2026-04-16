import { NextRequest, NextResponse } from 'next/server'
import { getAdminUser } from '@/lib/auth'
import { proxyBackendAdminRoute } from '@/lib/backend-api'

export async function GET(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  return proxyBackendAdminRoute(req, '/api/admin/item-balance/profiles')
}

export async function PUT(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const body = await req.json()
  return proxyBackendAdminRoute(req, '/api/admin/item-balance/profiles', {
    method: 'PUT',
    body,
  })
}
