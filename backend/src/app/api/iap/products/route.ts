import { NextResponse } from 'next/server'
import { IAP_PRODUCTS } from '@/lib/game/balance'

export async function GET() {
  try {
    // Filter out products with enabled === false (Economy v3: flat gold packs + premium_forever
    // are disabled for new purchases but kept in catalog to honor existing entitlements).
    const products: Record<string, typeof IAP_PRODUCTS[string]> = {}
    for (const [id, p] of Object.entries(IAP_PRODUCTS)) {
      if (p.enabled === false) continue
      products[id] = p
    }
    return NextResponse.json({ products })
  } catch (error) {
    console.error('iap products error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch products' },
      { status: 500 }
    )
  }
}
