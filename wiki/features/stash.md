# Feature: Stash

> Single-file map of every file that touches the stash — account-level (not character-level) shared storage for items, 100-slot cap, deposit / withdraw flow.

## One-liner

Users have a single shared stash across all their characters (100 slots). Deposit from a character's equipment inventory, withdraw to any character. Preserves upgrade level, durability, and rolled stats.

## Status

- **Phase:** In production (shipped 2026-04-13; see memory `feedback_verify_prod_tables_before_release`)
- **Owner / last hands:** Artem

## Entry points

- **iOS screen:** `Hexbound/Hexbound/Views/Minigames/StashDetailView.swift` — stash browser with deposit/withdraw tabs
- **Player action:** Hub → Stash building OR Hero inventory → "Move to stash" on an equipment row

## Backend

### Routes

- `GET  /api/stash`            — `backend/src/app/api/stash/route.ts` — list stored items (paginated, filtered by type/rarity if needed)
- `POST /api/stash/deposit`    — `backend/src/app/api/stash/deposit/route.ts` — move `EquipmentInventory` row → `StashItem` row
- `POST /api/stash/withdraw`   — `backend/src/app/api/stash/withdraw/route.ts` — move `StashItem` row → `EquipmentInventory` row of target character

### Business logic

- Deposit: unequip if equipped → transfer row atomically → increment stash slot count → enforce 100-cap
- Withdraw: validate target character belongs to user → insert into `EquipmentInventory` with preserved `upgradeLevel` / `durability` / `rolledStats` → delete `StashItem`
- Slot cap enforced server-side — client cannot bypass

### Prisma models touched

- `StashItem` (line 542, `@@map("stash_items")`) — pivot row, user-scoped not character-scoped
- `User.stashItems` (line 271) — relation
- `Item.stashItems` (line 495) — relation
- Key fields preserved across move: `upgradeLevel`, `durability`, `maxDurability`, `rolledStats` (JSON)

### Constraints

- **Account-scoped, not character-scoped.** `userId` FK, NOT `characterId`. This is the whole point of stash.
- Max 100 items per user (enforced in deposit route).

## iOS

### Views

- `Hexbound/Hexbound/Views/Minigames/StashDetailView.swift` — list + deposit/withdraw actions
  - (filed under Minigames/ in the tree; this is a legacy grouping — stash is a core system, not a minigame)

### ViewModel

- `Hexbound/Hexbound/Views/Minigames/StashViewModel.swift` — list state, filter, deposit/withdraw actions

### Services

- `Hexbound/Hexbound/Services/StashService.swift` — list + deposit + withdraw API wrappers

### Cache

- `GameDataCache.stash` — stash list (invalidated on deposit/withdraw)
- `GameDataCache.inventory.equipment` — must ALSO invalidate on deposit/withdraw (the item moved)

## Admin

- No dedicated admin page for stash. Adjacent item management lives in:
  - `admin/src/app/(dashboard)/items/page.tsx`
  - `admin/src/app/(dashboard)/items/items-client.tsx`
- Stash rows themselves are still inspected through Supabase console if needed

## Docs

- `docs/02_product_and_features/GAME_SYSTEMS.md` — stash overview
- Memory: `feedback_verify_prod_tables_before_release` (Stash 04-13 incident — table not in prod Supabase at deploy time)

## Notable gotchas

- **Account-scoped = cross-character transfer.** This is the whole design; rolling a good item on one character and moving it to another is the main use case. Don't treat it as character-local.
- **Dual-invalidation.** Deposit moves the row — BOTH stash cache AND source character's inventory cache must invalidate. Single-invalidate = stale UI shows the item in two places.
- **Preserve everything.** `upgradeLevel`, `durability`, `rolledStats` must survive the round-trip. Never regenerate. Never reset.
- **100-slot cap is hard.** UI must preflight against cap; backend is the source of truth but client should block the action before the user picks an item.
- **Not tradeable.** Stash is PLAYER-SCOPED. Not a player-to-player trade system. Do not add a recipient field.
- **Prod-table rule.** When schema changed to add `StashItem`, table was missing in prod Supabase → 500s. Verify via MCP before deploy. See memory.

## Tests / fixtures

- No dedicated stash backend test file is checked in today

## Related features

- [[inventory]] — source/destination of stash moves (`EquipmentInventory`)
- [[characters]] — withdraw target is a character under the same user
- [[auth]] — scope is `User`, not `Character`
