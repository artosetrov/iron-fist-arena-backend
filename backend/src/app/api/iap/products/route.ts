import { NextRequest, NextResponse } from 'next/server'
import { IAP_PRODUCTS } from '@/lib/game/balance'

export async function GET(_req: NextRequest) {
  try {
    return NextResponse.json({ products: IAP_PRODUCTS })
  } catch (error) {
    console.error('iap products error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch products' },
      { status: 500 }
    )
  }
}
