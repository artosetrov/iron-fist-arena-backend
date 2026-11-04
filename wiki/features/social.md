# Feature: Social

> Single-file map of every file that touches friends + challenges + messaging + guild — the entire social stack.

## One-liner

Players add friends, send direct messages, issue PvP challenges, and participate in guild hall (allies/duels/scrolls). Opponent profile card (Challenge/Message/AddFriend) is the shared entry point.

## Status

- **Phase:** Friends + challenges + DMs in production. Broader guild-system expansion still lives as a historical draft in `docs/02_product_and_features/GUILD_SYSTEM_SPEC.md`.
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/Social/GuildHallDetailView.swift` — guild hub host
  - `Hexbound/Hexbound/Views/Social/GuildHallAlliesTab.swift` — friends/members
  - `Hexbound/Hexbound/Views/Social/GuildHallDuelsTab.swift` — challenge queue
  - `Hexbound/Hexbound/Views/Social/GuildHallScrollsTab.swift` — direct-message conversations and thread view
- **Shared entry:** Opponent Profile card (Challenge / Message / AddFriend buttons) reused from leaderboard / arena / mail
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
- `backend/src/lib/game/guild-challenge.ts` — guild-scoped challenge helpers

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
- `Hexbound/Hexbound/Views/Social/GuildHallScrollsTab.swift` — DM conversation list + thread UI
- `Hexbound/Hexbound/Views/Social/GuildHallChrome.swift` — hall header (`building-guild-hall`), pennant tabs with emblems and badges, section labels
- `Hexbound/Hexbound/Views/Social/GuildHallCards.swift` — `HeroFramedPortrait` (portrait in the `HeroCardTier` frame of the level), `AllyHeroCard`, parchment letters with wax seals

### The look (2026-11-04, canvas "A · Зал гильдии")

- The hall header scrolls away; the pennant tabs pin under an opaque nav bar (`LazyVStack` pinned section header).
- The Chronicler (`NPCSpeechBubble`, `npc-chronicler-face`) says one line about the open tab: banners raised, sealed scrolls, challenges on the door.
- Allies are hero cards in a 3-column grid (frame by level, status light, class crest); the card opens the old row menu (profile, challenge, scroll, remove, block). Warriors from recent Arena fights sit under them with RAISE BANNER (= ally request).
- Scrolls are letters on `rush2-map-parchment`, sealed with `rush2-map-seal` pressed with the sender's class crest: intact + gold count while unread, cracked once read. WRITE A SCROLL lists your allies, or opens the Leaderboard.

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

- `admin/src/app/(dashboard)/social/page.tsx` — read-only social review page for friendships, direct messages, and challenge history

## Docs

- `docs/02_product_and_features/GAME_SYSTEMS.md` — social systems overview
- `docs/02_product_and_features/GUILD_SYSTEM_SPEC.md` — historical draft for a fuller future guild system, not a live runtime spec

## Notable gotchas

- **Shared opponent profile.** Challenge / Message / AddFriend buttons on the Opponent Profile card work everywhere — leaderboard, arena, mail. Do NOT re-implement.
- **Friendship is pair-keyed.** Always store canonical `(charA, charB)` order OR handle both orderings in query.
- **Challenge expires.** `Challenge.expiresAt` — server cleans up; don't trust unexpired state cached on client.
- **Guild draft is broader than runtime.** Full guild entity / raid / bank / buff systems remain design-layer material. Today the shipped Guild Hall is mainly a host for social primitives plus adjacent guild-challenge scaffolding.
- **DMs separate from mail.** `DirectMessage` (player-to-player) vs `MailRecipient` (system broadcast). Don't conflate. See [[mail]].
- **Rate limits.** Friend requests and challenges need rate limits to prevent spam.
- **Dates arrive as ISO strings.** `APIClient` has no date strategy, so `FriendEntry.lastActiveAt` / `FriendRequest.requestedAt` are `String` and parse through `SocialDate`. As `Date` they failed the whole friends list ("Failed to load allies", fixed 2026-11-04).
- **Admin social surface is review-only today.** The dashboard shows recent friendships/messages/challenges, but it is not a live moderation console with mute/ban/clear-message actions.

## Tests / fixtures

- `backend/tests/api/social-challenges.test.ts`
- `backend/tests/api/social-messages.test.ts`
- No broader `social/*` backend suite is checked in today beyond these route-level tests

## Related features

- [[mail]] — system mail and direct messages share the UI but different backend tables
- [[leaderboard]] — tap row → opponent profile → social actions
- [[pvp-combat]] — challenges funnel directly into PvP
- [[opponent-profile]] — the shared profile surface used everywhere for Challenge / Message / Add Ally actions
