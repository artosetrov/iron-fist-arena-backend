# API Reference (Source of Truth)
*Derived from backend routes. Updated: 2026-03-19*

## Auth (`/api/auth/*`)

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | /auth/login | No | Email/password login |
| POST | /auth/register | No | Create account |
| POST | /auth/google | No | Google OAuth |
| POST | /auth/apple | No | Apple OAuth |
| POST | /auth/guest | No | Guest account |
| POST | /auth/guest-login | No | Resume guest |
| POST | /auth/upgrade-guest | Yes | Convert guest to real |
| POST | /auth/link-account | Yes | Merge guest with social |
| POST | /auth/forgot-password | No | Password reset |
| POST | /auth/sync-user | Yes | Sync user data |

## Characters (`/api/characters/*`)

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | /characters | Yes | Create character |
| GET | /characters/[id] | Yes | Get character |
| PUT | /characters/[id] | Yes | Update character |
| POST | /characters/check-name | Yes | Check name availability |
| PUT | /characters/[id]/appearance | Yes | Update appearance |
| PUT | /characters/[id]/origin | Yes | Change origin |
| PUT | /characters/[id]/profile | Yes | Update profile |
| PUT | /characters/[id]/stance | Yes | Set combat stance |
| POST | /characters/[id]/allocate-stats | Yes | Allocate stat points |
| POST | /characters/[id]/respec-stats | Yes | Reset stats (costs gems) |

## PvP (`/api/pvp/*`)

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | /pvp/find-match | Yes | Search opponents |
| POST | /pvp/prepare | Yes | Generate battle ticket |
| POST | /pvp/fight | Yes | Start battle |
| POST | /pvp/resolve | Yes | Finalize battle (server verifies) |
| POST | /pvp/opponents | Yes | Recent opponents list |
| POST | /pvp/revenge/[id] | Yes | Revenge battle |
| GET | /pvp/history | Yes | Match history |

## Combat/Training

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | /combat/simulate | Yes | Training vs AI |
| GET | /combat/status | Yes | Stamina/training state |
| POST | /combat/buy-extra | Yes | Buy extra stamina |

## Dungeons

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /dungeons/list | Yes | Available dungeons |
| GET | /dungeons | Yes | Dungeon metadata |
| POST | /dungeons/start | Yes | Start dungeon run |
| POST | /dungeons/fight | Yes | Combat |
| POST | /dungeons/run/[id]/fight | Yes | Floor fight |
| POST | /dungeons/abandon | Yes | Abandon run |

## Dungeon Rush

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | /dungeon-rush/start | Yes | Begin rush |
| POST | /dungeon-rush/fight | Yes | Rush combat |
| POST | /dungeon-rush/resolve | Yes | Finalize |
| POST | /dungeon-rush/abandon | Yes | Exit rush |
| POST | /dungeon-rush/shop-buy | Yes | Buy during run |
| GET | /dungeon-rush/status | Yes | Run state |

## Inventory

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /inventory | Yes | List all items |
| POST | /inventory/equip | Yes | Equip item |
| POST | /inventory/unequip | Yes | Remove item |
| POST | /inventory/use | Yes | Use consumable |
| POST | /inventory/sell | Yes | Sell item |
| POST | /inventory/expand | Yes | Unlock slots |

## Shop

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /shop/items | Yes | Item catalog |
| GET | /shop/offers | Yes | Active offers |
| POST | /shop/buy | Yes | Purchase item |
| POST | /shop/buy-gems | Yes | Buy gems (IAP) |
| POST | /shop/buy-gold | Yes | Buy gold (IAP) |
| POST | /shop/buy-consumable | Yes | Buy potion |
| POST | /shop/upgrade | Yes | Upgrade equipment |
| POST | /shop/repair | Yes | Restore durability |

## Skills

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /skills | Yes | Skill catalog |
| GET | /skills/character | Yes | Learned skills |
| POST | /skills/learn | Yes | Unlock skill |
| POST | /skills/equip | Yes | Assign to loadout |
| POST | /skills/upgrade | Yes | Improve rank |

## Passives

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /passives/tree | Yes | Full passive tree |
| GET | /passives/character | Yes | Unlocked nodes |
| POST | /passives/unlock | Yes | Spend point |
| POST | /passives/respec | Yes | Reset tree |
| POST | /passives/connections | Admin | Manage connections |

