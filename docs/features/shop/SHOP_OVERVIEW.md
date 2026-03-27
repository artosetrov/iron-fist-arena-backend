# Feature: Shop

> **Status:** Complete
> **Owner:** Economy system
> **Last updated:** 2026-03-26
> **Source of truth:** `Hexbound/Hexbound/Views/Shop/` + `backend/src/app/api/shop/`

---

## Overview

Магазин — центральный gold/gem sink. Вкладки с экипировкой, расходниками, специальные предложения с таймером, IAP для покупки gems/gold.

## Key Files

**iOS Views:**
- `Hexbound/Hexbound/Views/Shop/ShopDetailView.swift` — главный экран с вкладками
- `Hexbound/Hexbound/Views/Shop/ShopViewModel.swift` — state management, покупки
- `Hexbound/Hexbound/Views/Shop/ShopOfferBannerView.swift` — баннер спецпредложений
- `Hexbound/Hexbound/Views/Shop/CurrencyPurchaseView.swift` — IAP flow (gold/gems)
- `Hexbound/Hexbound/Views/Shop/PremiumPurchaseView.swift` — premium покупки
- `Hexbound/Hexbound/Views/Shop/MerchantStripView.swift` — NPC merchant UI

**iOS Models:**
- `Models/ShopOffer.swift`, `Models/ShopItem.swift`, `Models/Item.swift`

**iOS Service:** `Services/ShopService.swift`

**Backend Routes:**
| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/shop/items` | Список товаров |
| `GET` | `/api/shop/offers` | Спецпредложения |
| `POST` | `/api/shop/buy` | Покупка за gold |
| `POST` | `/api/shop/buy-consumable` | Покупка расходника |
| `POST` | `/api/shop/buy-potion` | Покупка зелья |
| `POST` | `/api/shop/buy-gems` | IAP gems |
| `POST` | `/api/shop/buy-gold` | Обмен gems → gold |
| `POST` | `/api/shop/upgrade` | Апгрейд предмета |
| `POST` | `/api/shop/repair` | Починка экипировки |

**Admin:** `admin/src/actions/shop-offers.ts`
**Tests:** `backend/tests/api/shop-buy.test.ts`

## Components

- `ItemCardView(.shop(...))` — карточка товара (НЕ ShopItemCardView — deprecated)
- `CurrencyDisplay(.mini)` — цена на карточке
- `TabSwitcher` — вкладки категорий

## Rules

- TOCTOU prevention: все покупки внутри `$transaction` с row lock
- Optimistic UI: обновляй баланс мгновенно, API в background
- Никогда SF Symbols для валюты — только `CurrencyDisplay`

## Dependencies

- Depends on: Economy system, Inventory, Item system
- Depended by: Daily quests (gold_spent), Achievements

## Related Docs

- `docs/rules/rules-economy.md`, `docs/02_product_and_features/ECONOMY.md`
