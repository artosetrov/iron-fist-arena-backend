# Rules: Economy / Shop / IAP

> **Домен:** Валюты, магазин, цены, IAP, gold sinks/faucets, Battle Pass economy
> **Когда читать:** Работа с shop, pricing, rewards, purchases, gold mine
> **НЕ покрывает:** Combat formulas, UI tokens, Deploy

---

## Source of Truth

- Economy design: `docs/02_product_and_features/ECONOMY.md`
- Balance constants: `docs/06_game_systems/BALANCE_CONSTANTS.md`
- Admin config keys: `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- Live config: `backend/src/lib/game/live-config.ts`

## Currencies

- **Gold** — основная, earn in-game
- **Gems** — premium, IAP + daily gem card + rare drops
- **Arena Tokens** — PvP rewards (если применимо)

## Economy Principles

- **Monetization = acceleration**, never hard-block fair play
- Server-authoritative prices — клиент не считает стоимость
- All purchase validation INSIDE Prisma transaction with row lock

## TOCTOU Prevention (CRITICAL)

**Все purchase routes:**
1. `$transaction(async (tx) => { ... })` с `Serializable` isolation
2. `SELECT FOR UPDATE` row lock
3. Validate limits ВНУТРИ транзакции, не до

## Shop System

- `ItemCardView(.shop(...))` для отображения товаров
- `CurrencyDisplay(.mini)` для цен на карточках
- Никогда SF Symbols для валюты — только `icon-gold` / `icon-gems`
- ShopItemCardView — DEPRECATED, использовать ItemCardView

## Gold Mine

- Badge: "READY" когда slots с status "ready"
- Building ID: `gold-mine`
- Cache: `cache.goldMineSlots`

## Battle Pass Economy

- Free tier + Premium tier
- Claimable rewards tracked via level ≤ current
- Badge на hub building: count of claimable tiers

## Daily Systems Economy

- Daily quests: gold/XP rewards
- Daily login: reward tiers, consecutive days
- Daily gem card: steady gem income

## Atomic Increments

Все counter increments — через atomic SQL:
```sql
UPDATE ... SET progress = LEAST(progress + $1, target) WHERE ...
```
НЕ read-then-write.

## Optimistic UI for Purchases

- Обновляй баланс мгновенно → API в background → revert при ошибке
- Applied: ShopVM.buy(), BattlePassVM.claimReward(), DailyQuestsVM.claimQuest()
