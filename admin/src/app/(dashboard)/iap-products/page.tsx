import { requireAdmin } from '@/lib/auth'
import { headers, cookies } from 'next/headers'
import { IapProductsClient, type IapProductRow } from './iap-products-client'

async function fetchProducts(): Promise<IapProductRow[]> {
  const h = await headers()
  const host = h.get('host')
  const proto = h.get('x-forwarded-proto') ?? 'http'
  const cookieStore = await cookies()
  const cookieHeader = cookieStore.getAll().map((c) => `${c.name}=${c.value}`).join('; ')

  const res = await fetch(`${proto}://${host}/api/admin/iap-products`, {
    headers: { cookie: cookieHeader },
    cache: 'no-store',
  })
  if (!res.ok) return []
  const data = await res.json()
  return (data.products ?? []) as IapProductRow[]
}

export default async function IapProductsPage() {
  await requireAdmin()
  const products = await fetchProducts()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">IAP Products</h1>
        <p className="text-muted-foreground">
          Live catalog from <code>balance.ts</code> <code>IAP_PRODUCTS</code>.
          Disabled products are hidden from <code>/api/iap/products</code> (shop)
          and rejected by <code>/api/iap/verify-receipt</code>.
        </p>
      </div>
      <IapProductsClient products={products} />
    </div>
  )
}