## Battle Pass

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /battle-pass | Yes | Season info |
| POST | /battle-pass/claim/[level] | Yes | Claim reward |
| POST | /battle-pass/buy-premium | Yes | Upgrade to premium |

## Gold Mine

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | /gold-mine/start | Yes | Begin mining |
| GET | /gold-mine/status | Yes | Slot status |
| POST | /gold-mine/collect | Yes | Claim finished |
| POST | /gold-mine/buy-slot | Yes | Add slot |
| POST | /gold-mine/boost | Yes | Speed up |

## Shell Game

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | /shell-game/start | Yes | Initialize |
| POST | /shell-game/play | Yes | Bet + guess |
| POST | /shell-game/guess | Yes | Finalize guess |

## Daily Systems

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /daily-login | Yes | Login state |
| POST | /daily-login/claim | Yes | Claim reward |
| GET | /quests/daily | Yes | Quest list |
| POST | /quests/daily/bonus | Yes | Claim bonus |

## Mail

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /mail | Yes | Inbox |
| GET | /mail/unread-count | Yes | Unread count |
| POST | /mail/[id]/read | Yes | Mark read |
| POST | /mail/[id]/claim | Yes | Claim attachments |
| POST | /mail/[id]/delete | Yes | Delete message |

## Achievements

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /achievements | Yes | All + progress |
| POST | /achievements/claim/[key] | Yes | Claim reward |
| POST | /achievements/[key]/claim | Yes | Claim by key |

## Leaderboards & State

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /leaderboard | Yes | Top 100 |
| GET | /game/init | Yes | Full game state |
| GET | /me | Yes | Current user |

## User Management

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | /user/email | Yes | Update email |
| POST | /user/password | Yes | Change password |
| GET | /stamina | Yes | Current stamina |
| POST | /stamina/refill | Yes | Restore stamina |

## Cosmetics & Systems

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /appearances | Yes | Available skins |
| GET | /consumables | Yes | Consumable inventory |
| POST | /consumables/use | Yes | Use consumable |
| GET | /events/active | Yes | Active events |
| GET | /flags | Yes | Feature flags |
| GET | /design-tokens | Yes | UI theme tokens |

## Progression & Prestige

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /prestige | Yes | Prestige info |
| POST | /prestige | Yes | Execute prestige |

## In-App Purchases

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /iap/products | Yes | IAP catalog |
| POST | /iap/verify-receipt | Yes | Verify Apple receipt |
| POST | /iap/verify | Yes | Verify transaction |
| POST | /iap/restore-purchases | Yes | Restore purchases |
| POST | /iap/restore | Yes | Restore (alt) |

## Push Notifications

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | /push/register | Yes | Register device |
| POST | /push/unregister | Yes | Unregister |

## Admin Endpoints

All endpoints below require `admin` role. Key admin capabilities:

| Method | Path | Purpose |
|--------|------|---------|
| GET | /admin/users | Search/browse users |
| POST | /admin/users/[id]/ban | Ban user |
| POST | /admin/users/[id]/unban | Unban user |
| POST | /admin/users/[id]/grant | Grant gold/gems/items |
| POST | /admin/users/[id]/reset | Reset inventory |
| GET/POST | /admin/items | CRUD items |
| GET/POST | /admin/consumables | CRUD consumables |
| GET/POST | /admin/skills | CRUD skills |
| GET/POST | /admin/passives | CRUD passives |
| GET/POST | /admin/achievements | CRUD achievements |
| GET/POST | /admin/events | CRUD events |
| GET/POST | /admin/seasons | CRUD seasons |
| GET/POST | /admin/dungeons | CRUD dungeons |
| GET/POST | /admin/appearances | CRUD cosmetics |
| GET | /admin/economy | Economy overview |
| GET | /admin/matches | Browse PvP matches |
| GET | /admin/stats | Game statistics |
| GET/POST | /admin/design-tokens | Manage UI tokens |
| GET/POST | /admin/mail | Broadcast/segment mail |
| POST | /admin/push/campaign | Create push campaign |
| GET/POST | /admin/feature-flags | Toggle features |
| GET/POST | /admin/config | Manage game config |
| POST | /admin/config/snapshot | Save/rollback config |
| GET | /admin/balance/simulate | Run balance sims |
