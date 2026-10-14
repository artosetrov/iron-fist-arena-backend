/**
 * Gem Pack Catalog — single source of truth for shop gem packs.
 *
 * These packs let players spend gold to receive gems (soft-to-hard currency
 * conversion). Prices and amounts are authoritative here and consumed by:
 *   - /api/shop/items      (listing)
 *   - /api/shop/buy-gems   (transaction)
 *
 * DO NOT duplicate these values anywhere else. If you need a new tier, add it
 * here and both endpoints will pick it up automatically.
 */

export type GemPackCatalogId =
  | 'gem_pack_small'
  | 'gem_pack_medium'
  | 'gem_pack_large'

export interface GemPackDef {
  catalogId: GemPackCatalogId
  gemsAmount: number
  goldPrice: number
  requiredLevel: number
}

export const GEM_PACKS: Record<GemPackCatalogId, GemPackDef> = {
  gem_pack_small: {
    catalogId: 'gem_pack_small',
    gemsAmount: 10,
    goldPrice: 500,
    requiredLevel: 1,
  },
  gem_pack_medium: {
    catalogId: 'gem_pack_medium',
    gemsAmount: 50,
    goldPrice: 1200,
    requiredLevel: 5,
  },
  gem_pack_large: {
    catalogId: 'gem_pack_large',
    gemsAmount: 100,
    goldPrice: 3000,
    requiredLevel: 10,
  },
}

/**
 * Pack purchases allowed per account per UTC day.
 *
 * With no limit, gem_pack_large converted gold to gems at 30:1 forever, and
 * since gold runs a multi-thousand daily surplus every gem price in the game
 * collapsed into a day or two of ambient play — the 700-gem Battle Pass was
 * 2.3 days. One pack a day keeps the conversion as a small F2P supplement
 * (at most +100 gems/day) instead of a second wallet.
 */
export const GEM_PACK_DAILY_PURCHASE_CAP = 1

export function isGemPackCatalogId(id: string): id is GemPackCatalogId {
  return id === 'gem_pack_small' || id === 'gem_pack_medium' || id === 'gem_pack_large'
}

export function getGemPack(id: string): GemPackDef | null {
  return isGemPackCatalogId(id) ? GEM_PACKS[id] : null
}
