'use client'

import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Separator } from '@/components/ui/separator'
import {
  RARITY_COLORS, RARITY_TEXT_COLORS, RARITY_BORDER_COLORS,
  STAT_KEYS, type ItemFormData,
} from '@/lib/item-constants'
import { Sword, Shield, Coins, Sparkles, Zap, TrendingUp, Gem, X } from 'lucide-react'

interface ItemPreviewCardProps {
  form: ItemFormData
  /** When provided, renders a close (X) button in the top-right corner */
  onClose?: () => void
  /** Additional className for the card wrapper */
  className?: string
}

export function ItemPreviewCard({ form, onClose, className }: ItemPreviewCardProps) {
  const nonZeroStats = STAT_KEYS.filter(s => (form.stats[s.key] ?? 0) > 0)
  const hasEffects = form.specialEffect || form.uniquePassive
  const hasEconomy = form.buyPrice > 0 || form.sellPrice > 0 || form.dropChance > 0
  const hasUpgrade = form.maxUpgradeLevel > 0
  const borderColor = RARITY_BORDER_COLORS[form.rarity] ?? 'border-border'

  return (
    <Card className={`w-full ${borderColor} border-2 bg-card/80 backdrop-blur ${className ?? ''}`}>
      <CardHeader className="pb-3 pt-4 px-4 relative">
        {/* Close button */}
        {onClose && (
          <button
            onClick={onClose}
            className="absolute top-3 right-3 p-1 rounded-md text-muted-foreground hover:text-foreground hover:bg-muted transition-colors z-10"
            aria-label="Close"
          >
            <X className="h-4 w-4" />
          </button>
        )}
        {/* Item Image + Info */}
        <div className="flex items-start gap-3">
          <div className={`w-20 h-20 rounded-lg border-2 ${borderColor} bg-muted flex items-center justify-center overflow-hidden shrink-0`}>
            {form.imageUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={form.imageUrl}
                alt={form.itemName || 'Item'}
                className="w-full h-full object-cover"
              />
            ) : (
              <Sword className="h-8 w-8 text-muted-foreground/50" />
            )}
          </div>
          <div className="min-w-0 flex-1 pr-4">
            <h3 className={`text-lg font-bold leading-tight ${RARITY_TEXT_COLORS[form.rarity] ?? 'text-foreground'}`}>
              {form.itemName || 'Unnamed Item'}
            </h3>
            <div className="flex flex-wrap items-center gap-1.5 mt-1.5">
              {form.itemType && (
                <Badge variant="secondary" className="text-[10px] px-1.5 py-0">
                  {form.itemType}
                </Badge>
              )}
              {form.rarity && (
                <Badge className={`text-[10px] px-1.5 py-0 ${RARITY_COLORS[form.rarity] ?? ''}`}>
                  {form.rarity}
                </Badge>
              )}
              {form.itemClass && (
                <Badge variant="outline" className="text-[10px] px-1.5 py-0">
                  {form.itemClass}
                </Badge>
              )}
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              Level {form.itemLevel}
              {form.classRestriction && form.classRestriction !== 'none' && (
                <span className="text-amber-400"> &middot; {form.classRestriction} only</span>
              )}
            </p>
          </div>
        </div>
      </CardHeader>

      {nonZeroStats.length > 0 && (
        <>
          <Separator />
          <CardContent className="py-3 px-4">
            <div className="flex items-center gap-1.5 mb-2">
              <Shield className="h-3.5 w-3.5 text-muted-foreground" />
              <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Stats</span>
            </div>
            <div className="grid grid-cols-2 gap-x-4 gap-y-1">
              {nonZeroStats.map(s => (
                <div key={s.key} className="flex justify-between text-sm">
                  <span className="text-muted-foreground">{s.label}</span>
                  <span className="font-medium text-green-400">+{form.stats[s.key]}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </>
      )}

      {hasEffects && (
        <>
          <Separator />
          <CardContent className="py-3 px-4 space-y-1.5">
            {form.specialEffect && (
              <div className="flex items-start gap-1.5">
                <Sparkles className="h-3.5 w-3.5 text-amber-400 mt-0.5 shrink-0" />
                <span className="text-sm text-amber-400">{form.specialEffect}</span>
              </div>
            )}
            {form.uniquePassive && (
              <div className="flex items-start gap-1.5">
                <Zap className="h-3.5 w-3.5 text-cyan-400 mt-0.5 shrink-0" />
                <span className="text-sm text-cyan-400">{form.uniquePassive}</span>
              </div>
            )}
          </CardContent>
        </>
      )}

      {hasEconomy && (
        <>
          <Separator />
          <CardContent className="py-3 px-4">
            <div className="flex items-center gap-1.5 mb-2">
              <Coins className="h-3.5 w-3.5 text-muted-foreground" />
              <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Economy</span>
            </div>
            <div className="flex flex-wrap gap-x-4 gap-y-1 text-sm">
              {form.buyPrice > 0 && (
                <div>
                  <span className="text-muted-foreground">Buy: </span>
                  <span className="text-yellow-400 font-medium">{form.buyPrice.toLocaleString()}g</span>
                </div>
              )}
              {form.sellPrice > 0 && (
                <div>
                  <span className="text-muted-foreground">Sell: </span>
                  <span className="text-yellow-400 font-medium">{form.sellPrice.toLocaleString()}g</span>
                </div>
              )}
              {form.dropChance > 0 && (
                <div>
                  <span className="text-muted-foreground">Drop: </span>
                  <span className="font-medium">{(form.dropChance * 100).toFixed(1)}%</span>
                </div>
              )}
            </div>
          </CardContent>
        </>
      )}

      {hasUpgrade && (
        <>
          <Separator />
          <CardContent className="py-3 px-4">
            <div className="flex items-center gap-1.5 mb-1">
              <TrendingUp className="h-3.5 w-3.5 text-muted-foreground" />
              <span className="text-xs font-medium text-muted-foreground uppercase tracking-wider">Upgrade</span>
            </div>
            <p className="text-sm">
              Max <span className="text-blue-400 font-medium">+{form.maxUpgradeLevel}</span>
              <span className="text-muted-foreground"> ({form.scalingType})</span>
            </p>
          </CardContent>
        </>
      )}

      {(form.description || form.setName || form.catalogId) && (
        <>
          <Separator />
          <CardContent className="py-3 px-4 space-y-1.5">
            {form.description && (
              <p className="text-sm italic text-muted-foreground line-clamp-3">{form.description}</p>
            )}
            {form.setName && (
              <div className="flex items-center gap-1.5">
                <Gem className="h-3.5 w-3.5 text-green-400" />
                <span className="text-sm text-green-400">Set: {form.setName}</span>
              </div>
            )}
            {form.catalogId && (
              <p className="text-[10px] font-mono text-muted-foreground/60">{form.catalogId}</p>
            )}
          </CardContent>
        </>
      )}
    </Card>
  )
}
