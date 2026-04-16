---
title: Block 044 — backend social contracts and runtime hardening
category: audit
tags: [audit, backend, social, challenges, messages, tests]
sources:
  - backend/src/app/api/social/challenges/route.ts
  - backend/src/app/api/social/friends/route.ts
  - backend/src/app/api/social/messages/route.ts
  - backend/src/app/api/social/relationship/route.ts
  - backend/tests/api/social-challenges.test.ts
  - backend/tests/api/social-messages.test.ts
updated: 2026-04-15
status: Fixed
---

# Block 044 — backend social contracts and runtime hardening

## Scope

- `backend/src/app/api/social/challenges/route.ts`
- `backend/src/app/api/social/friends/route.ts`
- `backend/src/app/api/social/messages/route.ts`
- `backend/src/app/api/social/relationship/route.ts`
- `backend/tests/api/social-challenges.test.ts`
- `backend/tests/api/social-messages.test.ts`

## Why this block

This social slice still looked like “mostly typing debt” from the lint output, but there were two real runtime problems hiding inside it:

1. direct-message send limits were checked before the final write without a sender-row lock, so parallel sends could bypass the daily cap or anti-spam gate;
2. challenge acceptance had already been improved to finish under one locked transaction, but the new sentinel errors from that transaction could still leak out as generic `500`s during concurrency races.

The rest of the work here was about turning the social routes back into explicit contracts instead of loose JSON plumbing.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[social]]
- [[bug-patterns]]
- [[design-principles]]

## File notes

### `backend/src/app/api/social/challenges/route.ts`

- **Zone:** backend / social / duels
- **Purpose:** lists, sends, accepts, and declines player-to-player challenges
- **Depends on:** auth, combat runtime, premium gold bonus helpers, progression helpers, battle-result mail helpers, Prisma transactions
- **Used by:** iOS Guild Hall duel/challenge flows
- **Problems found:**
  - duel XP was computed but not persisted to `currentXp` before `applyLevelUp(...)`
  - challenge acceptance used to write `accepted` before combat, so failures after that point could strand a challenge in a half-resolved state
  - after the new locked transaction was introduced, concurrent stale-state failures could still bubble up as generic `500`s
- **What was fixed:**
  - winner and loser now both persist `currentXp` increments inside the final locked transaction
  - the old pre-combat `accepted` write is gone; `pvpMatch`, character updates, gold updates, and challenge completion now commit together under one lock
  - transaction sentinel errors now return stable HTTP responses (`404`, `403`, `409`, `410`) instead of leaking as generic backend failures
- **Status:** Fixed

### `backend/src/app/api/social/messages/route.ts`

- **Zone:** backend / social / messaging
- **Purpose:** lists conversations, sends direct messages, and marks them as read
- **Depends on:** auth, Prisma, friendship checks, route-level rate limits
- **Used by:** iOS Guild Hall direct messages
- **Problems found:**
  - daily-limit and anti-spam checks lived outside the final message write
  - the route still leaned on weak body/error typing
- **What was fixed:**
  - send and quick-send now run through a shared helper that locks the sender character row before checking counts and creating the message
  - request and conversation payloads are typed explicitly instead of flowing through loose `any` shapes
- **Status:** Fixed

### `backend/src/app/api/social/friends/route.ts`

- **Zone:** backend / social / friends
- **Purpose:** returns accepted friends, incoming/outgoing requests, and blocked users
- **Depends on:** auth, Prisma friendships
- **Used by:** iOS Guild Hall friends list
- **Problems found:** dead request-expiry constants and repeated `any` in list mapping
- **What was fixed:** removed the dead constants and converted the live mappings to typed object reads
- **Status:** Fixed

### `backend/src/app/api/social/relationship/route.ts`

- **Zone:** backend / social / relationship
- **Purpose:** returns the relationship state between two characters
- **Depends on:** auth, Prisma friendship/challenge state
- **Used by:** profile, duel, and social action entry points
- **Problems found:** broad `any` catch path
- **What was fixed:** narrowed error handling to `unknown` without changing response semantics
- **Status:** Fixed

### `backend/tests/api/social-challenges.test.ts`

- **Zone:** backend tests / social
- **Purpose:** protects the challenge accept contract around duel resolution
- **What it covers now:**
  - duel XP is persisted before level-up side effects run
  - the final locked transaction completes the challenge with `matchId`
  - stale locked-state rejection returns `409 Challenge is no longer pending` instead of a generic `500`
- **Status:** Fixed

### `backend/tests/api/social-messages.test.ts`

- **Zone:** backend tests / social
- **Purpose:** protects the locked direct-message send boundary
- **What it covers now:**
  - tx-local daily message cap rejection
  - successful send through the locked helper path
- **Status:** Fixed

## Problems found

1. **Direct-message send guards had a TOCTOU gap**
   - Risk: parallel sends from one character could exceed the daily send cap or bypass the short anti-spam delay.
   - Fix: sender-row locking now wraps both guard checks and message creation.

2. **Challenge accept could still fail as a generic `500` after the runtime hardening**
   - Risk: if the challenge changed state between the optimistic pre-read and the final lock, the client got an opaque backend failure instead of a recoverable conflict.
   - Fix: mapped transaction sentinel errors to stable contract responses and added a focused regression test.

3. **Duel XP was computed but not persisted**
   - Risk: challenge fights could claim XP in response/mail payloads without actually moving character progression.
   - Fix: both winner and loser `currentXp` increments now commit inside the final duel transaction.

4. **Social routes still had weak payload typing**
   - Risk: future refactors would keep dragging stale shapes and error handling around.
   - Fix: typed request bodies, locked-row shapes, and conversation entries in the live routes.

## Verification

- targeted backend `eslint`:
  - `src/app/api/social/challenges/route.ts`
  - `src/app/api/social/friends/route.ts`
  - `src/app/api/social/messages/route.ts`
  - `src/app/api/social/relationship/route.ts`
  - `tests/api/social-challenges.test.ts`
  - `tests/api/social-messages.test.ts`
- targeted backend `vitest`:
  - `tests/api/social-challenges.test.ts`
  - `tests/api/social-messages.test.ts`
- full backend `npx vitest run` (`35/35` files, `269/269` tests)
- `npm run build` in `backend/`
- `git diff --check`

## Follow-up

- `social/challenges` is now contract-safe, but the route is still heavy and mixes list/send/accept/decline responsibilities in one file; keep that split-locality in mind for the later architecture pass.
- the next warning-heavy backend slice is still the remaining helper/runtime debt in `tutorial`, `achievement-catalog`, `combat*`, `feature-flags`, `progression`, `weekly-challenges`, and `push/send`.
