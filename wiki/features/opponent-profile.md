# Feature: Opponent Profile

> Single-file map of every file that touches the shared opponent-profile surface — the card/page players open from leaderboard, arena-adjacent flows, and social entry points to challenge, message, or add an ally.

## One-liner

Players can inspect another character's full public profile, compare visible gear/stats, and launch the shared social actions: Challenge, Message, and Add Ally.

## Status

- **Phase:** In production
- **Owner / last hands:** Artem

## Entry points

- **iOS screens:**
  - `Hexbound/Hexbound/Views/Leaderboard/LeaderboardPlayerDetailSheet.swift` — modal profile opened from a leaderboard row tap
  - `Hexbound/Hexbound/Views/Profile/CharacterProfileView.swift` — full-page profile route used as the newer shared drill-down surface
- **Shared actions:** Challenge / Message / Add Ally
- **Player action:** tap another player from Leaderboard or another social/opponent surface

## Backend

### Routes

- `GET  /api/characters/[id]/profile`        — `backend/src/app/api/characters/[id]/profile/route.ts` — full public profile payload for another character
- `GET  /api/social/relationship`            — `backend/src/app/api/social/relationship/route.ts` — friendship state + head-to-head PvP stats
- `GET/POST /api/social/friends`             — `backend/src/app/api/social/friends/route.ts` — send / accept / remove ally requests
- `GET/POST /api/social/challenges`          — `backend/src/app/api/social/challenges/route.ts` — issue and resolve duel challenges
- `GET/POST /api/social/messages`            — `backend/src/app/api/social/messages/route.ts` — direct player-to-player messaging

### Business logic

- public profile read path is anchored on the character-profile route
- relationship state is resolved separately so button states stay player-specific
- challenge / message / ally actions reuse the existing social runtime rather than inventing a profile-specific backend path

### Prisma models touched

- `Character` — public profile source (name, class, origin, level, avatar, PvP stats, visible combat stats)
- `Friendship` — ally / request / blocked state
- `Challenge` — duel requests launched from the profile
- `DirectMessage` — player-to-player DM threads
- `Item` / equipped gear relations — visible loadout shown in the card/profile

## iOS

### Views

- `Hexbound/Hexbound/Views/Leaderboard/LeaderboardPlayerDetailSheet.swift` — modal presentation with profile card, action row, PvP record, and stat groups
- `Hexbound/Hexbound/Views/Profile/CharacterProfileView.swift` — full-page profile route with the same shared interaction model
- `IntegratedCharacterCard` — shared visual shell for hero/opponent card presentation

### Models

- `Hexbound/Hexbound/Models/OpponentProfile.swift` — typed public-profile payload used by both modal and full-page versions

### Services

- `Hexbound/Hexbound/Services/SocialService.swift` — friendship-state fetch + ally actions
- challenge and messaging actions route through the existing social/message services from the profile surface

### Cache

- `GameDataCache.opponentProfiles` — 60-second cache keyed by `characterId`
- cache is stale-while-revalidate oriented so re-opening the same profile feels instant

## Admin

- no dedicated admin surface; this is a player-facing read/action entry point over existing character/social systems

## Docs

- `wiki/features/leaderboard.md` — one of the main entry surfaces
- `wiki/features/social.md` — shared ally/challenge/message semantics
- `wiki/features/characters.md` — shared integrated-card and profile-display lineage

## Notable gotchas

- **Shared entry point, not a separate subsystem.** The profile surface should call the existing social/challenge/message flows, not fork its own mini-runtime.
- **Perspective matters.** Friendship state is relative to the current player, so the profile payload alone is not enough; pair it with `social/relationship`.
- **Cache is short-lived on purpose.** Rating, gear, and friendship state can change quickly; the 60s cache is just enough to avoid annoying repeat fetches.
- **Visible gear is inspectable.** The opponent card supports item-tap comparison flow against the local player's matching slot.
- **Do not duplicate UI logic.** `LeaderboardPlayerDetailSheet` and `CharacterProfileView` are two containers over the same profile idea, not two unrelated features.

## Tests / fixtures

- no dedicated standalone feature test file; coverage is distributed across character/social/leaderboard route tests

## Related features

- [[leaderboard]] — primary drill-down entry from ranked rows
- [[social]] — ally, challenge, and DM actions launched from the profile
- [[characters]] — shared profile data model and integrated card presentation
- [[mail]] — some mail/social flows can route into the same player-facing identity context
- [[pvp-combat]] — challenge actions feed directly into PvP
