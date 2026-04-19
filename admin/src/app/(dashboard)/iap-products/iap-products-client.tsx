'use client'

import { useState } from 'react'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

export interface IapProductRow {
  id: string
  gems: number
  gold: number
  premium: boolean
  monthlyGemCard: boolean
  price: number
  enabled: boolean
  items: { type: string; quantity: number }[] | null
  subscription: { monthlyGems?: number } | null
}

export function IapProductsClient({ products }: { products: IapProductRow[] }) {
  const [filter, setFilter] = useState('')
  const [hideDisabled, setHideDisabled] = useState(false)

  const filtered = products.filter((p) => {
    if (hideDisabled && !p.enabled) return false
    if (filter && !p.id.toLowerCase().includes(filter.toLowerCase())) return false
    return true
  })

  const enabledCount = products.filter((p) => p.enabled).length
  const disabledCount = products.length - enabledCount

  return (
    <div className="space-y-4">
      <div className="grid gap-3 grid-cols-3">
        <Card>
          <CardHeader className="pb-2"><CardTitle className="text-xs text-muted-foreground">Total SKUs</CardTitle></CardHeader>
          <CardContent className="text-2xl font-bold">{products.length}</CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2"><CardTitle className="text-xs text-muted-foreground">Enabled</CardTitle></CardHeader>
          <CardContent className="text-2xl font-bold text-green-400">{enabledCount}</CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2"><CardTitle className="text-xs text-muted-foreground">Disabled (grandfathered)</CardTitle></CardHeader>
          <CardContent className="text-2xl font-bold text-yellow-400">{disabledCount}</CardContent>
        </Card>
      </div>

      <div className="flex items-center gap-3">
        <Input
          type="search"
          placeholder="Filter by product id…"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="max-w-xs"
        />
        <label className="flex items-center gap-2 text-sm text-muted-foreground">
          <input
            type="checkbox"
            checked={hideDisabled}
            onChange={(e) => setHideDisabled(e.target.checked)}
          />
          Hide disabled
        </label>
      </div>

      <div className="rounded-lg border border-border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-muted/50">
            <tr>
              <th className="text-left p-3 font-medium">Product ID</th>
              <th className="text-right p-3 font-medium">Price (USD)</th>
              <th className="text-right p-3 font-medium">Gems</th>
              <th className="text-right p-3 font-medium">Gold</th>
              <th className="text-left p-3 font-medium">Flags</th>
              <th className="text-left p-3 font-medium">Extras</th>
              <th className="text-left p-3 font-medium">Status</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((p) => (
              <tr key={p.id} className="border-t border-border">
                <td className="p-3 font-mono text-xs">{p.id}</td>
                <td className="p-3 text-right">${p.price.toFixed(2)}</td>
                <td className="p-3 text-right">{p.gems || '—'}</td>
                <td className="p-3 text-right">{p.gold || '—'}</td>
                <td className="p-3 space-x-1">
                  {p.premium && <Badge variant="secondary">premium</Badge>}
                  {p.monthlyGemCard && <Badge variant="secondary">monthly-card</Badge>}
                  {p.subscription && <Badge variant="secondary">subscription</Badge>}
                </td>
                <td className="p-3 text-xs">
                  {p.items && p.items.length > 0
                    ? p.items.map((i) => `${i.quantity}× ${i.type}`).join(', ')
                    : '—'}
                </td>
                <td className="p-3">
                  {p.enabled ? (
                    <Badge className="bg-green-500/20 text-green-300">enabled</Badge>
                  ) : (
                    <Badge className="bg-yellow-500/20 text-yellow-300">disabled</Badge>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered.length === 0 && (
          <div className="p-8 text-center text-muted-foreground text-sm">
            No products match the current filter.
          </div>
        )}
      </div>

      <p className="text-xs text-muted-foreground">
        Read-only view. To change a product&apos;s <code>enabled</code> flag or
        price, edit <code>backend/src/lib/game/balance.ts</code> <code>IAP_PRODUCTS</code>
        and deploy. Apple StoreKit config must be kept in sync per{' '}
        <code>backend/CLAUDE.md</code> IAP rules.
      </p>
    </div>
  )
}
