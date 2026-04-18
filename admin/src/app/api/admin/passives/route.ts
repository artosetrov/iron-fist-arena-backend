import { NextRequest } from 'next/server'
import { getAdminUser, canModifyConfig } from '@/lib/auth'
import { proxyBackendAdminRoute } from '@/lib/backend-api'

function forbidden() {
  return Response.json({ error: 'Insufficient permissions — admin or developer role required' }, { status: 403 })
}

export async function GET(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return Response.json({ error: 'Unauthorized' }, { status: 401 })

  return proxyBackendAdminRoute(req, '/api/admin/passives')
}

export async function POST(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return Response.json({ error: 'Unauthorized' }, { status: 401 })
  if (!canModifyConfig(admin.role)) return forbidden()

  return proxyBackendAdminRoute(req, '/api/admin/passives')
}

export async function PUT(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return Response.json({ error: 'Unauthorized' }, { status: 401 })
  if (!canModifyConfig(admin.role)) return forbidden()

  return proxyBackendAdminRoute(req, '/api/admin/passives')
}

export async function DELETE(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return Response.json({ error: 'Unauthorized' }, { status: 401 })
  if (!canModifyConfig(admin.role)) return forbidden()

  return proxyBackendAdminRoute(req, '/api/admin/passives')
}
