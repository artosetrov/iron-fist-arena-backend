# API Reference (Source of Truth)
*Derived from backend routes. Updated: 2026-03-29*

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
| POST | /auth/link-account | Yes | Legacy local profile-link sync compatibility route |
| POST | /auth/forgot-password | No | Password reset email (redirects to `/reset-password`) |
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
| GET | /characters/[id]/set-bonuses | Yes | Active set bonuses for equipped items |
| GET | /characters/[id]/stance | Yes | Get current combat stance |

## PvP (`/api/pvp/*`)

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | /pvp/find-match | Yes | Search opponents |
| POST | /pvp/prepare | Yes | Generate battle ticket |
| POST | /pvp/fight | Yes | Start battle (classic, fully resolved server-side) |
| POST | /pvp/resolve | Yes | Finalize battle (server verifies) |
| POST | /pvp/opponents | Yes | Recent opponents list |
| POST | /pvp/revenge/[id] | Yes | Revenge battle |
| GET | /pvp/history | Yes | Match history |
| POST | /pvp/match/start | Yes | Interactive Combat v1 — create live match + return initial snapshot |
| POST | /pvp/strike | Yes | Interactive Combat v1 — resolve ONE round (player + opponent turn) |
| POST | /pvp/match/complete | Yes | Interactive Combat v1 — finalize match, award rewards, return summary |

### Interactive Combat v1 (feature-flagged: `INTERACTIVE_COMBAT_V1=true`)

Interactive Combat splits a single PvP match into round-by-round exchanges. The server is authoritative for all HP state; the client only sends its own zone/active choices per round. If the feature flag is off, `/pvp/match/*` and `/pvp/strike` return 404.

#### `POST /pvp/match/start`

Creates a new live match row (`pvp_matches` with `status = in_progress`) and returns the starting snapshot. Called after `/pvp/prepare` ticketing.

- **Body**: `{ opponent_id: string, ticket_id: string }`
- **Response**: `{ match_id, attacker_hp, defender_hp, max_rounds, actives: InteractiveActiveSlotSnapshot[], opponent_actives: InteractiveActiveSlotSnapshot[] }`

#### `POST /pvp/strike`

Resolves ONE round: the player's attack against the opponent, then (if opponent survives) a counter-strike with server-picked zones derived from seeded RNG (Mulberry32). Both turns are persisted into `pvp_matches.interactive_choices`.

- **Body**: `{ match_id: string, attacker_zone: 'head'|'chest'|'legs', defender_zone: 'head'|'chest'|'legs', active_slot_index?: 0|1|2 }`
- **Response**:
  ```json
  {
    "match_id": "uuid",
    "strike_index": 3,
    "player_strike": { /* Turn */ },
    "opponent_strike": { /* Turn */ } | null,
    "attacker_hp": 140,
    "defender_hp": 0,
    "opp_zones": { "attack": "chest", "defend": "legs" },
    "consumable_type": null,
    "active_fired": null,
    "actives": [ /* InteractiveActiveSlotSnapshot[] */ ],
    "match_finished": true,
    "winner_id": "uuid"
  }
  ```
- **Errors**: `OUT_OF_CONSUMABLE`, `MATCH_STATE_CHANGED` (surfaced in `detail`).
- **Rate limit**: IP-based via `rateLimit('pvp:strike:' + ip, ...)`.
- **Round cap**: `MAX_ROUNDS = 15` — match auto-finishes at round cap if neither player has fallen.

#### `POST /pvp/match/complete`

Finalizes an `in_progress` match. Reads `interactive_choices`, computes rewards, updates ratings (ELO), durability, quests, and returns the full summary + snapshot for the iOS `BattleSummaryView`.

- **Body**: `{ match_id: string }`
- **Response** (selected fields):
  ```json
  {
    "winner_id": "uuid",
    "player_strike": { /* aggregated */ },
    "opp_strike": { /* aggregated */ } | null,
    "turns": [ /* Turn[] */ ],
    "total_turns": 7,
    "post_combat_hp": { "player": 140, "enemy": 0 },
    "rating_before": { "attacker": 1024, "defender": 998 },
    "rating_after":  { "attacker": 1041, "defender": 981 },
    "rewards": { /* gold, xp, items, etc. */ }
  }
  ```
- **Contract note**: iOS reads final HP from `post_combat_hp`, NOT from per-actor `currentHp` fields on the match snapshot (those remain `null` post-Phase 3 and are only populated during classic `/pvp/fight` flow).

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
| POST | /minigames/gold-mine/start | Yes | Begin mining |
| GET | /minigames/gold-mine/status | Yes | Slot status |
| POST | /minigames/gold-mine/collect | Yes | Claim finished |
| POST | /minigames/gold-mine/buy-slot | Yes | Add slot |
| POST | /minigames/gold-mine/boost | Yes | Speed up |

## Shell Game

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | /minigames/shell-game/start | Yes | Initialize |
| POST | /minigames/shell-game/play | Yes | Bet + guess |
| POST | /minigames/shell-game/guess | Yes | Finalize guess |

## Fortune Wheel

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | /minigames/fortune-wheel/spin | Yes | Spin the wheel |

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
| POST | /achievements/claim | Yes | Claim reward by body payload (`{ character_id, achievement_key }`) |
| POST | /achievements/[key]/claim | Yes | Claim by key |

