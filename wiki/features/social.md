# Feature: Social

> Single-file map of every file that touches friends + challenges + messaging + guild — the entire social stack.

## One-liner

Players add friends, send direct messages, issue PvP challenges, and participate in guild hall (allies/duels/scrolls). Opponent profile card (Challenge/Message/AddFriend) is the shared entry point.

## Status

- **Phase:** Friends + challenges + DMs in production. Guild drafted 2026-04-01 (see memory `project_guild_system_spec`).
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/Social/GuildHallDetailView.swift` — guild hub host
  - `Hexbound/Hexbound/Views/Social/GuildHallAlliesTab.swift` — friends/members
  - `Hexbound/Hexbound/Views/Social/GuildHallDuelsTab.swift` — challenge queue
  - `Hexbound/Hexbound/Views/Social/GuildHallScrollsTab.swift` — guild-wide messaging/notes
- **Shared entry:** Opponent Profile card (Challenge / Message / AddFriend buttons) reused from leaderboard / arena / mail (see memory `opponent_profile_feature`)
- **Player action:** Hub → Guild Hall building OR Leaderboard row tap

## Backend

### Routes

#### Friendship
- `GET/POST /api/social/friends`           — `backend/src/app/api/social/friends/route.ts` — list + add/accept/decline
- `GET  /api/social/relationship`          — `backend/src/app/api/social/relationship/route.ts` — relationship state with a specific character
- `GET  /api/social/status`                — `backend/src/app/api/social/status/route.ts` — online/last-seen status

#### Challenges
- `GET/POST /api/social/challenges`        — `backend/src/app/api/social/challenges/route.ts` — issue / list PvP challenges
- `GET/POST /api/guild-challenge`          — `backend/src/app/api/guild-challenge/route.ts` — guild-scoped challenges

#### Direct messaging
- `GET/POST /api/social/messages`          — `backend/src/app/api/social/messages/route.ts` — player-to-player DMs (see also [[mail]] for system mail)

### Business logic

- `backend/src/lib/game/social.ts` — friendship state machine, block/unblock logic
- `backend/src/lib/game/challenges.ts` — challenge creation, accept, expire
- `backend/src/lib/game/guild.ts` (if present) — guild membership + permissions

### Prisma models touched

- `Friendship` (line 1533, `@@map("friendships")`) — pair-keyed friendship row
- `Challenge` (line 1573, `@@map("challenges")`) — PvP challenge request (challenger → target, status, expiresAt)
- `GuildChallenge` (line 116, `@@map("guild_challenges")`) — guild-scope challenges
- `DirectMessage` (line 1550, `@@map("direct_messages")`) — player-to-player DM (see [[mail]])

## iOS

### Views

- `Hexbound/Hexbound/Views/Social/GuildHallDetailView.swift` — host screen
- `Hexbound/Hexbound/Views/Social/GuildHallAlliesTab.swift` — friend list + status
- `Hexbound/Hexbound/Views/Social/GuildHallDuelsTab.swift` — challenge list
- `Hexbound/Hexbound/Views/Social/GuildHallScrollsTab.swift` — guild feed / notes

### ViewModel

- `Hexbound/Hexbound/Views/Social/GuildHallViewModel.swift` — tab state, action handlers

### Services

- `Hexbound/Hexbound/Services/SocialService.swift` — friends + relationship + status + messages
- `Hexbound/Hexbound/Services/ChallengeService.swift` — challenge CRUD
- `Hexbound/Hexbound/Services/MessageService.swift` — shared with mail system for DM delivery

### Cache

- `GameDataCache.friends` — friend list
- `GameDataCache.challenges` — active incoming/outgoing challenges
- `GameDataCache.directMessages` — DM threads

## Admin

- `admin/src/app/(dashboard)/social/` — moderation (mute, ban, clear DMs)

## Docs

- `docs/02_product_and_features/GAME_SYSTEMS.md` — social systems overview
- Memory: `project_guild_system_spec` (guild draft 2026-04-01), `opponent_profile_feature` (tap-row actions)

## Notable gotchas

- **Shared opponent profile.** Challenge / Message / AddFriend buttons on the Opponent Profile card work everywhere — leaderboard, arena, mail. Do NOT re-implement.
- **Friendship is pair-keyed.** Always store canonical `(charA, charB)` order OR handle both orderings in query.
- **Challenge expires.** `Challenge.expiresAt` — server cleans up; don't trust unexpired state cached on client.
- **Guild spec in flux.** Full guild system (chat, rank, bank) is still design phase. Today: Guild Hall UI exists; underlying features mostly social primitives.
- **DMs separate from mail.** `DirectMessage` (player-to-player) vs `MailRecipient` (system broadcast). Don't conflate. See [[mail]].
- **Rate limits.** Friend requests and challenges need rate limits to prevent spam.

## Tests / fixtures

- `backend/src/__tests__/social/*` (if present)

## Related features

- [[mail]] — system mail and direct messages share the UI but different backend tables
- [[leaderboard]] — tap row → opponent profile → social actions
- [[pvp-combat]] — challenges funnel directly into PvP
- [[opponent-profile]] — the shared profile component used everywhere (documented as a separate project memory, not yet a feature file)
