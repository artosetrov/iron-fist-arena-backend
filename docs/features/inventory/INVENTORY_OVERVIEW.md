# Feature: Inventory & Equipment

> **Status:** Complete
> **Owner:** Core gameplay
> **Last updated:** 2026-03-26
> **Source of truth:** `Hexbound/Hexbound/Views/Inventory/` + `backend/src/app/api/inventory/`

---

## Overview

Система инвентаря и экипировки. Предметы с rarity, durability, stats. Equip/unequip, sell, use consumables, repair, upgrade.

## Key Files

**iOS Views:**
- `Views/Inventory/ItemDetailSheet.swift` — детали предмета (inspect, equip, sell, use, buy)
- `Views/Inventory/ItemCardView.swift` — ЕДИНСТВЕННЫЙ source of truth для отображения предметов

**ItemCardView Contexts:**
- `.inventory(equippedItem:)` — сравнение, equipped badge, durability
- `.shop(price:isGem:canAfford:meetsLevel:isBuying:)` — цена, affordability
- `.equipment(slotAsset:)` — empty slot placeholder, broken indicator
- `.loot` — minimal для battle result
- `.preview` — full detail для sheets

**iOS Components:**
- `HeroIntegratedCard.swift` — equipment grid + portrait + bars + action pills
- `CurrencyDisplay.swift` — prices (`.mini` size)

**ViewModels:** `InventoryViewModel.swift`, `EquipmentViewModel.swift`
**Service:** `Services/InventoryService.swift`
**Models:** `Models/Item.swift`, `Models/ShopItem.swift`, `Models/Enums/ItemRarity.swift`, `Models/Enums/ItemType.swift`

**Backend Routes:**
| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/api/inventory` | Полный инвентарь |
| `POST` | `/api/inventory/equip` | Надеть предмет |
| `POST` | `/api/inventory/unequip` | Снять предмет |
| `POST` | `/api/inventory/use` | Использовать расходник |
| `POST` | `/api/inventory/sell` | Продать за gold |
| `POST` | `/api/inventory/expand` | Расширить инвентарь |

**Backend Logic:**
- `backend/src/lib/game/item-validation.ts` — валидация, level requirements
- `backend/src/lib/game/equipment-stats.ts` — stat бонусы от экипировки
- `backend/src/lib/game/item-balance.ts` — power score

## Slot System

Universal slots: `amulet` принимает amulet/necklace; `relic` принимает relic/accessory/weapon off-hand.

## Rarity

`common` → `uncommon` → `rare` → `epic` → `legendary`. `ItemRarity.color` — computed property для rarity borders.

## Rules

- ВСЕГДА `ItemCardView` для отображения — никогда inline card styles
- НИКОГДА SF Symbols для валюты — `CurrencyDisplay`
- Optimistic UI для repair/equip

## Related Docs

- `docs/rules/rules-ui-design.md`, `docs/rules/rules-swift.md`
