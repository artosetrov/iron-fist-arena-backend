# Feature: Inventory

> Single-file map of every file that touches the character inventory — equipment, consumables, equip/unequip, sell, upgrade, inventory expansion.

## One-liner

Each character owns a per-character EquipmentInventory (weapons/armor/accessories) + ConsumableInventory (potions/tokens); items can be equipped, upgraded, used, sold.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/Hero/HeroInventoryTab.swift` — inventory tab of hero screen
  - `Hexbound/Hexbound/Views/Inventory/ItemDetailSheet.swift` — item tap sheet (3 contexts: Inventory / Shop / Loot)
  - `Hexbound/Hexbound/Views/Inventory/ItemDetailSections.swift`, `ItemDetailActions.swift` — sheet subcomponents
  - `Hexbound/Hexbound/Views/Inventory/ItemCardView.swift` — unified item cell (see memory `itemcard_unified_refactor`)
- **Player action:** Hero screen → Inventory tab → tap item → equip / unequip / sell / use

## Backend

### Routes

- `GET  /api/inventory`             — `backend/src/app/api/inventory/route.ts` — current equipment + consumables
- `POST /api/inventory/equip`       — `backend/src/app/api/inventory/equip/route.ts` — equip an item to slot
- `POST /api/inventory/unequip`     — `backend/src/app/api/inventory/unequip/route.ts` — unequip slot
- `POST /api/inventory/use`         — `backend/src/app/api/inventory/use/route.ts` — consume a consumable
- `POST /api/inventory/sell`        — `backend/src/app/api/inventory/sell/route.ts` — sell equipment for gold
- `POST /api/inventory/expand`      — `backend/src/app/api/inventory/expand/route.ts` — purchase inventory slot expansion

### Business logic

- `backend/src/lib/game/inventory.ts` — equip/unequip rules, slot mapping, class-restriction check
- `backend/src/lib/game/items.ts` — item stat resolution (base + upgrade + roll)
- `backend/src/lib/game/set-bonuses.ts` — equipped-set resolver (referenced by character profile)
- `backend/src/lib/game/consumable-effects.ts` — `use` effect resolver

### Prisma models touched

- `Item` (line 470) — global item catalog (name, type, rarity, base stats, set name, buy/sell price, drop chance, upgrade config)
- `EquipmentInventory` (line 503, `@@map("equipment_inventory")`) — per-character owned equipment (with upgrade, durability, isEquipped, equippedSlot, rolled stats)
- `ConsumableInventory` (line 528, `@@map("consumable_inventory")`) — per-character stackable consumables (unique `(characterId, consumableType)`)
- `StashItem` — account-level stash (see [[stash]])
- `DungeonDrop` — links Items as drops (see [[dungeons]])

### Game enums (CLAUDE.md-canonical)

- `ItemType`: weapon, helmet, chest, gloves, legs, boots, accessory, amulet, belt, relic, necklace, ring, consumable
- `ItemRarity`: common, uncommon, rare, epic, legendary
- `EquippedSlot`: enum for slot binding

## iOS

### Views

- `Hexbound/Hexbound/Views/Inventory/ItemCardView.swift` — SINGLE SOURCE OF TRUTH for all item cell rendering (9 Figma variants: 5 rarities × contexts)
- `Hexbound/Hexbound/Views/Inventory/ItemDetailSheet.swift` + `ItemDetailSections.swift` + `ItemDetailActions.swift` — tap modal
- `Hexbound/Hexbound/Views/Hero/HeroInventoryTab.swift` — grid host

### ViewModels

- `Hexbound/Hexbound/Views/Inventory/InventoryViewModel.swift` — list state, filter, sort
- `Hexbound/Hexbound/Views/Inventory/EquipmentViewModel.swift` — equipped slots state

### Services

- `Hexbound/Hexbound/Services/InventoryService.swift` — equip/unequip/use/sell/expand API wrapper

### Cache

- `GameDataCache.equipment` — equipment list + equipped state
- `GameDataCache.consumables` — consumable counts

## Admin

- `admin/src/app/(dashboard)/items/` — item catalog editor (stats, rarity, drop chance)

## Docs

- `docs/04_database/SCHEMA_REFERENCE.md` — Item + EquipmentInventory fields
- `docs/06_game_systems/BALANCE_CONSTANTS.md` — rarity rates

## Notable gotchas

- **Server-authoritative stat calc.** `EquipmentInventory.rolledStats` + `upgradeLevel` + set bonuses resolved server-side. Client displays.
- **Class restriction.** `Item.classRestriction` must match `Character.characterClass` at equip time — mismatch = 400.
- **Unique per consumableType.** `ConsumableInventory` has `@@unique([characterId, consumableType])` — stacking logic uses `quantity++` not insert.
- **Optimistic UI pattern.** Equip / use / sell must update UI instantly, rollback on API failure (see memory `feedback_optimistic_ui_everywhere`).
- **`ItemCardView` is the only cell.** Do NOT re-implement item cells per screen — ItemCard handles 9 Figma variants (Common→Legendary × Inventory/Shop/Loot context).
- **Flat response shape.** Shop endpoints (and any mutation returning currency) must return flat `{ gold, gems, ... }` — nested `character` breaks `ShopService.updateCharacter` (see memory `feedback_flat_response_shape`).

## Tests / fixtures

- `backend/src/__tests__/inventory/*` (if present)

## Related features

- [[shop]] — shop purchases land in EquipmentInventory/ConsumableInventory
- [[dungeons]] / [[dungeon-rush]] — drops land here
- [[stash]] — account-wide shared storage (cross-character)
- [[characters]] — equipped gear affects derived stats
- [[pvp-combat]] — consumable use during fight
