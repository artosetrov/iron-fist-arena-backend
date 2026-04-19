import { NextRequest } from 'next/server'
import { getAdminUser } from '@/lib/auth'
import { proxyBackendAdminRoute } from '@/lib/backend-api'

export async function GET(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return Response.json({ error: 'Unauthorized' }, { status: 401 })

  return proxyBackendAdminRoute(req, '/api/admin/iap-products')
}
