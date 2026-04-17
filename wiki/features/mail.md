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

## Admin

- `admin/src/app/(dashboard)/mail/` — compose & broadcast mail, attach rewards, target segments

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

- `backend/src/__tests__/mail/*` (if present)

## Related features

- [[social]] — direct player messaging routes through `/api/social/messages`
- [[shop]] / [[battle-pass]] — mail is a delivery channel for purchase receipts and BP nudges
- [[events]] — event rewards can be delivered via mail attachments
