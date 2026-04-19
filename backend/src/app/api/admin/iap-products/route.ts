import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { IAP_PRODUCTS } from '@/lib/game/balance'

/**
 * GET /api/admin/iap-products
 *
 * Returns the IAP catalog with its `enabled?` flag state. Source-of-truth is
 * `IAP_PRODUCTS` in `backend/src/lib/game/balance.ts` — products with
 * `enabled === false` are still honored on server for grandfathered owners but
 * filtered out of `/api/iap/products` (shop) and rejected by verify-receipt.
 *
 * Read-only for Phase 1. Write path (toggling `enabled`) is a balance-config
 * change and must still go through a backend/admin code deploy per
 * `backend/CLAUDE.md` IAP rules — surfacing the catalog here lets GMs verify
 * live state without round-tripping through StoreKit config.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const products = Object.entries(IAP_PRODUCTS).map(([id, product]) => ({
      id,
      gems: product.gems,
      gold: product.gold,
      premium: product.premium,
      monthlyGemCard: product.monthlyGemCard,
      price: product.price,
      enabled: product.enabled !== false,
      items: product.items ?? null,
      subscription: product.subscription ?? null,
    }))

    return NextResponse.json({ products })
  } catch (error) {
    console.error('admin iap-products list error:', error)
    return NextResponse.json({ error: 'Failed to fetch IAP products' }, { status: 500 })
  }
}
