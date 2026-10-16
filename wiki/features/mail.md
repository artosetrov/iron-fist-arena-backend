# Feature: Mail

> Single-file map of every file that touches the in-game mail/inbox — system-authored messages with optional attached rewards and per-player claim/read/delete state.

## One-liner

System and admin broadcast mail lands in each player's inbox; some carry attached rewards claimable from the message. Direct player↔player DMs are a separate system exposed via social/messages.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/Inbox/InboxDetailView.swift` — inbox list + message detail
  - `Hexbound/Hexbound/Views/Inbox/InboxRowView.swift` — single-row cell (2 Figma variants: unread/read)
- **Player action:** Hub → Inbox icon (unread badge) → open message → Claim / Delete

## Backend

### Routes

- `GET  /api/mail`                   — `backend/src/app/api/mail/route.ts` — paginated inbox
- `GET  /api/mail/unread-count`      — `backend/src/app/api/mail/unread-count/route.ts` — badge count
- `POST /api/mail/[id]/read`         — `backend/src/app/api/mail/[id]/read/route.ts` — mark read
- `POST /api/mail/[id]/claim`        — `backend/src/app/api/mail/[id]/claim/route.ts` — claim attached reward
- `POST /api/mail/[id]/delete`       — `backend/src/app/api/mail/[id]/delete/route.ts` — delete single
- Direct messaging: `POST /api/social/messages/route.ts` — player-to-player DMs (see [[social]])

### Business logic

- `backend/src/lib/game/mail.ts` — reward resolver, claim gating, broadcast writer (admin)

### Prisma models touched

- `MailMessage` (line 1145) — catalog of sent mails (subject, body, reward config, sender, createdAt)
- `MailRecipient` (line 1165) — per-recipient delivery row with `readAt`, `claimedAt`, `deletedAt`
- `DirectMessage` (line 1550, `@@map("direct_messages")`) — player-to-player DMs (separate from system mail)

## iOS

### Views

- `Hexbound/Hexbound/Views/Inbox/InboxDetailView.swift` — split list+detail
- `Hexbound/Hexbound/Views/Inbox/InboxRowView.swift` — row component

### ViewModel

- `Hexbound/Hexbound/Views/Inbox/InboxViewModel.swift` — list, unread count, read/claim/delete actions

### Services

- `Hexbound/Hexbound/Services/MessageService.swift` — inbox + DM API wrapper

### Cache

- `GameDataCache.inbox` — list + unread count (invalidated on read/claim/delete)

### Screen states & icons (2026-10-16)

- **Empty tabs** use `EmptyStateScene` with pen-and-ink art from `Assets.xcassets/EmptyStates` — ALL `empty-inbox`, BATTLES `empty-battles`, SCROLLS `empty-scrolls`, SYSTEM `empty-system` (prompts: `docs/08_prompts/EMPTY_STATE_ICONS_PROMPTS.md`). Each one has a single next step: Arena (ALL / BATTLES, and SCROLLS below level 8), leaderboard "Find a Warrior" (SCROLLS once `ranks` is unlocked), Daily Quests (SYSTEM). Empty tabs are pull-to-refresh too.
- **Tab badges** — `TabSwitcher(badgeStyle: .count)` shows unread per tab from `InboxViewModel.unreadCount(for:)`; ALL has none (the title already says "N unread").
- **Row crests are painted assets, not SF Symbols** — battle report: opponent portrait (class crest if none) + `icon-wins` / `icon-losses`; duel challenge `icon-fights`; letter with unclaimed rewards `hud-gift`; Game Master news `hud-quests`; other letters `hud-inbox`. Rating swing `reward-rating-up/down`, rewards `icon-gold` / `icon-gems` / `icon-xp` / `reward-loot`, expand arrow `ui-arrow-down`.
- **Delete** is a quiet text button under the actions, so it is never hit instead of Claim.

### Reward surface

- Mail attachment claim now presents the reward through the shared `ClaimRewardModalView` ceremony, not a success toast.
- `InboxViewModel` writes into the root-level `AppState.claimRewardConfig`, because the inbox screens do not own a local claim modal slot.
- Error paths stay as toasts; only the successful currency / loot payout is ceremonial. See [[why-reward-modal-over-toast]].

## Admin

- `admin/src/app/(dashboard)/mail/page.tsx` — mail admin page
- `admin/src/app/(dashboard)/mail/mail-client.tsx` — compose / segment / reward attachment surface

## Docs

- `docs/02_product_and_features/GAME_SYSTEMS.md` — inbox/mail overview
- `docs/05_admin_panel/ADMIN_CAPABILITIES.md` — broadcast tooling

## Notable gotchas

- **Two systems under "messaging".** `MailMessage` + `MailRecipient` = SYSTEM mail with optional rewards. `DirectMessage` = player-to-player DM. Do not conflate.
- **Unread count is hot.** Badge updates on every app resume — `unread-count` endpoint must be fast and cacheable.
- **Claim idempotency.** `claimedAt` timestamp gates re-claim — double-tap must return already-claimed state, not double-grant.
- **Delete != unsend.** Player delete only soft-deletes `MailRecipient`, not `MailMessage`. Other recipients keep the message.
- **Broadcast pressure.** Admin broadcasting to N users writes N `MailRecipient` rows in a transaction — watch for timeouts on very large batches.

## Tests / fixtures

- `backend/tests/api/mail-list.test.ts` — inbox-list contract coverage
- No broader dedicated `mail/*` backend suite is checked in today beyond the focused inbox route coverage

## Related features

- [[social]] — direct player messaging routes through `/api/social/messages`
- [[shop]] / [[battle-pass]] — mail is a delivery channel for purchase receipts and BP nudges
- [[events]] — event rewards can be delivered via mail attachments