## Leaderboards & State

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /leaderboard | Yes | Top 100 |
| GET | /leaderboard/search | No | Search characters by name (IP-rate-limited) |
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
| POST | /iap/verify-receipt | Yes | Verify Apple receipt (canonical backend route) |
| POST | /iap/verify | Yes | Verify Apple receipt (compatibility alias used by current iOS client) |
| POST | /iap/restore-purchases | Yes | Return verified purchase history (canonical restore surface) |
| POST | /iap/restore | Yes | Restore purchases (compatibility alias) |

## Push Notifications

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | /push/register | Yes | Register device |
| POST | /push/unregister | Yes | Unregister |

## Social (`/api/social/*`)

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /social/friends | Yes | Friend list with status |
| POST | /social/friends | Yes | Send/accept/decline/remove/block friend |
| GET | /social/challenges | Yes | Incoming/outgoing/completed challenges |
| POST | /social/challenges | Yes | Send/accept/decline duel challenge |
| GET | /social/messages | Yes | Conversation list |
| POST | /social/messages | Yes | Send direct message |
| GET | /social/status | Yes | Social badge counts (pending, challenges, messages, revenges) |
| POST | /social/status | Yes | Get friendship status between two characters |

## Milestones

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /milestones | Yes | Milestone progress |
| POST | /milestones | Yes | Claim milestone reward |

## Guild Challenge

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /guild-challenge | Yes | Weekly guild challenge progress |
| POST | /guild-challenge | Yes | Claim community reward |

## Session Summary

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /session-summary | Yes | Session stats (matches, gold, XP, items earned in last 30min) |

## Assets

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | /assets/manifest | No | Asset manifest (items, skins, bosses) with URLs; cached 60s |

## Admin Endpoints

All endpoints below require `admin` role. Admin operations are split between two codebases:
- **Backend API** (`/backend/src/app/api/admin/*`): Core admin operations, moderation, monitoring
- **Admin Panel API** (`/admin/src/app/api/*`): Admin dashboard CRUD operations (items, events, dungeons, etc.)

### Backend Admin API (Core Operations)

| Method | Path | Purpose |
|--------|------|---------|
| GET | /admin/users | Search/browse users |
| POST | /admin/ban | Ban user (expects `{user_id, reason}`) |
| POST | /admin/unban | Unban user (expects `{user_id}`) |
| GET | /admin/economy | Economy overview |
| GET | /admin/matches | Browse PvP matches |
| GET | /admin/stats | Game statistics |
| GET | /admin/achievements | View/search achievements |
| POST | /admin/achievements | Create/update achievement |
| GET | /admin/skills | View/search skills |
| POST | /admin/skills | Create/update skill |
| GET | /admin/passives | View passive tree |
| POST | /admin/passives | Create/update passive |
| POST | /admin/passives/connections | Manage passive connections |
| GET | /admin/characters | Character lookup |
| GET | /admin/design-tokens | Get UI theme tokens |
| POST | /admin/design-tokens | Update UI tokens |
| POST | /admin/events | Create/send events |
| POST | /admin/seasons | Create/manage season |
| GET/POST | /admin/hub-layout | Manage hub building positions |
| GET/POST | /admin/dungeon-map-layout | Manage dungeon node positions |
| GET | /admin/iap | View IAP analytics |
| POST | /admin/item-balance/config | Update balance config |
| GET | /admin/item-balance/power-scores | Calculate item power scores |
| GET | /admin/item-balance/profiles | Get balance profiles |
| POST | /admin/item-balance/suggest | Generate balance suggestions |
| POST | /admin/item-balance/apply-suggestions | Apply balance changes |
| POST | /admin/item-balance/validate | Validate balance changes |
| POST | /admin/item-balance/simulate/combat | Combat simulation |
| POST | /admin/item-balance/simulate/item-impact | Item impact analysis |
| POST | /admin/item-balance/simulate/matchups | Matchup simulation |
| GET | /admin/item-balance/simulation-history | Simulation history |

### Admin Panel API (Dashboard CRUD)

Admin dashboard operations are handled by the Admin Panel's own Next.js application (`/admin`). These are NOT backend API routes but are called by the admin dashboard frontend:

| Method | Path | Purpose |
|--------|------|---------|
| GET/POST | /api/items | CRUD items |
| GET/POST | /api/events | CRUD events |
| GET/POST | /api/seasons | CRUD seasons |
| GET/POST | /api/dungeons | CRUD dungeons |
| GET | /api/dungeons/[id] | Get dungeon by ID |
| GET/POST | /api/dungeon-map-layout | Manage dungeon layout |
| GET/POST | /api/admin/item-balance/* | Balance configuration suite |
| POST | /api/upload | Upload assets (images) |
| POST | /api/settings/role | Manage admin roles |
| POST | /api/auth/login | Admin login |
| POST | /api/auth/logout | Admin logout |

### NOT IMPLEMENTED

The following endpoints are documented in legacy docs but do not exist:
- `POST /admin/users/[id]/grant` — Grant gold/gems/items (not implemented)
- `POST /admin/users/[id]/reset` — Reset inventory (not implemented)
- `GET/POST /admin/consumables` — CRUD consumables (not implemented)
- `GET/POST /admin/appearances` — CRUD cosmetics (not implemented)
- `GET/POST /admin/mail` — Broadcast/segment mail (not implemented)
- `POST /admin/push/campaign` — Create push campaign (not implemented)
- `GET/POST /admin/feature-flags` — Toggle features (not implemented)
- `GET/POST /admin/config` — Manage game config (not implemented)
- `POST /admin/config/snapshot` — Save/rollback config (not implemented)
- `GET /admin/balance/simulate` — Run balance sims (not implemented)
